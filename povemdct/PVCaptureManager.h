//
//  PVCaptureManager.h
//  povemdct
//
//  Created by Roman Filippov on 25.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@protocol PVCaptureManagerDelegate;
@protocol PVCaptureManagerCameraDelegate;
@protocol PVCaptureManagerGyroDelegate;

@interface PVCaptureManager : NSObject

+ (id)sharedManager;
- (void)sendFaceCaptureWithRect:(CGRect)captureRect;
- (void)sendData:(NSData*)data;
- (void)sendWindowSize:(CGSize)wsize;
- (void)sendGyroData:(CMGyroData*)gdata;
- (void)sendAccelerometerData:(CMAccelerometerData*)accdata;

@end

@interface PVCaptureManager (SubscribeMethods)

- (void)subscribeToAllEvents:(id<PVCaptureManagerCameraDelegate, PVCaptureManagerGyroDelegate>) delegate;
- (void)subscribeToCameraEvents:(id<PVCaptureManagerCameraDelegate>) delegate;
- (void)subscribeToGyroEvents:(id<PVCaptureManagerGyroDelegate>) delegate;

@end

@protocol PVCaptureManagerDelegate <NSObject>

- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedData:(NSData*)data;
- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedWindowSize:(CGSize)winSize;

@end

@protocol PVCaptureManagerCameraDelegate <NSObject>

- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedFaceCaptureAtRect:(CGRect)captureRect;

@end

@protocol PVCaptureManagerGyroDelegate <NSObject>

- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedGyroscopeData:(CMGyroData*)gdata;
- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedAccelerometerData:(CMAccelerometerData*)accdata;


@end
