//
//  FastKV.m
//  FastKV
//
//  Created by Yao Li on 2018/8/9.
//

#import "FastKV.h"
#import "FKVPair.h"
#import <sys/mman.h>
#import <sys/stat.h>
#import <pthread/pthread.h>

const char * FastKVSeparatorString = "$FastKVSeparatorString$";

static size_t   FastKVPageSize = 8 * 1024; // bytes
static NSString *const FastKVMarkString = @"FastKV";
static uint32_t FastKVVersion  = 1; // mmkv file format version
static size_t  FastKVHeaderSize = 18; // sizeof("FastKV") + version: sizeof(uint32_t) + dataLength: sizeof(uint64_t)

@interface FastKV () {
    int _fd;
    void *_mmptr;
    size_t _mmsize;
    size_t _cursize;
    
    NSMutableDictionary<NSString *, FKVPair *> *_dict;
    pthread_mutex_t _mutexLock;
    
}
@end

@implementation FastKV
+ (instancetype)defaultFastKV {
    static dispatch_once_t onceToken;
    static FastKV *defaultInstacnce;
    dispatch_once(&onceToken, ^{
        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        path = [path stringByAppendingPathComponent:@"default.fkv"];
        defaultInstacnce = [[self alloc] initWithFile:path];
    });
    return defaultInstacnce;
}

- (instancetype)init {
    [NSException raise:@"FastKVException" format:@"Can initialize FastKV via -init"];
    return nil;
}

- (instancetype)initWithFile:(NSString *)path {
    self = [super init];
    if (self) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            return nil;
        }
        
        if(![self open:path]) {
            return nil;
        }
        
        pthread_mutex_init(&_mutexLock, NULL);

    }
    return self;
}

- (BOOL)open:(NSString *)file {
    _fd = open([file fileSystemRepresentation], O_RDWR | O_CREAT, 0666);
    if (_fd == 0) {
        NSCAssert(NO, @"Can not open file: %@", file);
        return NO;
    }
    
    struct stat statInfo;
    if(fstat( _fd, &statInfo ) != 0) {
        NSCAssert(NO, @"Can not read file: %@", file);
        return NO;
    }
    
    if (![self reallocMMSizeWithNeededSize:statInfo.st_size]) {
        return NO;
    }
    
    _dict = [NSMutableDictionary dictionary];
    if (statInfo.st_size == 0) {
        [self resetHeaderWithContentSize:0];
        _cursize = FastKVHeaderSize;
        return YES;
    }
    
    char *ptr = (char *)_mmptr;
    // read file magic code
    NSData *data = [NSData dataWithBytes:ptr length:6];
    if (![FastKVMarkString isEqualToString:[NSString stringWithUTF8String:(const char *)data.bytes]]) {
        NSCAssert(NO, @"Not a FastKV file: %@", file);
        return NO;
    }
    // read version
    ptr += 6;
    data = [NSData dataWithBytes:ptr length:4];
    uint32_t ver = 0;
    [data getBytes:&ver length:4];
    
    // read content-length
    ptr += 4;
    data = [NSData dataWithBytes:ptr length:8];
    uint64_t dataLength = 0;
    [data getBytes:&dataLength length:8];
    if (dataLength + FastKVHeaderSize > statInfo.st_size) {
        NSCAssert(NO, @"illegal file size");
        return NO;
    }
    
    // read contents
    ptr += 8;
    data = [NSData dataWithBytes:ptr length:MIN(dataLength, statInfo.st_size - FastKVHeaderSize)];
    NSError *error;
    FKVPairList *kvlist = [FKVPairList parseFromData:data error:&error];
    for (FKVPair *item in kvlist.items) {
        if (item.key != nil && item.valueType != FKVPairTypeRemoved) {
            _dict[item.key] = item;
        } else if (item.valueType == FKVPairTypeRemoved) {
            [_dict removeObjectForKey:item.key];
        }
    }
    [self reallocWithExtraSize:0];
    return YES;
}

- (void)cleanup {
    if (_mmptr) {
        munmap(_mmptr, _cursize);
    }
    if (_fd) {
        ftruncate(_fd, _cursize);
        close(_fd);
    }
}

#pragma mark - primitive types
- (BOOL)boolForKey:(NSString *)key {
    FKVPair *kv = [self _itemForKey:key];
    id val = [self _numberValue:kv];
    if (val == nil) {
        if (kv.valueType == FKVPairTypeString) {
            val = kv.stringVal;
        }
    }
    return [val boolValue];
}

- (NSInteger)integerForKey:(NSString *)key {
    FKVPair *kv = [self _itemForKey:key];
    id val = [self _numberValue:kv];
    if (val == nil) {
        if (kv.valueType == FKVPairTypeString) {
            val = kv.stringVal;
        }
    }
    return [val integerValue];
}

- (float)floatForKey:(NSString *)key {
    FKVPair *kv = [self _itemForKey:key];
    id val = [self _numberValue:kv];
    if (val == nil) {
        if (kv.valueType == FKVPairTypeString) {
            val = kv.stringVal;
        }
    }
    return [val floatValue];
}

- (double)doubleForKey:(NSString *)key {
    FKVPair *kv = [self _itemForKey:key];
    id val = [self _numberValue:kv];
    if (val == nil) {
        if (kv.valueType == FKVPairTypeString) {
            val = kv.stringVal;
        }
    }
    return [val doubleValue];
}

#pragma mark - read: ObjC objects
- (id)objectOfClass:(Class)cls forKey:(NSString *)key {
    FKVPair *kv = [self _itemForKey:key];
    Class octype = [self _objCType:kv];
    
#ifndef CASE_CLASS
#define CASE_CLASS(cls, type) if (cls == type.class || [cls isSubclassOfClass:type.class])
#endif
    
    CASE_CLASS(cls, NSNumber) {
        return [self _numberValue:kv];
    }
    CASE_CLASS(cls, NSString) {
        return kv.stringVal;
    }
    CASE_CLASS(cls, NSData) {
        if (kv.valueType == FKVPairTypeData) {
            return kv.binaryVal;
        }
        return nil;
    }
    CASE_CLASS(cls, NSDate) {
        CASE_CLASS(octype, NSDate) {
            id val = [self _unarchiveValueForClass:NSDate.class fromItem:kv];
            if (val == nil) {
                val = [self _numberValue:kv];
                return val ? [NSDate dateWithTimeIntervalSince1970:[val doubleValue]] : nil;
            }
            return val;
        }
        return nil;
    }
    CASE_CLASS(cls, NSURL) {
        CASE_CLASS(octype, NSURL) {
            id val = [self _unarchiveValueForClass:NSURL.class fromItem:kv];
            if (val == nil && kv.valueType == FKVPairTypeString) {
                return [NSURL URLWithString:kv.stringVal];
            }
            return val;
        }
        return nil;
    }
    
    return [self _unarchiveValueForClass:octype fromItem:kv];
}

#pragma mark - read: private
- (FKVPair *)_itemForKey:(NSString *)key {
    pthread_mutex_lock(&_mutexLock);
    
    FKVPair *kv = _dict[key];
    
    pthread_mutex_unlock(&_mutexLock);
    return kv;
}

- (Class)_objCType:(FKVPair *)kv {
    if (kv.objcType) {
        return NSClassFromString(kv.objcType);
    }
    return nil;
}

- (NSNumber *)_numberValue:(FKVPair *)kv{
    if (!kv) {
        return nil;
    }
    switch (kv.valueType) {
        case FKVPairTypeBOOL:   return @(kv.boolVal);
        case FKVPairTypeInt32:  return @(kv.int32Val);
        case FKVPairTypeInt64:  return @(kv.int64Val);
        case FKVPairTypeFloat:  return @(kv.floatVal);
        case FKVPairTypeDouble: return @(kv.doubleVal);
        case FKVPairTypeData:
            return [self _unarchiveValueForClass:[NSNumber class] fromItem:kv];
        default: return nil;
    }
}

- (id)_unarchiveValueForClass:(Class)cls fromItem:(FKVPair *)kv {
    if (kv.valueType == FKVPairTypeData) {
        @try {
            id val = [NSKeyedUnarchiver unarchiveObjectWithData:kv.binaryVal];
            return [val isKindOfClass:cls] ? val : nil;
        } @catch (NSException *e) {
            return nil;
        }
    }
    return nil;
}

#pragma mark - set: primitive types
- (void)setBool:(BOOL)val forKey:(NSString *)key {
    FKVPair *kv = [[FKVPair alloc] init];
    kv.key = key;
    kv.boolVal = val;
    kv.objcType = @"NSNumber";
    kv.valueType = FKVPairTypeBOOL;
    [self append:kv];
}

- (void)setInteger:(NSInteger)intval forKey:(NSString *)key {
    FKVPair *kv = [[FKVPair alloc] init];
    kv.key = key;
    kv.objcType = @"NSNumber";
    if (intval > INT_MAX) {
        kv.int64Val = (int64_t)intval;
        kv.valueType = FKVPairTypeInt64;
    } else {
        kv.int32Val = (int32_t)intval;
        kv.valueType = FKVPairTypeInt32;
    }
    [self append:kv];
}

- (void)setFloat:(float)val forKey:(NSString *)key {
    FKVPair *kv = [[FKVPair alloc] init];
    kv.key = key;
    kv.floatVal = val;
    kv.objcType = @"NSNumber";
    kv.valueType = FKVPairTypeFloat;
    [self append:kv];
}

- (void)setDouble:(double)val forKey:(NSString *)key {
    FKVPair *kv = [[FKVPair alloc] init];
    kv.key = key;
    kv.doubleVal = val;
    kv.objcType = @"NSNumber";
    kv.valueType = FKVPairTypeDouble;
    [self append:kv];
}

- (void)setObject:(id)obj forKey:(NSString *)key {
    if (obj == nil) {
        FKVPair *kv = [[FKVPair alloc] init];
        kv.valueType = FKVPairTypeNil;
        kv.key = key;
        [self append:kv];
        return;
    }
    
    FKVPair *kv = [[FKVPair alloc] init];
    kv.key = key;
    kv.objcType = NSStringFromClass([obj class]);
    
    if ([obj isKindOfClass:[NSString class]]) {
        kv.stringVal = (NSString *)obj;
        kv.valueType = FKVPairTypeString;
    } else if ([obj isKindOfClass:[NSData class]]) {
        kv.binaryVal = (NSData *)obj;
        kv.valueType = FKVPairTypeData;
    } else if ([obj isKindOfClass:[NSDate class]]) {
        kv.doubleVal = [((NSDate *)obj) timeIntervalSince1970];
        kv.valueType = FKVPairTypeDouble;
    } else if ([obj isKindOfClass:[NSURL class]]) {
        kv.stringVal = [(NSURL *)obj absoluteString];
        kv.valueType = FKVPairTypeString;
    } else {
        kv.binaryVal = [NSKeyedArchiver archivedDataWithRootObject:obj]; // should throw if exception.
        kv.valueType = FKVPairTypeData;
    }
    
    [self append:kv];
}

- (void)removeObjectForKey:(NSString *)key {
    FKVPair *kv = [[FKVPair alloc] init];
    kv.valueType = FKVPairTypeRemoved;
    kv.key = key;
    [self append:kv];
}

- (void)reset {
    pthread_mutex_lock(&_mutexLock);

    [_dict removeAllObjects];
    munmap(_mmptr, _mmsize);
    [self mapWithSize:FastKVPageSize];
    [self resetHeaderWithContentSize:0];
    
    pthread_mutex_unlock(&_mutexLock);
}

- (void)resetHeaderWithContentSize:(uint64_t)dataLength {
    char *ptr = (char *)_mmptr;
    memcpy(ptr, [FastKVMarkString dataUsingEncoding:NSUTF8StringEncoding].bytes, 6);
    ptr += 6;
    memcpy(ptr, &FastKVVersion, 4);
    ptr += 4;
    memcpy(ptr, &dataLength, 8);
}

- (void)append:(FKVPair *)item {
    pthread_mutex_lock(&_mutexLock);

    if (item.valueType != FKVPairTypeRemoved) {
        _dict[item.key] = item;
    } else {
        [_dict removeObjectForKey:item.key];
    }
    
    NSMutableData *data = [NSMutableData data];
    [data appendData:[item representationData]];
    [data appendBytes:FastKVSeparatorString length:sizeof(FastKVSeparatorString)];
    
    if (data.length + _cursize >= _mmsize) {
        [self reallocWithExtraSize:data.length];
    } else {
        memcpy((char *)_mmptr + _cursize, data.bytes, data.length);
        _cursize += data.length;
        
        uint64_t dataLength = _cursize - FastKVHeaderSize;
        memcpy((char *)_mmptr + sizeof(uint32_t) + [FastKVMarkString lengthOfBytesUsingEncoding:NSUTF8StringEncoding], &dataLength, 8);
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (BOOL)mapWithSize:(size_t)mapSize {
    _mmptr = mmap(NULL, mapSize,  PROT_READ | PROT_WRITE, MAP_FILE | MAP_SHARED, _fd, 0);
    if (_mmptr == MAP_FAILED) {
        NSCAssert(NO, @"create mmap failed: %d", errno);
        return NO;
    }
    ftruncate(_fd, mapSize);
    _mmsize = mapSize;
    return YES;
}

- (void)reallocWithExtraSize:(size_t)size {
    FKVPairList *kvlist = [[FKVPairList alloc] init];
    for (FKVPair *item in _dict.allValues) {
        if (item.valueType != FKVPairTypeRemoved) {
            [kvlist.items addObject:item];
        }
    }
    NSData *data = [kvlist representationData];
    NSUInteger dataLength = data.length;
    
    size_t totalSize = dataLength + FastKVHeaderSize;
    size_t newTotalSize = totalSize + size;
    if (newTotalSize >= _mmsize) {
        munmap(_mmptr, _mmsize);
        [self reallocMMSizeWithNeededSize:totalSize];
        [self resetHeaderWithContentSize:0];
    }
    memcpy((char *)_mmptr + FastKVHeaderSize, data.bytes, dataLength);
    memcpy((char *)_mmptr + 10, &dataLength, 8);
    _cursize = dataLength + FastKVHeaderSize;
}

- (BOOL)reallocMMSizeWithNeededSize:(size_t)neededSize {
    size_t allocationSize = FastKVPageSize;
    int scale = (neededSize < FastKVPageSize * 8) ? 4 : 2;
    while (allocationSize <= neededSize) {
        allocationSize *= scale;
    }
    return [self mapWithSize:allocationSize];
}

#if DEBUG
+ (void)dump {
    
}
#endif
@end
