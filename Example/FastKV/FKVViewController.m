//
//  FKVViewController.m
//  FastKV
//
//  Created by yao.li on 08/09/2018.
//  Copyright (c) 2018 yao.li. All rights reserved.
//

#import "FKVViewController.h"
#import <FastKV/FastKV.h>
#import <FastKV/FKVPair.h>

@interface FKVViewController ()

@end

@implementation FKVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self test];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)test {
    FKVPair *fkp = [[FKVPair alloc] init];
    fkp.valueType = FKVPairTypeData;
    fkp.objcType = @"NSString";
    fkp.key = @"testlytestlytestlytestly";
    fkp.stringVal = @"sss";
    NSData *numberData = [NSKeyedArchiver archivedDataWithRootObject:@1];
    fkp.binaryVal = numberData;
    
    NSData *data = [fkp representationData];
    
    FKVPair *pair = [FKVPair parseFromData:data error:nil];
    NSLog(@"%@", pair);
}

- (IBAction)eventFromButton:(UIButton *)sender {
    NSMutableArray *keyArray = [NSMutableArray array];
    for (int i=0; i<5000; i++) {
        NSString *key = [NSString stringWithFormat:@"testfkv%@", @(i)];
        [keyArray addObject:key];
    }
    if (sender.tag == 1) {
        [self logTimeTakenToRunBlock:^{
            [keyArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [[FastKV defaultFastKV] setObject:obj forKey:obj];
            }];
        } withPrefix:@"FKV"];
        
    } else if (sender.tag == 2) {
        id integer = [[FastKV defaultFastKV] objectOfClass:NSString.class forKey:@"testfkv4800"];
        
        NSLog(@"%@", integer);
    } else if (sender.tag == 3) {
        [[FastKV defaultFastKV] removeObjectForKey:@"testfkv4800"];
//        [[FastKV defaultFastKV] reset];
        
        [self logTimeTakenToRunBlock:^{
            [keyArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [[NSUserDefaults standardUserDefaults] setObject:obj forKey:obj];
            }];
        } withPrefix:@"UserDefaults"];
    }
}

- (void)logTimeTakenToRunBlock:(void(^)(void))block withPrefix:(NSString *)prefixString {
    
    double a = CFAbsoluteTimeGetCurrent();
    block();
    double b = CFAbsoluteTimeGetCurrent();
    
    unsigned long m = ((b-a) * 1000.0f); // convert from seconds to milliseconds
    
    NSLog(@"fkv %@: %lu ms", prefixString ? prefixString : @"Time taken", m);
}
@end
