//
//  FastKV.h
//  FastKV
//
//  Created by Yao Li on 2018/8/9.
//

#import <Foundation/Foundation.h>

extern const char * FastKVSeparatorString;

@interface FastKV : NSObject
+ (instancetype)defaultFastKV;

- (instancetype)initWithFile:(NSString *)path;

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
- (void)reset;
@end
