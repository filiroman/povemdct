//
//  PVWindow.h
//  povemdct
//
//  Created by Roman Filippov on 22.05.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

#define kTouchPhaseBeganCustomNotification @"TouchPhaseBeganCustomNotification"

#if TARGET_OS_IPHONE
@interface PVWindow : UIWindow
#elif TARGET_OS_MAC
@interface PVWindow : NSWindow
#endif

@property (nonatomic, assign) BOOL enableTouchNotifications;

@end
