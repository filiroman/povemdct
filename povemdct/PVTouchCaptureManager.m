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
#import <objc/runtime.h>
#import "UIView+touchesDetector.h"

static PVTouchCaptureManager *sharedManager = nil;

Boolean AppTouched = false;     // provide a global for touch detection

static IMP iosBeginTouch = nil; // avoid lookup every time through
static IMP iosEndedTouch = nil;
static IMP iosCanedTouch = nil;

// implement detectors for UIView
@implementation  UIView (touchesBeganDetector)
- (void)touchesBeganDetector:(NSSet *)touches withEvent:(UIEvent *)event
{
    AppTouched = true;
    
    if ( iosBeginTouch == nil )
        iosBeginTouch = [self methodForSelector:
                         @selector(touchesBeganDetector:withEvent:)];
    
    iosBeginTouch( self, @selector(touchesBegan:withEvent:), touches, event );
}
@end

@implementation  UIView (touchesEndedDetector)
- (void)touchesEndedDetector:(NSSet *)touches withEvent:(UIEvent *)event
{
    AppTouched = false;
    
    if ( iosEndedTouch == nil )
        iosEndedTouch = [self methodForSelector:
                         @selector(touchesEndedDetector:withEvent:)];
    
    iosEndedTouch( self, @selector(touchesEnded:withEvent:), touches, event );
}
@end

static void Swizzle(Class c, SEL orig, SEL repl )
{
    Method origMethod = class_getInstanceMethod(c, orig );
    Method newMethod  = class_getInstanceMethod(c, repl );
    
    BOOL didAddMethod = class_addMethod( c, orig, method_getImplementation(newMethod),
                                        method_getTypeEncoding(newMethod));
    
    if (didAddMethod) {
        class_replaceMethod( c, repl, method_getImplementation(origMethod),
                            method_getTypeEncoding(origMethod) );
    }
    else {
        method_exchangeImplementations( origMethod, newMethod );
    }
}

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

#if TARGET_OS_IPHONE
- (void)pv_touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    AppTouched = true;
    
    if ( iosBeginTouch == nil )
        iosBeginTouch = [self methodForSelector:
                         @selector(pv_touchesBegan:withEvent:)];
    
    iosBeginTouch( self, @selector(touchesBegan:withEvent:), touches, event );
}

- (void)pv_touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    AppTouched = false;
    
    if ( iosEndedTouch == nil )
        iosEndedTouch = [self methodForSelector:
                         @selector(pv_touchesEnded:withEvent:)];
    
    iosEndedTouch( self, @selector(touchesEnded:withEvent:), touches, event );
}

- (void)pv_touchesCanceled:(NSSet *)touches withEvent:(UIEvent *)event
{
    AppTouched = false;
    
    if ( iosCanedTouch == nil )
        iosCanedTouch = [self methodForSelector:
                         @selector(pv_touchesCanceled:withEvent:)];
    
    iosCanedTouch( self, @selector(touchesCancelled:withEvent:), touches, event );
}
#endif

- (id)init
{
    if (self = [super init])
    {
        
        /*SEL beganOriginalSelector = @selector( touchesBegan:withEvent: );
        SEL beganSwizzledSelector = @selector( pv_touchesBegan:withEvent: );
        
        SEL endedOriginalSelector = @selector( touchesEnded:withEvent: );
        SEL endedSwizzledSelector = @selector( pv_touchesEnded:withEvent: );
        
        SEL canceledOriginalSelector = @selector( touchesCanceled:withEvent: );
        SEL canceledSwizzledSelector = @selector( pv_touchesCanceled:withEvent: );
        
#if TARGET_OS_IPHONE
        Swizzle([UIView class], beganOriginalSelector, beganSwizzledSelector);
        Swizzle([UIView class], endedOriginalSelector, endedSwizzledSelector);
        Swizzle([UIView class], canceledOriginalSelector, canceledSwizzledSelector);*/
        
        SEL rep = @selector( touchesBeganDetector:withEvent: );
        SEL orig = @selector( touchesBegan:withEvent: );
        Swizzle( [UIView class], orig, rep );
        
        rep = @selector( touchesEndedDetector:withEvent: );
        orig = @selector( touchesEnded:withEvent: );
        Swizzle( [UIView class], orig, rep );
//#endif
    }
    return self;
}

- (void)startTouchEvents
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(touched:)
                                                 name:kTouchPhaseBeganCustomNotification
                                               object:nil];
    
    //((PVWindow *)self.window).enableTouchNotifications = YES;
}

- (void)stopTouchEvents
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTouchPhaseBeganCustomNotification
                                                  object:nil];
    //((PVWindow *)self.window).enableTouchNotifications = NO;
}

- (void)touched:(NSNotification *)event
{
#if TARGET_OS_IPHONE
    UIEvent *touchEvent = event.object;
    NSSet *touches = [touchEvent allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:touch.view];
    [[PVCaptureManager sharedManager] sendTouchPoint:location];
    NSLog(@"%f / %f", location.x, location.y);
#endif
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTouchPhaseBeganCustomNotification
                                                  object:nil];
    //((PVWindow *)self.window).enableTouchNotifications = NO;
    [super dealloc];
}

- (NSString*)deviceCapabilities
{
    return @"touch";
}

@end
