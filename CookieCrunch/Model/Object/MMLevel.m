//
//  MMLevel.m
//  CookieCrunch
//
//  Created by Moosa Mir on 3/8/17.
//  Copyright © 2017 Moosa Mir. All rights reserved.
//

#import "MMLevel.h"
@interface MMLevel()
@property (nonatomic, strong) NSSet *possibleSwaps;
@property (nonatomic, assign) NSUInteger comboMultiplier;
@end

@implementation MMLevel{
    MMCookie *_cookies[NumColumns][NumRows];
    MMTile *_tiles[NumColumns][NumRows];
}

- (MMCookie*)cookieAtColumn:(NSInteger)column andRow:(NSInteger)row{
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);
    
    return _cookies[column][row];
}

- (NSSet*)shuffle{
    NSSet *set;
    do{
        set = [self createInitialCookies];
        [self detectPossibleSwape];
    }while([self.possibleSwaps count] == 0);
    return set;
}

- (NSSet*)createInitialCookies{
    NSMutableSet *set = [NSMutableSet set];
    //1
    for(NSInteger row = 0; row < NumRows; row++){
        for(NSInteger column = 0; column < NumColumns; column++){
            if(_tiles[column][row] != nil){
                //2
                NSInteger cookieType = 0;
                do{
                    cookieType = arc4random_uniform(NumCookieTypes) + 1;
                } while ((column >= 2 &&
                        _cookies[column - 1][row].cookieType == cookieType &&
                        _cookies[column - 2][row].cookieType == cookieType)
                       ||
                       (row >= 2 &&
                        _cookies[column][row - 1].cookieType == cookieType &&
                        _cookies[column][row - 2].cookieType == cookieType));
                
                //3
                MMCookie *cookie = [self createCookieAtColumn:column withRow:row andCookieType:cookieType];
                
                //4
                [set addObject:cookie];
            }
        }
    }
    return set;
}

- (MMCookie*)createCookieAtColumn:(NSInteger)column withRow:(NSInteger)row andCookieType:(NSUInteger)cookieType{
    MMCookie  *cookie = [[MMCookie alloc] init];
    [cookie setRow:row];
    [cookie setColumn:column];
    [cookie setCookieType:cookieType];
    _cookies[column][row] = cookie;
    return cookie;
}

- (NSDictionary*)locadJson:(NSString*)fileName{
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    if(path == nil){
        NSLog(@"Could not find level file: %@",fileName);
        return nil;
    }
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if(data == nil) {
        NSLog(@"Could not load level file %@, error: %@",fileName,error);
        return nil;
    }
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(dictionary == nil || ![dictionary isKindOfClass:[NSDictionary class]]){
        NSLog(@"level file '%@' is not valid json:%@ ",fileName, error);
        return nil;
    }
    
    return dictionary;
}

- (instancetype)initWithFile:(NSString *)fileName{
    self = [super init];
    if(self != nil) {
        NSDictionary *dictionry = [self locadJson:fileName];
        
        //loop though the rows
        [dictionry[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop) {
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop) {
                
                // Note: In Sprite Kit (0,0) is at the bottom of the screen,
                // so we need to read this file upside down.
                NSInteger tileRow = NumRows - row - 1;
                
                // If the value is 1, create a tile object.
                if([value integerValue] == 1){
                    _tiles[column][tileRow] = [[MMTile alloc] init];
                }
            }];
        }];
        self.targetScore = [dictionry[@"targetScore"] unsignedIntegerValue];
        self.maximumMoves = [dictionry[@"moves"] unsignedIntegerValue];
    }
    return self;
}

- (void)resetTils:(NSString*)fileName{
    
    for(NSInteger column = 0; column < NumColumns; column++){
        for(NSInteger row = 0; row < NumRows; row++){
            _tiles[column][row] = nil;
        }
    }
    
    if(self != nil) {
        NSDictionary *dictionry = [self locadJson:fileName];
        
        //loop though the rows
        [dictionry[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop) {
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop) {
                
                // Note: In Sprite Kit (0,0) is at the bottom of the screen,
                // so we need to read this file upside down.
                NSInteger tileRow = NumRows - row - 1;
                
                // If the value is 1, create a tile object.
                if([value integerValue] == 1){
                    _tiles[column][tileRow] = [[MMTile alloc] init];
                }
            }];
        }];
        self.targetScore = [dictionry[@"targetScore"] unsignedIntegerValue];
        self.maximumMoves = [dictionry[@"moves"] unsignedIntegerValue];
    }
}

- (MMTile*)tileAtColumn:(NSInteger)column andRow:(NSInteger)row{
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);
    
    return _tiles[column][row];
}

#pragma mark - swap
- (void)performSwap:(MMSwap*)swap{
    NSInteger columnA = swap.cookieA.column;
    NSInteger rowA = swap.cookieA.row;
    NSInteger columnB = swap.cookieB.column;
    NSInteger rowB = swap.cookieB.row;
    
    _cookies[columnA][rowA] = swap.cookieB;
    swap.cookieB.column = columnA;
    swap.cookieB.row = rowA;
    
    _cookies[columnB][rowB] = swap.cookieA;
    swap.cookieA.column = columnB;
    swap.cookieA.row = rowB;
//    [self detectPossibleSwape];
}

#pragma mrak - detect possible swape
- (void)detectPossibleSwape{
    NSMutableSet *set = [NSMutableSet set];
    
    for(NSInteger row = 0; row < NumRows; row++){
        for(NSInteger column = 0; column < NumColumns; column++){
            
            MMCookie *cookie = _cookies[column][row];
            // Is it possible to swap this cookie with the one on the right?
            if(cookie != nil){
                
                // Is it possible to swap this cookie with the one on the right?
                if(column < NumColumns -1){
                    // Have a cookie in this spot? If there is no tile, there is no cookie.
                    MMCookie *otherCookie = _cookies[column + 1][row];
                    if(otherCookie != nil){
                        //swap them
                        _cookies[column][row] = otherCookie;
                        _cookies[column + 1][row] = cookie;
                        
                        // Is either cookie now part of a chain?
                        if([self hasChainAtColumn:column + 1 andRow:row] || [self hasChainAtColumn:column andRow:row]){
                            MMSwap *swap = [[MMSwap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = otherCookie;
                            [set addObject:swap];
                        }
                        
                        //swape the back
                        _cookies[column][row] = cookie;
                        _cookies[column + 1][row] = otherCookie;
                    }
                }
                
                if(row < NumRows -1){
                    MMCookie *otherCookie = _cookies[column][row + 1];
                    if(otherCookie != nil){
                        _cookies[column][row] = otherCookie;
                        _cookies[column][row + 1] = cookie;
                        
                        if([self hasChainAtColumn:column andRow:row] || [self hasChainAtColumn:column andRow:row + 1]){
                            MMSwap *swap = [[MMSwap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = otherCookie;
                            [set addObject:swap];
                        }
                        
                        _cookies[column][row] = cookie;
                        _cookies[column][row + 1] = otherCookie;
                    }
                }
            }
        }
    }
    [self setPossibleSwaps:set];
    NSLog(@"possible swaps: %@", self.possibleSwaps);
}

- (BOOL)hasChainAtColumn:(NSInteger)column andRow:(NSInteger)row{
    NSUInteger cookieType = _cookies[column][row].cookieType;
    
    NSUInteger horzLenght = 1;
    for(NSInteger i = column - 1; i >= 0 && _cookies[i][row].cookieType == cookieType; i--,horzLenght++);
    for(NSInteger i = column + 1; i < NumColumns && _cookies[i][row].cookieType == cookieType; i++,horzLenght++);
    if(horzLenght >= 3) return YES;
    
    NSUInteger vertLenght = 1;
    for(NSInteger i = row - 1; i >= 0 && _cookies[column][i].cookieType == cookieType; i--,vertLenght++);
    for(NSInteger i = row + 1; i < NumRows && _cookies[column][i].cookieType == cookieType; i++,vertLenght++);
    return (vertLenght >= 3);
}

- (BOOL)isPossibleSape:(MMSwap *)swape{
//    return [self.possibleSwaps containsObject:swape];
    MMCookie *cookieA = swape.cookieA;
    MMCookie *cookieB = swape.cookieB;
    _cookies[cookieA.column][cookieA.row] = cookieB;
    _cookies[cookieB.column][cookieB.row] = cookieA;
    
    BOOL isPossible = [self hasChainAtColumn:cookieB.column andRow:cookieB.row];

    if(cookieB.cookieType == cookieA.cookieType) isPossible = NO;
    
    _cookies[cookieA.column][cookieA.row] = cookieA;
    _cookies[cookieB.column][cookieB.row] = cookieB;
    
    return isPossible;
}

#pragma mark - detecet horizontal matches
- (NSSet *)detectHorizontalMathces{
    NSMutableSet *set = [NSMutableSet set];
    
    //2
    for(NSInteger row = 0; row < NumRows; row++){
        for(NSInteger column = 0; column < NumColumns -2; ){
            
            //3
            if(_cookies[column][row] != nil){
                NSUInteger matchesType = _cookies[column][row].cookieType;
                
                //4
                if(_cookies[column + 1][row].cookieType == matchesType && _cookies[column + 2][row].cookieType == matchesType){
                    
                    //5
                    MMChain *chain = [[MMChain alloc] init];
                    [chain setChainType:ChainTypeHorizontal];
                    do{
                        [chain addCookie:_cookies[column][row]];
                        column += 1;
                    }while(column < NumColumns && _cookies[column][row].cookieType == matchesType);
                    [set addObject:chain];
                    continue;
                }
            }
            
            //6
            column += 1;
        }
    }
    return set;
}

- (NSSet *)detectVerticalMatches{
    NSMutableSet *set = [NSMutableSet set];
    
    for(NSInteger column = 0; column < NumColumns; column++){
        for(NSInteger row = 0; row < NumRows -2; ){
            if(_cookies[column][row] != nil){
                NSUInteger matcheType = _cookies[column][row].cookieType;
                
                if(_cookies[column][row + 1].cookieType == matcheType && _cookies[column][row + 2].cookieType == matcheType){
                    MMChain *chain = [[MMChain alloc] init];
                    [chain setChainType:ChainTypeVertical];
                    do{
                        [chain addCookie:_cookies[column][row]];
                        row += 1;
                    }while(row < NumColumns && _cookies[column][row].cookieType == matcheType);
                    [set addObject:chain];
                    continue;
                }
            }
            row += 1;
        }
    }
    
    return set;
}

#pragma mark - remove chains
- (NSSet *)removeMatches{
    NSSet *horizontalChains = [self detectHorizontalMathces];
    NSSet *verticalChains = [self detectVerticalMatches];
    
    NSLog(@"Horizontal matches: %@", horizontalChains);
    NSLog(@"Vertical matches: %@", verticalChains);
    
    [self removeCookies:horizontalChains];
    [self removeCookies:verticalChains];
    
    [self calculateScores:horizontalChains];
    [self calculateScores:verticalChains];
    
    return [horizontalChains setByAddingObjectsFromSet:verticalChains];
}

#pragma mark -remove cookie
- (void)removeCookies:(NSSet *)chains{
    for(MMChain *chain in chains){
        for(MMCookie *cookie in chain.cookies){
            _cookies[cookie.column][cookie.row] = nil;
        }
    }
}

#pragma mark - fill holes
- (NSArray *)fillHoles{
    NSMutableArray *columns = [NSMutableArray array];
    
    //1
    for(NSInteger column = 0; column < NumColumns; column++){
        
        NSMutableArray *array;
        for(NSInteger row = 0; row < NumRows; row++){
            
            //2
            if(_tiles[column][row] != nil && _cookies[column][row] == nil){
                
                //3
                for(NSInteger lookUp = row + 1; lookUp <NumRows; lookUp++){
                    MMCookie *cookie = _cookies[column][lookUp];
                    if(cookie != nil){
                        
                        //4
                        _cookies[column][lookUp] = nil;
                        _cookies[column][row] = cookie;
                        cookie.row = row;
                        
                        //5
                        if(array == nil){
                            array = [NSMutableArray array];
                            [columns addObject:array];
                        }
                        [array addObject:cookie];
                        
                        //6
                        break;
                    }
                }
            }
        }
    }
    
    return columns;
}

#pragma mark -top up cookies
- (NSArray *)topUpCookies{
    NSMutableArray *columns = [NSMutableArray array];
    
    NSUInteger cookieType = 0;
    
    for(NSInteger column = 0; column < NumColumns; column++){
        
        NSMutableArray *array;
        
        //1
        for(NSInteger row = NumRows - 1; row >= 0 && _cookies[column][row] == nil; row--){
            
            //2
            if(_tiles[column][row] != nil) {
                
                //3
                NSUInteger newCookieType;
                do{
                    newCookieType = arc4random_uniform(NumCookieTypes) + 1;
                }while(newCookieType == cookieType);
                cookieType = newCookieType;
                
                //4
                MMCookie *cookie = [self createCookieAtColumn:column withRow:row andCookieType:cookieType];
                
                //5
                if(array == nil){
                    array = [NSMutableArray array];
                    [columns addObject:array];
                }
                [array addObject:cookie];
            }
        }
    }
    return columns;
}

#pragma mark -calculate score
- (void)calculateScores:(NSSet *)chains{
    for(MMChain *chain in chains){
        chain.score = 60 *([chain.cookies count] -2) *self.comboMultiplier;
        self.comboMultiplier++;
    }
}

#pragma mark -reset comboMultiPlier
- (void)resetComboMultiPlier{
    self.comboMultiplier = 1;
}
@end
