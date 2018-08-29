//
//  FKVPair.m
//  FastKV
//
//  Created by Yao Li on 2018/8/9.
//

#import "FKVPair.h"
#import "FastKV.h"

/**
 FKVPair Coding Data Format
 
 //Header Segment//
 valueType[NSUInteger] | version[uint32_t] | objcTypeLength[NSUInteger] | keyLength:[NSUInteger] | dataLength[NSUInteger]
 
 //Data Segment//
 objcType[Byte] | key[Byte] | data[Byte]
 
 //Check Code//
 CRC[uint16_t]
 */

@implementation FKVPair
- (instancetype)initWithValueType:(FKVPairType)valueType
                         objcType:(NSString *)objcType
                              key:(NSString *)key
                          version:(uint32_t)version {
    self = [self init];
    if (self) {
        _valueType = valueType;
        _objcType = objcType;
        _key = key;
        _fkv_version = version;
    }
    return self;
}

+ (id)parseFromData:(NSData *)data error:(NSError *__autoreleasing *)error {
    if (data.length == 0) {
        return nil;
    }
    
    // CRC check
    uint16_t crc = [[data subdataWithRange:NSMakeRange(0, data.length-2)] fkv_crc16];
    uint16_t crcInData;
    [data getBytes:&crcInData range:NSMakeRange(data.length-2, 2)];
    if (crc != crcInData) {
        return nil;
    }
    
    FKVPair *pair = [[FKVPair alloc] init];
    
    NSUInteger currentIndex = 0;
    
    FKVPairType valueType;
    [data getBytes:&valueType range:NSMakeRange(currentIndex, sizeof(FKVPairType))];
    currentIndex += sizeof(FKVPairType);
    pair.valueType = valueType;
    
    uint32_t fkv_version;
    [data getBytes:&fkv_version range:NSMakeRange(currentIndex, sizeof(uint32_t))];
    currentIndex += sizeof(uint32_t);
    pair.fkv_version = fkv_version;
    
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
        case FKVPairTypeRemoved:
        case FKVPairTypeNil:
            break;
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
    
    uint32_t fkv_version = self.fkv_version;
    [dataM appendBytes:&fkv_version length:sizeof(uint32_t)];
    
    NSUInteger objcTypeLength = [self.objcType lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    [dataM appendBytes:&objcTypeLength length:sizeof(NSUInteger)];

    NSUInteger keyLength = [self.key lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    [dataM appendBytes:&keyLength length:sizeof(NSUInteger)];
    
    NSUInteger dataLength;
    switch (valueType) {
        case FKVPairTypeRemoved:
        case FKVPairTypeNil: {
            dataLength = 0;
            [dataM appendBytes:&dataLength length:sizeof(NSUInteger)];
            
            [dataM appendBytes:[self.objcType UTF8String] length:objcTypeLength];
            [dataM appendBytes:[self.key UTF8String] length:keyLength];
            break;
        }
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
    
    // CRC check code
    uint16_t crc = [dataM fkv_crc16];
    [dataM appendBytes:&crc length:2];
    
    return [dataM copy];
}

- (BOOL)isEqual:(FKVPair *)object {
    if (![object isKindOfClass:[FKVPair class]]) {
        return NO;
    }
    BOOL result = YES;
    switch (self.valueType) {
        case FKVPairTypeRemoved:
        case FKVPairTypeNil: {
            return YES;
            break;
        }
        case FKVPairTypeBOOL: {
            result = result && (self.boolVal == object.boolVal);
            break;
        }
        case FKVPairTypeInt32: {
            result = result && (self.int32Val == object.int32Val);
            break;
        }
        case FKVPairTypeInt64: {
            result = result && (self.int64Val == object.int64Val);
            break;
        }
        case FKVPairTypeFloat: {
            result = result && (self.floatVal == object.floatVal);
            break;
        }
        case FKVPairTypeDouble: {
            result = result && (self.doubleVal == object.doubleVal);
            break;
        }
        case FKVPairTypeString: {
            result = result && [self.stringVal isEqualToString:object.stringVal];
            break;
        }
        case FKVPairTypeData: {
            result = result && (self.binaryVal == object.binaryVal);
            break;
        }
    }
    if (!result) {
        return NO;
    }
    result = result && (self.valueType == object.valueType);
    return result;
}
@end

@implementation FKVPairList
+ (FKVPairList *)parseFromData:(NSData *)data error:(NSError *__autoreleasing *)error {
    NSUInteger len = data.length;
    NSData *delimiterData = [NSData dataWithBytes:FastKVSeperatorString length:strlen(FastKVSeperatorString)];
    
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
        [data appendData:[obj representationData]];
        [data appendBytes:FastKVSeperatorString length:strlen(FastKVSeperatorString)];
    }];
    return data;
}
@end

@implementation NSData (FKVPair)

- (uint16_t)fkv_crc16 {
    const uint8_t *byte = (const uint8_t *)self.bytes;
    uint16_t length = (uint16_t)self.length;
    return fkv_gen_crc16(byte, length);
}

#define FKVPairCRCPLOY 0X1021
uint16_t fkv_gen_crc16(const uint8_t *data, uint16_t size) {
    uint16_t crc = 0;
    uint8_t i;
    for (; size > 0; size--) {
        crc = crc ^ (*data++ <<8);
        for (i = 0; i < 8; i++) {
            if (crc & 0X8000) {
                crc = (crc << 1) ^ FKVPairCRCPLOY;
            }else {
                crc <<= 1;
            }
        }
        crc &= 0XFFFF;
    }
    return crc;
}
@end
