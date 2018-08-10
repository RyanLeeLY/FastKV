//
//  FKVPair.h
//  FastKV
//
//  Created by Yao Li on 2018/8/9.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FKVPairType) {
    FKVPairTypeBOOL = 0,
    FKVPairTypeInt32,
    FKVPairTypeInt64,
    FKVPairTypeFloat,
    FKVPairTypeDouble,
    FKVPairTypeString,
    FKVPairTypeData,
};

@interface FKVPair : NSObject <NSCoding>
@property(copy, nonatomic) NSString *key;

@property(copy, nonatomic) NSString *objcType;

@property(assign, nonatomic) FKVPairType valueType;

@property(assign, nonatomic) BOOL boolVal;

@property(assign, nonatomic) int32_t int32Val;

@property(assign, nonatomic) int64_t int64Val;

@property(assign, nonatomic) float floatVal;

@property(assign, nonatomic) double doubleVal;

@property(copy, nonatomic) NSString *stringVal;

@property(assign, nonatomic) NSData *binaryVal;

@end

@interface FKVPairList : NSObject
@property(copy, nonatomic) NSMutableArray<FKVPair *> *items;

+ (FKVPairList *)parseFromData:(NSData *)data error:(NSError *__autoreleasing *)error;

- (NSData *)representationData;
@end
