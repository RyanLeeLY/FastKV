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
//    [[FastKV defaultFastKV] removeAllKeys];
//    [self resetDefaults];

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

uint64_t dispatch_benchmark(size_t count, void (^block)(void));

- (IBAction)eventFromButton:(UIButton *)sender {
    NSMutableArray *keyArray = [NSMutableArray array];
    NSMutableArray *valueArray = [NSMutableArray array];
    for (int i=0; i<10000; i++) {
        [keyArray addObject:[NSString stringWithFormat:@"testfkv%@", @(i)]];
//        [valueArray addObject:[NSString stringWithFormat:@"value%ud", arc4random()]];
        [valueArray addObject:@(arc4random())];
    }
    if (sender.tag == 1) {
        __block int i = 0;
        uint64_t time = dispatch_benchmark(10000, ^{
            [[FastKV defaultFastKV] setInteger:[valueArray[i] integerValue] forKey:keyArray[i++]];
//            [[FastKV defaultFastKV] setObject:valueArray[i] forKey:keyArray[i++]];
        });
        NSLog(@"FastKV %@ms", @(time * 10000 / 1000000));
        
    } else if (sender.tag == 2) {
        __block int i = 0;
        uint64_t time = dispatch_benchmark(10000, ^{
            [[FastKV defaultFastKV] integerForKey:keyArray[i++]];
            
//            [[NSUserDefaults standardUserDefaults] integerForKey:keyArray[i++]];
        });
        NSLog(@"Get FastKV %@ms", @(time * 10000 / 1000000));
    } else if (sender.tag == 3) {
        [[FastKV defaultFastKV] removeObjectForKey:@"testfkv4800"];
    } else if (sender.tag == 4) {
        [[FastKV defaultFastKV] cleanUp];
        __block int i = 0;
        uint64_t time = dispatch_benchmark(10000, ^{
            [[NSUserDefaults standardUserDefaults] setInteger:[valueArray[i] integerValue] forKey:keyArray[i++]];
//            [[NSUserDefaults standardUserDefaults] setObject:valueArray[i] forKey:keyArray[i++]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        });
        NSLog(@"NSUserDefaults %@ms", @(time * 10000 / 1000000));
    }
}


- (void)resetDefaults {
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    NSDictionary * dict = [defs dictionaryRepresentation];
    for (id key in dict) {
        [defs removeObjectForKey:key];
    }
    [defs synchronize];
}

- (void)logTimeTakenToRunBlock:(void(^)(void))block withPrefix:(NSString *)prefixString {
    
    double a = CFAbsoluteTimeGetCurrent();
    block();
    double b = CFAbsoluteTimeGetCurrent();
    
    unsigned long m = ((b-a) * 1000000.0f); // convert from seconds to milliseconds
    
    NSLog(@"fkv %@: %lu ms", prefixString ? prefixString : @"Time taken", m);
}
@end
