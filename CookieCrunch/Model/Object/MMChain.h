//
//  MMChain.h
//  CookieCrunch
//
//  Created by Moosa Mir on 3/13/17.
//  Copyright © 2017 Moosa Mir. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMCookie;

typedef NS_ENUM(NSUInteger, ChainType){
    ChainTypeHorizontal,
    ChainTypeVertical
};

@interface MMChain : NSObject

@property (nonatomic, strong, readonly) NSArray *cookies;
@property (nonatomic, assign) ChainType chainType;
@property (nonatomic, assign) NSUInteger score;

- (void)addCookie:(MMCookie *)cookie;
@end
