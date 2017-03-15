//
//  MMChain.m
//  CookieCrunch
//
//  Created by Moosa Mir on 3/13/17.
//  Copyright © 2017 Moosa Mir. All rights reserved.
//

#import "MMChain.h"

@implementation MMChain{
    NSMutableArray *_cookies;
}

#pragma mark - addCookie
- (void)addCookie:(MMCookie *)cookie{
    if(_cookies == nil){
        _cookies = [NSMutableArray array];
    }
    [_cookies addObject:cookie];
}

#pragma mark - return cookies
- (NSArray *)cookies{
    return _cookies;
}

#pragma mark - description
- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld cookies:%@", (long)self.chainType, self.cookies];
}

@end
