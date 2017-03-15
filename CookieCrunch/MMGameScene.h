//
//  GameScene.h
//  CookieCrunch
//
//  Created by Moosa Mir on 3/8/17.
//  Copyright © 2017 Moosa Mir. All rights reserved.
//

@import SpriteKit;

@class MMLevel;
@class MMSwap;

@interface MMGameScene : SKScene

@property (nonatomic, strong) MMLevel *level;
@property (nonatomic, strong) void(^swipeHandler)(MMSwap *swap);

- (void)addSpritesForCookies:(NSSet*)cookies;

- (void)addTiles;
- (void)removeTiles;
#pragma mark  - animate swipe
- (void)animateSwipe:(MMSwap*)swap completion:(dispatch_block_t)compltion;
- (void)animateInvalidSwipe:(MMSwap*)swap completion:(dispatch_block_t)completion;

#pragma mark - animate matches cookie
- (void)animateMatchedCookies:(NSSet *)chains completion:(dispatch_block_t)completion;

#pragma mark - animate falling
- (void)animateFallingCookies:(NSArray *)columns completion:(dispatch_block_t)completion;

#pragma mark - animate new cookies
- (void)animateNewCookies:(NSArray *)columns completion:(dispatch_block_t)completion;

#pragma mark - animate gameover
- (void)animateGameover;
- (void)animateBegianGame;

#pragma mark - remove all cookies sprit
- (void)removeAllCookieSprit;
@end
