# FastKV
[![Platform](https://img.shields.io/cocoapods/p/TinyPart.svg?style=flat)](https://cocoapods.org/?q=tinypart)
[![Version](https://img.shields.io/cocoapods/v/FastKV.svg?style=flat)](https://cocoapods.org/pods/FastKV)
[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/RyanLeeLY/TinyPart/blob/master/LICENSE)
[![Gmail](https://img.shields.io/badge/Gmail-@liyaoxjtu2013-red.svg?style=flat)](mail://liyaoxjtu2013@gmail.com)
[![Twitter](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/liyaoryan)

[中文介绍](https://github.com/RyanLeeLY/FastKV/blob/master/iOS的高性能、高实时性key-value持久化组件.md)

## Usage
```
[[FastKV defaultFastKV] setBool:YES forKey:@"key"];
[[FastKV defaultFastKV] setInteger:1 forKey:@"key"];
[[FastKV defaultFastKV] setObject:@"value" forKey:@"key"];

[[FastKV defaultFastKV] boolForKey:@"key"];
[[FastKV defaultFastKV] integerForKey:@"key"];
[[FastKV defaultFastKV] objectOfClass:NSString.class forKey:@"key"];
```

## Memory Allocation
`FastKV` provides two kinds of memory allocation strategy.

```
typedef NS_ENUM(NSUInteger, FastKVMemoryStrategy) {
    FastKVMemoryStrategyDefalut = 0,
    FastKVMemoryStrategy1,
};
```

**Doubling** `FastKVMemoryStrategyDefalut`

```
size_t allocationSize = 1;
    while (allocationSize <= neededSize) {
        allocationSize *= 2;
    }
    return allocationSize;
```
 
**Linear** `FastKVMemoryStrategy1 `

Reference [python list](https://svn.python.org/projects/python/trunk/Objects/listobject.c)

```
size_t allocationSize = (neededSize >> 3) + (neededSize < 9 ? 3 : 6);
return allocationSize + neededSize;
```

## Installation

FastKV is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FastKV'
```

## Benchmark
iPhone 8 64G, iOS 11.4

**Time taken of 10,000 write operations, unit: ms**

![Benchmark](https://github.com/RyanLeeLY/FastKV/raw/master/benchmark.jpeg)


## Author

yao.li, liyaoxjtu2013@gmail.com

## License

FastKV is available under the [MIT](https://github.com/RyanLeeLY/FastKV/blob/master/LICENSE) license. See the LICENSE file for more info.
