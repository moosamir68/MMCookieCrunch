//
//  MMCookie.m
//  CookieCrunch
//
//  Created by Moosa Mir on 3/8/17.
//  Copyright © 2017 Moosa Mir. All rights reserved.
//

#import "MMCookie.h"

@implementation MMCookie

- (NSString*)spritName{
    static NSString * const spritNames[] = {@"Croissant",
                            @"Cupcake",
                            @"Danish",
                            @"Donut",
                            @"Macaroon",
                            @"SugarCookie"};
    return spritNames[self.cookieType - 1];
}

- (NSString*)highlightedSpritName{
    static NSString * const highlitedSpritNames[] = {@"Croissant-Highlighted",
        @"Cupcake-Highlighted",
        @"Danish-Highlighted",
        @"Donut-Highlighted",
        @"Macaroon-Highlighted",
        @"SugarCookie-Highlighted"};
    return highlitedSpritNames[self.cookieType - 1];
}

- (NSString*)description{
    return [NSString stringWithFormat:@"type:%ld square:(%ld,%ld)", (long)self.cookieType,
            (long)self.column, (long)self.row];
}

@end
