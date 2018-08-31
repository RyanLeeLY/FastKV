> 今年上半年时候看到微信开发团队的这么一篇文章[MMKV--基于 mmap 的 iOS 高性能通用 key-value 组件](https://mp.weixin.qq.com/s/cZQ3FQxRJBx4px1woBaasg)，文中提到了用mmap实现一个高性能KV组件，虽然并没有展示太多的具体代码，但是基本思路讲的还是很清楚的。<br>文章最后提到了开源计划，等了快半年还没看到这个组件源码，于是决定自己试着写一个。

## 关于NSUserDefaults

在开始写这个组件之前，应该先调研一下NSUserDefaults性能（ps：这里有个失误，事实上我是在写完这个组件以后才调研的）。

据我所知NSUserDefaults有一层内存缓存的，所以它提供了一个叫`synchronize`的方法用于同步磁盘和缓存，但是这个方法现在苹果在文档中告诉我们`for any other reason: remove the synchronize call`，总之就是再也不需要调用这个方法了。

测试结果如下（写入1w次，值类型是NSInteger，环境：iPhone 8 64G, iOS 11.4）

非`synchronize`耗时：**137ms**

`synchronize`耗时：**3758ms**

很明显`synchronize `对性能的损耗非常大，因为本文需要的是一个**高性能**、**高实时性**的key-value持久化组件，也就是说在一些极端情况下数据也需要能够被持久化，同时又不影响性能。所谓极端情况，比如说在App发生Crash的时候数据也能够被存储到磁盘中，并不会因为缓存和磁盘没来得及同步而造成数据丢失。

从数据上我们可以看到非`synchronize`下的性能还是挺好的，比上面那篇微信的文章中的测试结果貌似要好很多嘛。那么`mmap`和`NSUserDefaults`在高性能上的优势似乎并不明显的。

那么我们再来看一下**高实时性**这个方面。既然苹果在文档中告诉我们`remove the synchronize`，难道苹果已经解决的`NSUserDefaults`的高实时性和高性能兼顾的问题？抱着试一试的心态笔者做了一下测试，答案是否定的。在不使用`synchronize `的情况下，极端情况依旧会出现数据丢失的问题。那么我们的`mmap`还是有它的用武之地的，至少它在保证的高实时性的时候还兼顾到了性能问题。

为了便于更好的理解，在阅读接下来的部分前请先阅读这篇文章。[MMKV--基于 mmap 的 iOS 高性能通用 key-value 组件](https://mp.weixin.qq.com/s/cZQ3FQxRJBx4px1woBaasg)

## 数据序列化

具体的实现笔者还是参考了上面微信团队的MMKV，那篇文章已经讲得比较详细了，因此对那篇文章的分析在这里就不再展开了。

在这里要提到的一个点是有关于数据序列化。MMKV在序列化时使用了Google开源的`protobuf`，笔者在实现的时候考虑到各方面原因决定自定义一个内存数据格式，这样就避免了对`protobuf`的依赖。

自定义协议主要分为3个部分：Header Segment、Data Segment、Check Code。

**Header Segment**：

| 32/64bit | 32bit | 32/64bit | 32/64bit | 32/64bit |
| ------ | ------ | ------ | ------ | ------ |
| VALUE_TYPE | VERSION | OBJC_TYPE length | KEY length | DATA length |

这部分的长度是固定的，160bit或288bit。

`VALUE_TYPE`：数据的类型，目前有8种类型bool、nil、int32、int64、float、double、string、data。

`VERSION`：数据记录时的版本。

`OBJC_TYPE length`：OC类名字符串的长度。

`KEY length`：key的长度。

`DATA length`：value的长度。

**Data Segment**：

| Data | Data | Data |
| ------ | ------ | ------ |
| OBJC_TYPE | KEY | DATA |

`OBJC_TYPE`：OC类名的字符串。

`KEY`：key。

`DATA`：value。

**Check Code**：

| 16bit |
| ------ |
| CRC code |

CRC code：倒数16位之前数据的CRC-16循环冗余检测码，用于后期数据校验。

## 空间增长

在MMKV的文章中提到，在append时遇到内存不够用的时候，会进行序列化排重；在序列化排重后还是不够用的话就将文件扩大一倍，直到够用。

在只考虑在添加新的key的情况下这确实是一种简单有效的内存分配策略，但是在多次更新key时可能会出现连续的排重操作，下面用一个例子来说明。

如果当前分配的`mmap size`仅仅只比当前正在使用的size多出极少极少一点，以至于接下来任何的append操作都会触发排重，但是由于每次都是对key进行更新操作，如果当前mmap的数据已经是最小集合了（没有任何重复key的数据），于是在排重完成后`mmap size`又刚好够用，不需要重新分配`mmap size`。这时候`mmap size`又是仅仅只比当前正在使用的size多出极少极少一点，然后任何的append又会走一遍上述逻辑。

为了解决这个问题，笔者在append操作的时候附加了一个逻辑：如果当前是对key进行更新操作，那么重新分配`mmap size`的需求大小将会扩大1倍。也就是说如果对key进行更新操作后触发排重，这时`mmap size`的将会按当前需求2倍的大小尝试进行重新分配，以空间来换取时间性能。

``` objective-c
if (data.length + _cursize >= _mmsize) {
	 // 如果是对key是update操作，那么就按照真实需求大小2倍的来尝试进行重新分配。
    [self reallocWithExtraSize:data.length scale:isUpdated?2:1];
} else {
    memcpy((char *)_mmptr + _cursize, data.bytes, data.length);
    _cursize += data.length;

    uint64_t dataLength = _cursize - FastKVHeaderSize;
    memcpy((char *)_mmptr + sizeof(uint32_t) + [FastKVMarkString lengthOfBytesUsingEncoding:NSUTF8StringEncoding], &dataLength, 8);
}
    
```

## 其他优化
有一些OC对象的存储是可以优化的，比如NSDate、NSURL，在实际存储时可以当成double和NSString来进行序列化，既提高了性能又减少了空间的占用。

## 性能比较
测试结果如下（1w次，值类型是NSInteger，环境：iPhone 8 64G, iOS 11.4）

add耗时：**70ms** （NSUserDefults Sync：**3469ms**）

update耗时：**80ms** （NSUserDefults Sync：**3521ms**）

get耗时：**10ms** （NSUserDefults：**48ms**）

测试下来mmap性能确实比`NSUserDefults Sync`要好不少，也和微信那篇文章中对MMKV的性能测试结果基本一致。总的来说，如果对实时性要求不高的项目，建议还是使用官方的`NSUserDefults `。

## 其他开源作品
**TinyPart —模块化框架**
[github](https://github.com/RyanLeeLY/TinyPart)

**Coolog —可扩展的log框架** [github](https://github.com/RyanLeeLY/Coolog)

**WhiteElephantKiller —无用代码扫描工具** [github](https://github.com/RyanLeeLY/WhiteElephantKiller)
