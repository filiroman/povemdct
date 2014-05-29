//
//  UIView+touchesDetector.m
//  povemdct
//
//  Created by Roman Filippov on 28.05.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "UIView+touchesDetector.h"
#import <objc/runtime.h>

Boolean AppTouched = false;     // provide a global for touch detection

static IMP iosBeginTouch = nil; // avoid lookup every time through
static IMP iosEndedTouch = nil;
static IMP iosCanedTouch = nil;

@implementation UIView (touchesDetector)

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

/*+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class self_class = [self class];
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        
        SEL beganOriginalSelector = @selector( touchesBegan:withEvent: );
        SEL beganSwizzledSelector = @selector( pv_touchesBegan:withEvent: );
        
        SEL endedOriginalSelector = @selector( touchesEnded:withEvent: );
        SEL endedSwizzledSelector = @selector( pv_touchesEnded:withEvent: );
        
        SEL canceledOriginalSelector = @selector( touchesCanceled:withEvent: );
        SEL canceledSwizzledSelector = @selector( pv_touchesCanceled:withEvent: );
        
        Swizzle(self_class, beganOriginalSelector, beganSwizzledSelector);
        Swizzle(self_class, endedOriginalSelector, endedSwizzledSelector);
        Swizzle(self_class, canceledOriginalSelector, canceledSwizzledSelector);
    });
}*/

#pragma mark - Method Swizzling

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

@end
