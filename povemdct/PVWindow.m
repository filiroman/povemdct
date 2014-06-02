//
//  PVWindow.m
//  povemdct
//
//  Created by Roman Filippov on 22.05.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "PVWindow.h"

@implementation PVWindow

#if TARGET_OS_IPHONE
- (void)sendEvent:(UIEvent *)event
{
    [super sendEvent:event];  // Apple says you must always call this!
    
    if (self.enableTouchNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTouchPhaseBeganCustomNotification object:event];
    }
}
#elif TARGET_OS_MAC
- (void)sendEvent:(NSEvent *)event
{
    [super sendEvent:event];  // Apple says you must always call this!
    
    if (self.enableTouchNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTouchPhaseBeganCustomNotification object:event];
    }
}
#endif

@end
