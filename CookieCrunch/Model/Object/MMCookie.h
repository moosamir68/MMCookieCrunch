//
//  MMCookie.h
//  CookieCrunch
//
//  Created by Moosa Mir on 3/8/17.
//  Copyright © 2017 Moosa Mir. All rights reserved.
//
@import SpriteKit;

static const NSUInteger NumCookieTypes = 6;
#import <Foundation/Foundation.h>

@interface MMCookie : NSObject
@property (nonatomic, assign) NSInteger column;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, assign) NSUInteger cookieType;
@property (nonatomic, strong) SKSpriteNode *sprit;

- (NSString*)spritName;
- (NSString*)highlightedSpritName;
@end
