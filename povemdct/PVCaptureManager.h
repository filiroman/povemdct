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

@interface PVCaptureManager : NSObject

@property (nonatomic, assign) id<PVCaptureManagerDelegate> delegate;

+ (id)sharedManager;
- (void)sendFaceCaptureWithRect:(CGRect)captureRect;
- (void)sendData:(NSData*)data;
- (void)sendWindowSize:(CGSize)wsize;
- (void)sendGyroData:(CMGyroData*)gdata;
- (void)sendAccelerometerData:(CMAccelerometerData*)accdata;

@end

@protocol PVCaptureManagerDelegate <NSObject>

- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedFaceCaptureAtRect:(CGRect)captureRect;
- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedData:(NSData*)data;
- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedWindowSize:(CGSize)winSize;
- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedGyroscopeData:(CMGyroData*)gdata;
- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedAccelerometerData:(CMAccelerometerData*)accdata;

@end
