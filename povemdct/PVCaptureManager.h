//
//  PVCaptureManager.h
//  povemdct
//
//  Created by Roman Filippov on 25.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PVCaptureManagerDelegate;

@interface PVCaptureManager : NSObject

@property (nonatomic, assign) id<PVCaptureManagerDelegate> delegate;

+ (id)sharedManager;
- (void)sendFaceCaptureWithRect:(CGRect)captureRect;

@end

@protocol PVCaptureManagerDelegate <NSObject>

- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedFaceCaptureAtRect:(CGRect)captureRect;

@end
