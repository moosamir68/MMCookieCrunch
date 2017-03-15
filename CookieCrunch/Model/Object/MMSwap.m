//
//  MMSwap.m
//  CookieCrunch
//
//  Created by Moosa Mir on 3/8/17.
//  Copyright © 2017 Moosa Mir. All rights reserved.
//

#import "MMSwap.h"
#import "MMCookie.h"

@implementation MMSwap

- (NSString*)description{
    return [NSString stringWithFormat:@"%@ swap %@ with %@", [super description], self.cookieA, self.cookieB];
}

- (BOOL)isEqual:(id)object{
    if(![object isKindOfClass:[MMSwap class]]) return NO;
    
    MMSwap *otherSwap = (MMSwap*)object;
    return (otherSwap.cookieA == self.cookieA && otherSwap.cookieB == self.cookieB) ||(otherSwap.cookieB == self.cookieA && otherSwap.cookieA == self.cookieB);
}

- (NSUInteger)hash{
    return [self.cookieA hash]^[self.cookieB hash];
}
@end
