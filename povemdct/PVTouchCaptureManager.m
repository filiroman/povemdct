//
//  PVTouchCaptureManager.m
//  povemdct
//
//  Created by Roman Filippov on 16.12.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVTouchCaptureManager.h"
#import "PVCaptureManager.h"
#import "PVWindow.h"

static PVTouchCaptureManager *sharedManager = nil;

@interface PVTouchCaptureManager ()

@property (nonatomic, assign) PVWindow *window;

@end

@implementation PVTouchCaptureManager

+ (id)sharedManager
{
    if (sharedManager == nil)
        sharedManager = [[PVTouchCaptureManager alloc] init];
    
    return sharedManager;
}

- (id)init
{
    if (self = [super init])
    {
#if TARGET_OS_IPHONE
        self.window = [[[UIApplication sharedApplication] windows]
                                               lastObject];
#elif TARGET_OS_MAC
        self.window = [[[NSApplication sharedApplication] windows]
                       lastObject];
#endif
    }
    return self;
}

- (void)startTouchEvents
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(touched:)
                                                 name:kTouchPhaseBeganCustomNotification
                                               object:nil];
    
    ((PVWindow *)self.window).enableTouchNotifications = YES;
}

- (void)stopTouchEvents
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTouchPhaseBeganCustomNotification
                                                  object:nil];
    ((PVWindow *)self.window).enableTouchNotifications = NO;
}

- (void)touched:(NSNotification *)event
{
#if TARGET_OS_IPHONE
    UIEvent *touchEvent = event.object;
    NSSet *touches = [touchEvent allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:touch.view];
    [[PVCaptureManager sharedManager] sendTouchPoint:location];
#endif
    
    NSLog(@"event received");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTouchPhaseBeganCustomNotification
                                                  object:nil];
    ((PVWindow *)self.window).enableTouchNotifications = NO;
    [super dealloc];
}

- (NSString*)deviceCapabilities
{
    return @"touch";
}

@end
