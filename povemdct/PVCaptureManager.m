//
//  PVCaptureManager.m
//  povemdct
//
//  Created by Roman Filippov on 25.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVCaptureManager.h"
#import "PVNetworkManager.h"
#import "NSData+NSValue.h"
#import "NSMutableArray+NonRetaining.h"
#import "PVTouchCaptureManager.h"
#if TARGET_OS_IPHONE
    #import "PVGyroCaptureManager.h"
#endif

static PVCaptureManager *sharedManager;

@interface PVCaptureManager ()

@property (retain, nonatomic) PVNetworkManager *networkManager;
@property (retain, nonatomic) NSMutableDictionary *delegates;

#if TARGET_OS_IPHONE

@property (retain, nonatomic) PVGyroCaptureManager *gyroCapture;

#endif
@property (retain, nonatomic) PVTouchCaptureManager *touchCapture;

@end

@implementation PVCaptureManager

- (id)init
{
    if (self = [super init])
    {
        self.delegates = [NSMutableDictionary dictionary];
        
        self.networkManager = [PVNetworkManager sharedManager];
        [self.networkManager start:(id)self];
        
        #if TARGET_OS_IPHONE
        self.gyroCapture = [PVGyroCaptureManager sharedManager];
        #endif
        
        self.touchCapture = [PVTouchCaptureManager sharedManager];
    }
    return self;
}

- (NSString*)deviceCapabilities
{
    NSMutableString *capabilities = [NSMutableString string];
    #if TARGET_OS_IPHONE
    [capabilities appendString:[self.gyroCapture deviceCapabilities]];
    #endif
    [capabilities appendString:[self.touchCapture deviceCapabilities]];
    
    return capabilities;
}

- (void)dealloc
{
    self.delegates = nil;
    
    #if TARGET_OS_IPHONE
    self.gyroCapture = nil;
    #endif
    self.touchCapture = nil;
    self.networkManager = nil;
    
    [super dealloc];
}

+ (id)sharedManager
{
    if (sharedManager == nil)
        sharedManager = [[PVCaptureManager alloc] init];
    return sharedManager;
}

#pragma mark send methods

- (void)sendFaceCaptureWithRect:(CGRect)captureRect
{
    NSDictionary *sdata = @{@"x": [NSNumber numberWithFloat:captureRect.origin.x], @"y" : [NSNumber numberWithFloat:captureRect.origin.y], @"width" : [NSNumber numberWithFloat:captureRect.size.width], @"height" : [NSNumber numberWithFloat:captureRect.size.height]};
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:sdata];
    //[self.networkManager sendData:sendingData];
}

- (void)sendWindowSize:(CGSize)wsize
{
    NSDictionary *sdata = @{@"width" : [NSNumber numberWithFloat:wsize.width], @"height" : [NSNumber numberWithFloat:wsize.height]};
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:sdata];
    //[self.networkManager sendData:sendingData withType:WINSIZE_DATA];
}

- (void)sendData:(NSData *)data withType:(int)dataType
{
    NSArray *motionDelegates = [_delegates objectForKey:@"general"];

    for (NSDictionary *device in motionDelegates) {
        [self.networkManager sendData:data withType:dataType toDevice:device];
    }
}

- (void)sendTouchPoint:(CGPoint)touchPoint
{
    NSDictionary *sdata = @{@"x": [NSNumber numberWithFloat:touchPoint.x], @"y": [NSNumber numberWithFloat:touchPoint.y]};
    
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:sdata];
    //[self.networkManager sendData:sendingData withType:TOUCH_DATA];
}

#if TARGET_OS_IPHONE

- (void)sendGyroData:(CMGyroData*)gdata
{
    PVGyroData *gyroData = [PVGyroData gyroDataWithData:gdata];
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:gyroData];
    
    NSArray *gyroDelegates = [_delegates objectForKey:@"gyro"];
    
    assert(gyroDelegates != nil);
    
    for (NSDictionary *device in gyroDelegates) {
        [self.networkManager sendData:sendingData withType:GYRO_DATA toDevice:device];
    }
}

- (void)sendAccelerometerData:(CMAccelerometerData*)accdata
{
    PVAccelerometerData *acclData = [PVAccelerometerData accelerometerDataWithData:accdata];
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:acclData];
    
    NSArray *acclDelegates = [_delegates objectForKey:@"accl"];
    
    assert(acclDelegates != nil);
    
    for (NSDictionary *device in acclDelegates) {
        [self.networkManager sendData:sendingData withType:ACCL_DATA toDevice:device];
    }
}

- (void)sendMotionData:(CMDeviceMotion*)mdata
{
    PVMotionData *motionData = [PVMotionData motionDataWithData:mdata];
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:motionData];
    
    NSArray *motionDelegates = [_delegates objectForKey:@"motion"];
    
    assert(motionDelegates != nil);
    
    for (NSDictionary *device in motionDelegates) {
        [self.networkManager sendData:sendingData withType:MOTION_DATA toDevice:device];
    }
}

#endif

#pragma mark network methods

- (void)PVNetworkManager:(PVNetworkManager*)manager didReceivedData:(NSData*)data fromDevice:(NSDictionary*)device withType:(int)dataType
{
    if (dataType == CONTROL_DATA)
    {
        NSDictionary *rdict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        NSString *type = [rdict objectForKey:@"type"];
        
        if ([type isEqualToString:@"subscribe"])
        {
            NSString *event = [rdict objectForKey:@"event"];
            
            //NSDictionary *device = [rdict objectForKey:@"device"];
            
            if ([event isEqualToString:@"camera"])
            {
                [self subscribeToCameraEvents:(id)self forDevice:device];
            } else if ([event isEqualToString:@"motion"])
            {
                [self subscribeToMotionEvents:(id)self forDevice:device];
            } else if ([event isEqualToString:@"gyro"])
            {
                [self subscribeToGyroEvents:(id)self forDevice:device];
            } else if ([event isEqualToString:@"accl"])
            {
                [self subscribeToAccelerometerEvents:(id)self forDevice:device];
            } else if ([event isEqualToString:@"touch"])
            {
                [self subscribeToTouchEvents:(id)self forDevice:device];
            }
        }
    }
    else if (dataType == CAPTURE_DATA) {
        
        NSDictionary *rdict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
        CGRect captureRect = CGRectMake([[rdict objectForKey:@"x"] floatValue], [[rdict objectForKey:@"y"] floatValue], [[rdict objectForKey:@"width"] floatValue], [[rdict objectForKey:@"height"] floatValue]);
        
        NSMutableArray *cameraDelegates = [_delegates objectForKey:@"camera"];
        
        for (id<PVCaptureManagerCameraDelegate> delegate in cameraDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didRecievedFaceCaptureAtRect:fromDevice:)])
                [delegate PVCaptureManager:self didRecievedFaceCaptureAtRect:captureRect fromDevice:device];
        }
        
    } else if (dataType == WINSIZE_DATA)
    {
        
        NSDictionary *rdict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
        CGSize winSize = CGSizeMake([[rdict objectForKey:@"width"] floatValue], [[rdict objectForKey:@"height"] floatValue]);
        
        NSMutableArray *systemDelegates = [_delegates objectForKey:@"system"];
        
        for (id<PVCaptureManagerDelegate> delegate in systemDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didRecievedWindowSize:fromDevice:)])
                [delegate PVCaptureManager:self didRecievedWindowSize:winSize fromDevice:device];
        }
        
    } else if (dataType == GYRO_DATA)
    {
        PVGyroData *gdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        NSMutableArray *gyroDelegates = [_delegates objectForKey:@"gyro"];
        
        for (id<PVCaptureManagerGyroDelegate> delegate in gyroDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didRecievedGyroscopeData:fromDevice:)])
                [delegate PVCaptureManager:self didRecievedGyroscopeData:gdata fromDevice:device];
        }
        
    } else if (dataType == ACCL_DATA)
    {
        PVAccelerometerData *accdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        NSMutableArray *acclDelegates = [_delegates objectForKey:@"accl"];
        
        for (id<PVCaptureManagerGyroDelegate> delegate in acclDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didRecievedAccelerometerData:fromDevice:)])
                [delegate PVCaptureManager:self didRecievedAccelerometerData:accdata fromDevice:device];
        }
    } else if (dataType == MOTION_DATA)
    {
        PVMotionData *mdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        NSMutableArray *motionDelegates = [_delegates objectForKey:@"motion"];
        
        for (id<PVCaptureManagerGyroDelegate> delegate in motionDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didRecievedMotionData:fromDevice:)])
                [delegate PVCaptureManager:self didRecievedMotionData:mdata fromDevice:device];
        }
    } else if (dataType == TOUCH_DATA)
    {
        NSDictionary *tdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        CGPoint point = CGPointMake([[tdata objectForKey:@"x"] floatValue], [[tdata objectForKey:@"y"] floatValue]);
        
        NSMutableArray *touchDelegates = [_delegates objectForKey:@"touch"];
        
        for (id<PVCaptureManagerTouchDelegate> delegate in touchDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didReceivedTouchAtPosition:fromDevice:)])
                [delegate PVCaptureManager:self didReceivedTouchAtPosition:point fromDevice:device];
        }
    } else if (dataType == TIME_DATA)
    {
        NSNumber *timeData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        double diff = [[NSDate date] timeIntervalSince1970] - [timeData doubleValue];
        
        NSString *str = [NSString stringWithFormat:@"%f\n", diff*1000];
        
        /*NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"file.txt"];
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];*/
        
        NSLog(@"%@", str);
    }
    
}

@end


@implementation PVCaptureManager (SubscribeMethods)

- (void)supscribeWithEvent:(NSString*)event andDevice:(NSDictionary*)device
{
    NSMutableDictionary *commands = [NSMutableDictionary dictionary];
    [commands setObject:@"subscribe" forKey:@"type"];
    [commands setObject:event forKey:@"event"];
    [commands setObject:device forKey:@"device"];
    
    NSData *hdata = [NSKeyedArchiver archivedDataWithRootObject:commands];
    
    assert(hdata != nil);
    
    [self.networkManager sendData:hdata withType:CONTROL_DATA toDevice:device];
}

- (void)subscribeToAllEvents:(id<PVCaptureManagerCameraDelegate, PVCaptureManagerGyroDelegate>) delegate forDevice:(NSDictionary*)device
{
    //[self subscribeToCameraEvents:delegate];
    //[self subscribeToGyroEvents:delegate];
}

- (void)subscribeToCameraEvents:(id<PVCaptureManagerCameraDelegate>) delegate forDevice:(NSDictionary*)device
{
    NSMutableArray *cameraDelegates = [_delegates objectForKey:@"camera"];
    if (cameraDelegates == nil)
    {
        cameraDelegates = [NSMutableArray array];
        [_delegates setObject:cameraDelegates forKey:@"camera"];
    }
    
    if (self.appType == PVApplicationTypeClient) {
        
        if (![cameraDelegates containsObject:delegate])
            [cameraDelegates addObject:delegate];
    
        [self supscribeWithEvent:@"camera" andDevice:device];
    }
}

- (void)subscribeToGyroEvents:(id<PVCaptureManagerGyroDelegate>) delegate forDevice:(NSDictionary*)device
{
    NSMutableArray *gyroDelegates = [_delegates objectForKey:@"gyro"];
    if (gyroDelegates == nil)
    {
        gyroDelegates = [NSMutableArray array];
        [_delegates setObject:gyroDelegates forKey:@"gyro"];
    }
    
    if (self.appType == PVApplicationTypeClient) {
        
        if (![gyroDelegates containsObject:delegate])
            [gyroDelegates addObject:delegate];
        
        [self supscribeWithEvent:@"gyro" andDevice:device];
    } else {
        #if TARGET_OS_IPHONE
        [self.gyroCapture startGyroEvents];
        #endif
    }
}

- (void)subscribeToAccelerometerEvents:(id<PVCaptureManagerGyroDelegate>) delegate forDevice:(NSDictionary*)device
{
    NSMutableArray *acclDelegates = [_delegates objectForKey:@"accl"];
    if (acclDelegates == nil)
    {
        acclDelegates = [NSMutableArray array];
        [_delegates setObject:acclDelegates forKey:@"accl"];
    }
    
    if (self.appType == PVApplicationTypeClient) {
        
        if (![acclDelegates containsObject:delegate])
            [acclDelegates addObject:delegate];
        
        [self supscribeWithEvent:@"accl" andDevice:device];
    } else {
        #if TARGET_OS_IPHONE
        [self.gyroCapture startAccelerometerEvents];
        #endif
    }
}

- (void)subscribeToMotionEvents:(id<PVCaptureManagerGyroDelegate>) delegate forDevice:(NSDictionary*)device
{
    NSMutableArray *motionDelegates = [_delegates objectForKey:@"motion"];
    if (motionDelegates == nil)
    {
        motionDelegates = [NSMutableArray array];
        [_delegates setObject:motionDelegates forKey:@"motion"];
    }
    
    if (self.appType == PVApplicationTypeClient) {
        
        if (![motionDelegates containsObject:delegate])
            [motionDelegates addObject:delegate];
        
        [self supscribeWithEvent:@"motion" andDevice:device];
    } else {
        
        if (![motionDelegates containsObject:device])
            [motionDelegates addObject:device];
        
        #if TARGET_OS_IPHONE
        [self.gyroCapture startMotionEvents];
        #endif
    }
}

- (void)subscribeToTouchEvents:(id<PVCaptureManagerTouchDelegate>) delegate forDevice:(NSDictionary*)device
{
    NSMutableArray *touchDelegates = [_delegates objectForKey:@"touch"];
    if (touchDelegates == nil)
    {
        touchDelegates = [NSMutableArray array];
        [_delegates setObject:touchDelegates forKey:@"touch"];
    }
    
    if (self.appType == PVApplicationTypeClient) {
        
        if (![touchDelegates containsObject:delegate])
            [touchDelegates addObject:delegate];
        
        [self supscribeWithEvent:@"touch" andDevice:device];
    } else {
        [self.touchCapture startTouchEvents];
    }
}

@end
