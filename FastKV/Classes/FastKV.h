//
//  FastKV.h
//  FastKV
//
//  Created by Yao Li on 2018/8/9.
//

#import <Foundation/Foundation.h>

extern const char * FastKVSeperatorString;

extern NSString * const FastKVErrorDomain;

typedef NS_ENUM(NSUInteger, FastKVError) {
    FastKVErrorOpenFailed = 4001,
    FastKVErrorReadFileFailed = 4002,
    FastKVErrorFileFormatError = 4003,
    FastKVErrorFileCorrupted = 4004,
};

@class FastKV;

@protocol FastKVDelegate <NSObject>
- (void)fastkv:(FastKV *)fastkv fileError:(NSError *)error;
@end

@interface FastKV : NSObject
@property (weak, nonatomic) id<FastKVDelegate> delegate;

+ (instancetype)defaultFastKV;

- (instancetype)initWithFile:(NSString *)path NS_DESIGNATED_INITIALIZER;

- (BOOL)boolForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;
- (nullable id)objectOfClass:(Class)cls forKey:(NSString *)key;

- (void)setBool:(BOOL)val forKey:(NSString *)key;
- (void)setInteger:(NSInteger)intval forKey:(NSString *)key;
- (void)setFloat:(float)val forKey:(NSString *)key;
- (void)setDouble:(double)val forKey:(NSString *)key;
- (void)setObject:(nullable id)obj forKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)removeAllKeys;

/**
 Clean up local file when file error occurs.
 */
- (void)cleanUp;
@end
