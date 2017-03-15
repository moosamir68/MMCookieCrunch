//
//  MMLevel.h
//  CookieCrunch
//
//  Created by Moosa Mir on 3/8/17.
//  Copyright © 2017 Moosa Mir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMCookie.h"
#import "MMTile.h"
#import "MMSwap.h"
#import "MMChain.h"

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

@interface MMLevel : NSObject

@property (nonatomic, assign) NSUInteger targetScore;
@property (nonatomic, assign) NSUInteger maximumMoves;

- (NSSet*)shuffle;
- (MMCookie*)cookieAtColumn:(NSInteger)column andRow:(NSInteger)row;

- (instancetype)initWithFile:(NSString*)fileName;

- (MMTile*)tileAtColumn:(NSInteger)column andRow:(NSInteger)row;

- (void)performSwap:(MMSwap*)swap;

- (BOOL)isPossibleSape:(MMSwap *)swape;

- (NSSet *)removeMatches;

- (NSArray *)fillHoles;

- (NSArray *)topUpCookies;

- (void)detectPossibleSwape;

- (void)calculateScores:(NSSet *)chains;

- (void)resetComboMultiPlier;

- (void)resetTils:(NSString*)fileName;
@end
