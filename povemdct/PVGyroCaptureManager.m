//
//  PVGyroCaptureViewController.m
//  povemdct
//
//  Created by Roman Filippov on 21.11.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//
#import <CoreMotion/CoreMotion.h>
#import "PVGyroCaptureManager.h"
#import "PVCaptureManager.h"

#define SEGMENTED_GYRO 0
#define SEGMENTED_ACCL 1

#define UPDATE_SPEED 1.0f / 20.0f

static PVGyroCaptureManager *sharedManager = nil;

@interface PVGyroCaptureManager ()

@property (nonatomic, retain) CMMotionManager *motionManager;

@end

@implementation PVGyroCaptureManager

+ (PVGyroCaptureManager*)sharedManager
{
    if (sharedManager == nil)
        sharedManager = [[PVGyroCaptureManager alloc] init];
    
    return sharedManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        self.motionManager = [[[CMMotionManager alloc] init] autorelease];
    }
    return self;
}

- (void)stopGyro
{
    if ([self.motionManager isGyroActive])
        [self.motionManager stopGyroUpdates];
}

- (void)stopAccelerometer
{
    if ([self.motionManager isAccelerometerActive])
        [self.motionManager stopAccelerometerUpdates];
}

- (NSString*)deviceCapabilities
{
    NSMutableString *capabilities = [NSMutableString string];
    
    if ([self.motionManager isGyroAvailable])
        [capabilities appendString:@"gyro"];
    if ([self.motionManager isAccelerometerAvailable])
        [capabilities appendString:@",accelerometer"];
    if ([self.motionManager isDeviceMotionAvailable])
        [capabilities appendString:@",devicemotion"];
    
    return capabilities;
}

- (BOOL)startAccelerometerEvents
{
    BOOL started = NO;
    
    [self stopGyro];
    
    //accelerometer
    if([self.motionManager isAccelerometerAvailable])
    {
        /* Start the accelerometer if it is not active already */
        if([self.motionManager isAccelerometerActive] == NO)
        {
            /* Update us 2 times a second */
            [self.motionManager setAccelerometerUpdateInterval:UPDATE_SPEED];
            
            /* Add on a handler block object */
            
            PVCaptureManager *captureManager = [PVCaptureManager sharedManager];
            
            /* Receive the accelerometer data on this block */
            
            [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                
                //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [captureManager sendAccelerometerData:accelerometerData];
                //});
               
                
            }];
            
            started = YES;
            
        }
    }
    else
    {
        NSLog(@"Accelerometer not Available!");
    }
    
    return started;
}

- (BOOL)startMotionEvents
{
    
    BOOL started = NO;
    
    [self stopAccelerometer];
    [self stopGyro];
    
    if ([self.motionManager isDeviceMotionAvailable])
    {
        if ([self.motionManager isDeviceMotionActive] == NO)
        {
            [self.motionManager setDeviceMotionUpdateInterval:UPDATE_SPEED];
            
            PVCaptureManager *captureManager = [PVCaptureManager sharedManager];
            
            [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSLog(@"%.3f / %.3f", motion.gravity.y, motion.gravity.x);
                    [captureManager sendMotionData:motion];
                    //NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
                    
                    //NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];
                    //NSData *timeData = [NSKeyedArchiver archivedDataWithRootObject:timeStampObj];
                    //[captureManager sendData:timeData withType:TIME_DATA];
                });
                
            }];
            
            started = YES;
        }
    }
    else
    {
        NSLog(@"Device motion is not Available! Consider to use raw methods!");
    }
    
    return started;
}

- (BOOL)startGyroEvents
{
    BOOL started = NO;
    
    [self stopAccelerometer];
    
    //Gyroscope
    if([self.motionManager isGyroAvailable])
    {
        /* Start the gyroscope if it is not active already */
        if([self.motionManager isGyroActive] == NO)
        {
            /* Update us 2 times a second */
            [self.motionManager setGyroUpdateInterval:UPDATE_SPEED];
            
            /* Add on a handler block object */
            
            PVCaptureManager *captureManager = [PVCaptureManager sharedManager];
            
            /* Receive the gyroscope data on this block */
            [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
                                            withHandler:^(CMGyroData *gyroData, NSError *error)
             {
                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                     [captureManager sendGyroData:gyroData];
                 });
                 
             }];
            
            started = YES;
        }
    }
    else
    {
        NSLog(@"Gyroscope not Available!");
    }
    return started;
}

- (void)dealloc
{
    self.motionManager = nil;
    
    [super dealloc];
}

@end
