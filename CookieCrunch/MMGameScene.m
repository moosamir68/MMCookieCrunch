//
//  GameScene.m
//  CookieCrunch
//
//  Created by Moosa Mir on 3/8/17.
//  Copyright © 2017 Moosa Mir. All rights reserved.
//

#import "MMGameScene.h"
#import "MMLevel.h"
#import "MMCookie.h"
#import "MMSwap.h"

static const CGFloat TileWidth = 32.0;
static const CGFloat TileHeight = 36.0;

@interface MMGameScene()

@property (nonatomic, strong) SKNode *gameLayer;
@property (nonatomic, strong) SKNode *cookiesLayer;
@property (nonatomic, strong) SKNode *tilesLayer;

@property (nonatomic, assign) NSInteger swipeFromColumn;
@property (nonatomic, assign) NSInteger swipeFromRow;

@property (nonatomic, strong) SKSpriteNode *selectionSprit;

@property (nonatomic, strong) SKAction *swapSound;
@property (nonatomic, strong) SKAction *invalidSwapSound;
@property (nonatomic, strong) SKAction *matchSound;
@property (nonatomic, strong) SKAction *fallingCookieSound;
@property (nonatomic, strong) SKAction *addCookieSound;

@end

@implementation MMGameScene

- (id)initWithSize:(CGSize)size{
    if ((self = [super initWithSize:size])) {
        
        self.anchorPoint = CGPointMake(0.5, 0.5);
        
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:background];
        
        [self setGameLayer:[SKNode node]];
        self.gameLayer.hidden = YES;
        [self addChild:self.gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth*NumColumns/2, -TileHeight*NumRows/2);
        
        [self setTilesLayer:[SKNode node]];
        [self.tilesLayer setPosition:layerPosition];
        [self.gameLayer addChild:self.tilesLayer];
        
        [self setCookiesLayer:[SKNode node]];
        [self.cookiesLayer setPosition:layerPosition];
        [self.gameLayer addChild:self.cookiesLayer];
        
        self.swipeFromColumn = self.swipeFromRow = NSNotFound;
        
        self.selectionSprit = [SKSpriteNode node];
        [self preLoadResoucre];
    }
    return self;
}

- (void)addSpritesForCookies:(NSSet *)cookies{
    for(MMCookie *cookie in cookies){
        SKSpriteNode *spritNode = [SKSpriteNode spriteNodeWithImageNamed:[cookie spritName]];
        [spritNode setPosition:[self pointForColumn:cookie.column andRow:cookie.row]];
        [self.cookiesLayer addChild:spritNode];
        [cookie setSprit:spritNode];
        
        cookie.sprit.alpha = 0;
        cookie.sprit.xScale = cookie.sprit.yScale = 0.5;
        
        [cookie.sprit runAction:[SKAction sequence:@[[SKAction waitForDuration:0.25 withRange:0.5], [SKAction group:@[[SKAction fadeInWithDuration:0.25], [SKAction scaleTo:1.0 duration:0.25]]]]]];
    }
}

- (CGPoint)pointForColumn:(NSInteger)column andRow:(NSInteger)row{
    return CGPointMake(column*TileWidth+ TileWidth/2, row*TileHeight + TileHeight/2);
}

- (void)addTiles{
    for(NSInteger row = 0; row < NumRows; row++){
        for(NSInteger column = 0; column < NumColumns; column++){
            if([self.level tileAtColumn:column andRow:row] != nil){
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"Tile"];
                [tileNode setPosition:[self pointForColumn:column andRow:row]];
                [self.tilesLayer addChild:tileNode];
            }
        }
    }
}

- (void)removeTiles{
    [self.tilesLayer removeAllChildren];
}

#pragma mark - touch
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //1
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookiesLayer];
    
    //2
    NSInteger column,row;
    if([self convertPoint:location withColumn:&column andRow:&row]){
        
        //3
        MMCookie *cookie = [self.level cookieAtColumn:column andRow:row];
        if(cookie !=nil){
            
            //4
            [self setSwipeFromRow:row];
            [self setSwipeFromColumn:column];
            
            //5
            [self showSelectionIndicatorForCookie:cookie];
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //1
    if(self.swipeFromColumn == NSNotFound)  return;
    
    //2
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookiesLayer];
    
    NSInteger column,row;
    if([self convertPoint:location withColumn:&column andRow:&row]){
        
        //3
        NSInteger horzDelta = 0,vertDelta = 0;
        if(column < self.swipeFromColumn){
            horzDelta = -1;                         // swipe left
        }else if(column > self.swipeFromColumn){
            horzDelta = 1;                          // swipe right
        }else if(row < self.swipeFromRow){
            vertDelta = -1;                          // swipe down
        }else if(row > self.swipeFromRow){
            vertDelta = 1;                          // swipe up
        }
        
        //4
        if(horzDelta != 0 || vertDelta != 0){
            [self trySwipeHorizontal:horzDelta andVertcal:vertDelta];
            
            self.swipeFromColumn = NSNotFound;
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.swipeFromColumn = self.swipeFromRow = NSNotFound;
    if(self.selectionSprit.parent != nil && self.swipeFromColumn != NSNotFound){
        [self hideSelectionIndicator];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self touchesEnded:touches withEvent:event];
}

#pragma mark - convert point to column and row
- (BOOL)convertPoint:(CGPoint)point withColumn:(NSInteger*)column andRow:(NSInteger*)row{
    NSParameterAssert(column);
    NSParameterAssert(row);
    
    // Is this a valid location within the cookies layer? If yes,
    // calculate the corresponding row and column numbers
    if(point.x >= 0 && point.x < NumColumns*TileWidth && point.y >=0 && point.y < NumRows*TileHeight){
        *column = point.x / TileWidth;
        *row = point.y / TileHeight;
        return YES;
    }else{
        *column = NSNotFound; // invalid location;
        *row = NSNotFound;
        return NO;
    }
}

#pragma mark - try swipe
- (void)trySwipeHorizontal:(NSInteger)horzDelta andVertcal:(NSInteger)vertDelta{
    
    //1
    NSInteger toColumn = self.swipeFromColumn + horzDelta;
    NSInteger toRow = self.swipeFromRow + vertDelta;
    
    //2
    if(toColumn < 0 || toColumn >= NumColumns) return;
    if(toRow < 0 || toRow >= NumRows) return;
    
    //3
    MMCookie *toCookie = [self.level cookieAtColumn:toColumn andRow:toRow];
    if(toCookie == nil) return;
    
    //4
    MMCookie *fromCookie = [self.level cookieAtColumn:self.swipeFromColumn andRow:self.swipeFromRow];
    
    if(fromCookie != nil) {
        [self hideSelectionIndicator];
    }
    
    if(self.swipeHandler != nil){
        MMSwap *swap = [[MMSwap alloc] init];
        [swap setCookieA:fromCookie];
        [swap setCookieB:toCookie];
        
        self.swipeHandler(swap);
    }
}

#pragma mark  - animate swipe
- (void)animateSwipe:(MMSwap*)swap completion:(dispatch_block_t)compltion{
    [swap.cookieA.sprit setZPosition:100];
    [swap.cookieB.sprit setZPosition:90];
    
    const NSTimeInterval duration = 0.3;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprit.position duration:duration];
    [moveA setTimingMode:SKActionTimingEaseOut];
    [swap.cookieA.sprit runAction:[SKAction sequence:@[moveA, [SKAction runBlock:compltion]]]];
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprit.position duration:duration];
    [moveB setTimingMode:SKActionTimingEaseOut];
    [swap.cookieB.sprit runAction:moveB];
    
    [self runAction:self.swapSound];
}

- (void)animateInvalidSwipe:(MMSwap*)swap completion:(dispatch_block_t)completion{
    [swap.cookieA.sprit setZPosition:100];
    [swap.cookieB.sprit setZPosition:90];
    
    const NSTimeInterval duration = 0.3;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprit.position duration:duration];
    [moveA setTimingMode:SKActionTimingEaseOut];
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprit.position duration:duration];
    [moveB setTimingMode:SKActionTimingEaseOut];
    
    [swap.cookieA.sprit runAction:[SKAction sequence:@[moveA, moveB, [SKAction runBlock:completion]]]];
    [swap.cookieB.sprit runAction:[SKAction sequence:@[moveB, moveA]]];
    [self runAction:self.invalidSwapSound];
}

#pragma mark - selection sprit
- (void)showSelectionIndicatorForCookie:(MMCookie*)cookie{
    // If the selection indicator is still visible, then first remove it.
    if(self.selectionSprit.parent != nil){
        [self.selectionSprit removeFromParent];
    }
    
    SKTexture *texture = [SKTexture textureWithImageNamed:[cookie highlightedSpritName]];
    self.selectionSprit.size = texture.size;
    [self.selectionSprit runAction:[SKAction setTexture:texture]];
    
    [cookie.sprit addChild:self.selectionSprit];
    self.selectionSprit.alpha = 1.0f;
    
}

- (void)hideSelectionIndicator{
    [self.selectionSprit runAction:[SKAction sequence:@[
                                                        [SKAction fadeInWithDuration:0.3],
                                                        [SKAction removeFromParent]]]];
}

#pragma mark -preload resource
- (void)preLoadResoucre{
    self.swapSound = [SKAction playSoundFileNamed:@"Chomp.wav" waitForCompletion:NO];
    self.invalidSwapSound = [SKAction playSoundFileNamed:@"Error.wav" waitForCompletion:NO];
    self.matchSound = [SKAction playSoundFileNamed:@"Ka-Ching.wav" waitForCompletion:NO];
    self.fallingCookieSound = [SKAction playSoundFileNamed:@"Scrape.wav" waitForCompletion:NO];
    self.addCookieSound = [SKAction playSoundFileNamed:@"Drip.wav" waitForCompletion:NO];
    [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
}

#pragma mark - animate matches cookie
- (void)animateMatchedCookies:(NSSet *)chains completion:(dispatch_block_t)completion{
    for(MMChain *chain in chains){
        
        [self animatePointScoreForChain:chain];
        for(MMCookie *cookie in chain.cookies){
            
            //1
            if(cookie.sprit != nil){
                
                //2
                SKAction *scaleAction = [SKAction scaleTo:0.1 duration:0.3];
                scaleAction.timingMode = SKActionTimingEaseOut;
                [cookie.sprit runAction:[SKAction sequence:@[scaleAction, [SKAction removeFromParent]]]];
                
                //3
                cookie.sprit = nil;
            }
        }
    }
    
    [self runAction:self.matchSound];
    
    //4
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.3],[SKAction runBlock:completion]]]];
}

#pragma mark - animate falling
- (void)animateFallingCookies:(NSArray *)columns completion:(dispatch_block_t)completion{
    
    //1
    __block NSTimeInterval longetDuration = 0;
    for(NSArray *array in columns){
        [array enumerateObjectsUsingBlock:^(MMCookie *cookie, NSUInteger idx, BOOL *stop) {
            CGPoint newPosition = [self pointForColumn:cookie.column andRow:cookie.row];
            
            //2
            NSTimeInterval delay = 0.05 + 0.15*idx;
            
            //3
            NSTimeInterval duration = ((cookie.sprit.position.y -newPosition.y) / TileHeight)* 0.1;
            
            //4
            longetDuration = MAX(delay + duration, longetDuration);
            
            //5
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            [cookie.sprit runAction:[SKAction sequence:@[[SKAction waitForDuration:delay], [SKAction group:@[moveAction, self.fallingCookieSound]]]]];
        }];
    }
    
    //6
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:longetDuration], [SKAction runBlock: completion]]]];
}

#pragma mark - animate new cookies
- (void)animateNewCookies:(NSArray *)columns completion:(dispatch_block_t)completion{
    
    //1
    __block NSTimeInterval longestDuration = 0;
    for(NSArray *array in columns){
        
        //2
        NSInteger startRow = ((MMCookie*)[array firstObject]).row + 1;
        
        [array enumerateObjectsUsingBlock:^(MMCookie *cookie, NSUInteger idx, BOOL *stop) {
            
            //3
            SKSpriteNode *sprit = [SKSpriteNode spriteNodeWithImageNamed:[cookie spritName]];
            sprit.position = [self pointForColumn:cookie.column andRow:startRow];
            [self.cookiesLayer addChild:sprit];
            cookie.sprit = sprit;
            
            //4
            NSTimeInterval delay = 0.1 + 0.2 *([array count] - idx - 1);
            
            //5
            NSTimeInterval duration = (startRow - cookie.row)* 0.1;
            longestDuration = MAX(duration + delay, longestDuration);
            
            //6
            CGPoint newPosition = [self pointForColumn:cookie.column andRow:cookie.row];
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            cookie.sprit.alpha = 0;
            
            [cookie.sprit runAction:[SKAction sequence:@[[SKAction waitForDuration:delay], [SKAction group:@[[SKAction fadeInWithDuration:0.05], moveAction, self.addCookieSound]]]]];
        }];
    }
    
    //7
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:longestDuration], [SKAction runBlock:completion]]]];
}

#pragma mark - animate point score
- (void)animatePointScoreForChain:(MMChain *)chain{
    // Figure out what the midpoint of the chain is.
    MMCookie *firstCookie = chain.cookies.firstObject;
    MMCookie *lastCookie = chain.cookies.lastObject;
    
    CGPoint centerPosition = CGPointMake((firstCookie.sprit.position.x + lastCookie.sprit.position.x)/2, (firstCookie.sprit.position.y + lastCookie.sprit.position.y)/2 -8);
    
    // Add a label for the score that slowly floats up.
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
    scoreLabel.fontSize = 16;
    scoreLabel.text = [NSString stringWithFormat:@"%lu",(long)chain.score];
    scoreLabel.position = centerPosition;
    scoreLabel.zPosition = 300;
    [self.cookiesLayer addChild:scoreLabel];
    
    SKAction *moveAction = [SKAction moveBy:CGVectorMake(0, 3) duration:0.7];
    moveAction.timingMode = SKActionTimingEaseOut;
    [scoreLabel runAction:[SKAction sequence:@[moveAction, [SKAction removeFromParent]]]];
}

#pragma mark - animate gameover
- (void)animateGameover{
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseIn;
    [self.gameLayer runAction:action];
}

- (void)animateBegianGame{
    self.gameLayer.hidden = NO;
    
    self.gameLayer.position = CGPointMake(0, self.size.height);
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseOut;
    [self.gameLayer runAction:action];
}

#pragma mark -remove all cookie sprit
- (void)removeAllCookieSprit{
    [self.cookiesLayer removeAllChildren];
}
@end
