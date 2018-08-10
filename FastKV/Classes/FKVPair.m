//
//  FKVPair.m
//  FastKV
//
//  Created by Yao Li on 2018/8/9.
//

#import "FKVPair.h"
#import "FastKV.h"

@implementation FKVPair
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.key = [coder decodeObjectForKey:@"key"];
        self.objcType = [coder decodeObjectForKey:@"objcType"];
        self.valueType = [coder decodeIntegerForKey:@"valueType"];
        self.boolVal = [coder decodeBoolForKey:@"boolVal"];
        self.int32Val = [coder decodeInt32ForKey:@"int32Val"];
        self.int64Val = [coder decodeInt64ForKey:@"int64Val"];
        self.floatVal = [coder decodeFloatForKey:@"floatVal"];
        self.doubleVal = [coder decodeDoubleForKey:@"doubleVal"];
        self.stringVal = [coder decodeObjectForKey:@"stringVal"];
        self.binaryVal = [coder decodeObjectForKey:@"binaryVal"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.objcType forKey:@"objcType"];
    [aCoder encodeInteger:self.valueType forKey:@"valueType"];
    [aCoder encodeBool:self.boolVal forKey:@"boolVal"];
    [aCoder encodeInt32:self.int32Val forKey:@"int32Val"];
    [aCoder encodeInt64:self.int64Val forKey:@"int64Val"];
    [aCoder encodeFloat:self.floatVal forKey:@"floatVal"];
    [aCoder encodeDouble:self.doubleVal forKey:@"doubleVal"];
    [aCoder encodeObject:self.stringVal forKey:@"stringVal"];
    [aCoder encodeObject:self.binaryVal forKey:@"binaryVal"];
}
@end

@implementation FKVPairList
+ (FKVPairList *)parseFromData:(NSData *)data error:(NSError *__autoreleasing *)error {
    NSUInteger len = data.length;
    NSData *delimiterData = [NSData dataWithBytes:FastKVSeparatorString length:FastKVSeparatorStringLength];
    
    FKVPairList *kvList = [[FKVPairList alloc] init];
    
    NSRange delimiterRange = NSMakeRange(0, 0);
    NSUInteger splitStartIndex = 0;
    while (YES) {
        delimiterRange = [data rangeOfData:delimiterData options:kNilOptions range:NSMakeRange(splitStartIndex, len - splitStartIndex)];
        if (delimiterRange.location == NSNotFound) {
            break;
        }
        FKVPair *kv = [NSKeyedUnarchiver unarchiveObjectWithData:[data subdataWithRange:NSMakeRange(splitStartIndex, delimiterRange.location - splitStartIndex)]];
        if (kv) {
            [kvList.items addObject:kv];
        }
        splitStartIndex = delimiterRange.location + delimiterRange.length;
    }
    
    return kvList;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
    }
    return self;
}

- (NSData *)representationData {
    NSMutableData *data = [NSMutableData data];
    [self.items enumerateObjectsUsingBlock:^(FKVPair * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [data appendBytes:"\n" length:1];
        [data appendData:[NSKeyedArchiver archivedDataWithRootObject:obj]];
    }];
    return data;
}
@end
