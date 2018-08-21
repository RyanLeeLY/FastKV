//
//  FKVPair.m
//  FastKV
//
//  Created by Yao Li on 2018/8/9.
//

#import "FKVPair.h"
#import "FastKV.h"

@implementation FKVPair
+ (id)parseFromData:(NSData *)data error:(NSError *__autoreleasing *)error {
    if (data.length == 0) {
        return nil;
    }
    FKVPair *pair = [[FKVPair alloc] init];
    
    NSUInteger currentIndex = 0;
    
    FKVPairType valueType;
    [data getBytes:&valueType range:NSMakeRange(currentIndex, sizeof(FKVPairType))];
    currentIndex += sizeof(FKVPairType);
    pair.valueType = valueType;
    
    NSUInteger objcTypeLength = 0;
    [data getBytes:&objcTypeLength range:NSMakeRange(currentIndex, sizeof(NSUInteger))];
    currentIndex += sizeof(NSUInteger);
    
    NSUInteger keyLength = 0;
    [data getBytes:&keyLength range:NSMakeRange(currentIndex, sizeof(NSUInteger))];
    currentIndex += sizeof(NSUInteger);
    
    NSUInteger dataLength = 0;
    [data getBytes:&dataLength range:NSMakeRange(currentIndex, sizeof(NSUInteger))];
    currentIndex += sizeof(NSUInteger);
    
    pair.objcType = [[NSString alloc] initWithBytes:[data bytes] + currentIndex
                                             length:objcTypeLength
                                           encoding:NSUTF8StringEncoding];
    currentIndex += objcTypeLength;
    
    pair.key = [[NSString alloc] initWithBytes:[data bytes] + currentIndex
                                             length:keyLength
                                           encoding:NSUTF8StringEncoding];
    currentIndex += keyLength;
    
    switch (valueType) {
        case FKVPairTypeBOOL: {
            BOOL boolVal;
            [data getBytes:&boolVal range:NSMakeRange(currentIndex, dataLength)];
            pair.boolVal = boolVal;
            break;
        }
        case FKVPairTypeInt32: {
            int32_t int32Val;
            [data getBytes:&int32Val range:NSMakeRange(currentIndex, dataLength)];
            pair.int32Val = int32Val;
            break;
        }
        case FKVPairTypeInt64: {
            int64_t int64Val;
            [data getBytes:&int64Val range:NSMakeRange(currentIndex, dataLength)];
            pair.int64Val = int64Val;
            break;
        }
        case FKVPairTypeFloat: {
            float floatVal;
            [data getBytes:&floatVal range:NSMakeRange(currentIndex, dataLength)];
            pair.floatVal = floatVal;
            break;
        }
        case FKVPairTypeDouble: {
            double doubleVal;
            [data getBytes:&doubleVal range:NSMakeRange(currentIndex, dataLength)];
            pair.doubleVal = doubleVal;
            break;
        }
        case FKVPairTypeString: {
            pair.stringVal = [[NSString alloc] initWithBytes:[data bytes] + currentIndex
                                                      length:dataLength
                                                    encoding:NSUTF8StringEncoding];
            break;
        }
        case FKVPairTypeData: {
            pair.binaryVal = [data subdataWithRange:NSMakeRange(currentIndex, dataLength)];
            break;
        }
    }
    
    return pair;
}

- (NSData *)representationData {
    NSMutableData *dataM = [NSMutableData data];
    FKVPairType valueType = self.valueType;
    [dataM appendBytes:&valueType length:sizeof(FKVPairType)];
    
    NSUInteger objcTypeLength = [self.objcType lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    [dataM appendBytes:&objcTypeLength length:sizeof(NSUInteger)];

    NSUInteger keyLength = [self.key lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    [dataM appendBytes:&keyLength length:sizeof(NSUInteger)];
    
    NSUInteger dataLength;
    switch (valueType) {
        case FKVPairTypeBOOL: {
            dataLength = (NSUInteger)sizeof(BOOL);
            [dataM appendBytes:&dataLength length:sizeof(NSUInteger)];
            
            BOOL data = self.boolVal;
            [dataM appendBytes:[self.objcType UTF8String] length:objcTypeLength];
            [dataM appendBytes:[self.key UTF8String] length:keyLength];
            [dataM appendBytes:&data length:dataLength];
            break;
        }
        case FKVPairTypeInt32: {
            dataLength = (NSUInteger)sizeof(int32_t);
            [dataM appendBytes:&dataLength length:sizeof(NSUInteger)];
            
            int32_t data = self.int32Val;
            [dataM appendBytes:[self.objcType UTF8String] length:objcTypeLength];
            [dataM appendBytes:[self.key UTF8String] length:keyLength];
            [dataM appendBytes:&data length:dataLength];
            break;
        }
        case FKVPairTypeInt64: {
            dataLength = (NSUInteger)sizeof(int64_t);
            [dataM appendBytes:&dataLength length:sizeof(NSUInteger)];
            
            int64_t data = self.int64Val;
            [dataM appendBytes:[self.objcType UTF8String] length:objcTypeLength];
            [dataM appendBytes:[self.key UTF8String] length:keyLength];
            [dataM appendBytes:&data length:dataLength];
            break;
        }
        case FKVPairTypeFloat: {
            dataLength = (NSUInteger)sizeof(float);
            [dataM appendBytes:&dataLength length:sizeof(NSUInteger)];
            
            float data = self.floatVal;
            [dataM appendBytes:[self.objcType UTF8String] length:objcTypeLength];
            [dataM appendBytes:[self.key UTF8String] length:keyLength];
            [dataM appendBytes:&data length:dataLength];
            break;
        }
        case FKVPairTypeDouble: {
            dataLength = (NSUInteger)sizeof(double);
            [dataM appendBytes:&dataLength length:sizeof(NSUInteger)];
            
            float data = self.doubleVal;
            [dataM appendBytes:[self.objcType UTF8String] length:objcTypeLength];
            [dataM appendBytes:[self.key UTF8String] length:keyLength];
            [dataM appendBytes:&data length:dataLength];
            break;
        }
        case FKVPairTypeString: {
            dataLength = self.stringVal.length;
            [dataM appendBytes:&dataLength length:sizeof(NSUInteger)];
            
            NSString *data = self.stringVal;
            [dataM appendBytes:[self.objcType UTF8String] length:objcTypeLength];
            [dataM appendBytes:[self.key UTF8String] length:keyLength];
            [dataM appendBytes:[data UTF8String] length:dataLength];
            break;
        }
        case FKVPairTypeData: {
            dataLength = self.binaryVal.length;
            [dataM appendBytes:&dataLength length:sizeof(NSUInteger)];
            
            NSData *data = self.binaryVal;
            [dataM appendBytes:[self.objcType UTF8String] length:objcTypeLength];
            [dataM appendBytes:[self.key UTF8String] length:keyLength];
            [dataM appendData:data];
            break;
        }
    }
    
    return [dataM copy];
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
        FKVPair *kv = [FKVPair parseFromData:[data subdataWithRange:NSMakeRange(splitStartIndex, delimiterRange.location - splitStartIndex)] error:error];
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
        [data appendBytes:FastKVSeparatorString length:FastKVSeparatorStringLength];
        [data appendData:[obj representationData]];
    }];
    return data;
}
@end
