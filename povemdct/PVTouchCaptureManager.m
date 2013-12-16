//
//  PVTouchCaptureManager.m
//  povemdct
//
//  Created by Roman Filippov on 16.12.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVTouchCaptureManager.h"
#import "PVCaptureManager.h"
#import <UIKit/UIKit.h>

@interface PVTouchCaptureManager ()

@property (nonatomic, retain) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, retain) UIView *parentView;

@end

@implementation PVTouchCaptureManager

- (BOOL)startTouchEvents:(UIView*)parent
{
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    self.tapRecognizer.numberOfTapsRequired = 1;
    self.parentView = parent;
    
    [parent addGestureRecognizer:self.tapRecognizer];
}

- (void)tapDetected:(UIGestureRecognizer *)gestureRecognizer
{
    
    if (gestureRecognizer.state==UIGestureRecognizerStateEnded)
    {
        
        CGPoint point = [gestureRecognizer locationInView:self.parentView];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PVCaptureManager sharedManager] sendTouchPoint:point];
        });
    }
}

- (void)dealloc
{
    self.tapRecognizer = nil;
}

@end
