//
//  PVCaptureManager.h
//  povemdct
//
//  Created by Roman Filippov on 25.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>
#import "PVNetworkManager.h"
#import "PVManager.h"

@protocol PVCaptureManagerDelegate;
@protocol PVCaptureManagerCameraDelegate;
@protocol PVCaptureManagerGyroDelegate;
@protocol PVCaptureManagerTouchDelegate;

@interface PVCaptureManager : NSObject

@property (nonatomic, assign) PVApplicationType appType;

+ (id)sharedManager;
- (void)sendFaceCaptureWithRect:(CGRect)captureRect;
- (void)sendWindowSize:(CGSize)wsize;
- (void)sendGyroData:(CMGyroData*)gdata;
- (void)sendAccelerometerData:(CMAccelerometerData*)accdata;
- (void)sendMotionData:(CMDeviceMotion*)mdata;
- (void)sendTouchPoint:(CGPoint)touchPoint;

@end

@interface PVCaptureManager (SubscribeMethods)

- (void)subscribeToAllEvents:(id<PVCaptureManagerCameraDelegate, PVCaptureManagerGyroDelegate>) delegate;
- (void)subscribeToCameraEvents:(id<PVCaptureManagerCameraDelegate>) delegate;
- (void)subscribeToGyroEvents:(id<PVCaptureManagerGyroDelegate>) delegate;
- (void)subscribeToTouchEvents:(id<PVCaptureManagerTouchDelegate>) delegate;

@end

@protocol PVCaptureManagerDelegate <NSObject>

- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedData:(NSData*)data;
- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedWindowSize:(CGSize)winSize;

@end

@protocol PVCaptureManagerTouchDelegate <NSObject>

- (void)PVCaptureManager:(PVCaptureManager*)manager didReceivedTouchAtPosition:(CGPoint)touchPosition;

@end

@protocol PVCaptureManagerCameraDelegate <NSObject>

- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedFaceCaptureAtRect:(CGRect)captureRect;

@end

@protocol PVCaptureManagerGyroDelegate <NSObject>

- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedGyroscopeData:(CMGyroData*)gdata;
- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedAccelerometerData:(CMAccelerometerData*)accdata;
- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedMotionData:(CMDeviceMotion*)mdata;


@end
