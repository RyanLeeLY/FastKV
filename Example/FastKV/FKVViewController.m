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
//    for (int i=0; i<3; i++) {
//        NSString *key = [NSString stringWithFormat:@"testfkv%@", @(i)];
//        [[FastKV defaultFastKV] setInteger:i forKey:key];
//    }
//
//    NSInteger integer = [[FastKV defaultFastKV] integerForKey:@"testfkv1"];
//
//    NSLog(@"%@", @(integer));
}

- (IBAction)eventFromButton:(UIButton *)sender {
    NSMutableArray *keyArray = [NSMutableArray array];
    for (int i=0; i<2000; i++) {
        NSString *key = [NSString stringWithFormat:@"testfkv%@", @(i)];
        [keyArray addObject:key];
    }
    if (sender.tag == 1) {
        [self logTimeTakenToRunBlock:^{
            [keyArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [[FastKV defaultFastKV] setInteger:idx forKey:obj];
            }];
        } withPrefix:@"FKV"];
        
    } else if (sender.tag == 2) {
        NSInteger integer = [[FastKV defaultFastKV] integerForKey:@"testfkv1"];
        NSLog(@"%zd", integer);
    } else if (sender.tag == 3) {
        
        [self logTimeTakenToRunBlock:^{
        [keyArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            FKVPair *pair = [[FKVPair alloc] init];
            pair.int32Val = (int32_t)idx;
            [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:pair] forKey:obj];
        }];
        } withPrefix:@"UserDefaults"];
    }
}

- (void)logTimeTakenToRunBlock:(void(^)(void))block withPrefix:(NSString *)prefixString {
    
    double a = CFAbsoluteTimeGetCurrent();
    block();
    double b = CFAbsoluteTimeGetCurrent();
    
    unsigned int m = ((b-a) * 1000.0f); // convert from seconds to milliseconds
    
    NSLog(@"fkv %@: %d ms", prefixString ? prefixString : @"Time taken", m);
}
@end
