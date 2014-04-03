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
//#import "PVTouchCaptureManager.h"
#import "PVGyroCaptureManager.h"

static PVCaptureManager *sharedManager;

@interface PVCaptureManager ()

@property (retain, nonatomic) PVNetworkManager *networkManager;
@property (retain, nonatomic) NSMutableArray *cameraDelegates;
@property (retain, nonatomic) NSMutableArray *gyroDelegates;
@property (retain, nonatomic) NSMutableArray *touchDelegates;
@property (retain, nonatomic) NSMutableArray *delegates;

@property (retain, nonatomic) PVGyroCaptureManager *gyroCapture;
//@property (retain, nonatomic) PVTouchCaptureManager *touchCapture;

@end

@implementation PVCaptureManager

- (id)init
{
    if (self = [super init])
    {
        
        self.cameraDelegates = [NSMutableArray nonRetainingArray];
        self.gyroDelegates = [NSMutableArray nonRetainingArray];
        self.delegates = [NSMutableArray nonRetainingArray];
        self.touchDelegates = [NSMutableArray nonRetainingArray];
        
        self.networkManager = [PVNetworkManager sharedManager];
        [self.networkManager start:(id)self];
        
        self.gyroCapture = [[[PVGyroCaptureManager alloc] init] autorelease];
        //self.touchCapture = [[[PVTouchCaptureManager alloc] init] autorelease];
    }
    return self;
}

- (void)dealloc
{
    self.cameraDelegates = nil;
    self.gyroDelegates = nil;
    self.delegates = nil;
    self.touchDelegates = nil;
    
    self.gyroCapture = nil;
    //self.touchCapture = nil;
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
    [self.networkManager sendData:sendingData];
}

- (void)sendWindowSize:(CGSize)wsize
{
    NSDictionary *sdata = @{@"width" : [NSNumber numberWithFloat:wsize.width], @"height" : [NSNumber numberWithFloat:wsize.height]};
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:sdata];
    [self.networkManager sendData:sendingData withType:WINSIZE_DATA];
}

- (void)sendData:(NSData *)data withType:(int)dataType
{
    [self.networkManager sendData:data withType:dataType];
}

- (void)sendTouchPoint:(CGPoint)touchPoint
{
    NSDictionary *sdata = @{@"x": [NSNumber numberWithFloat:touchPoint.x], @"y": [NSNumber numberWithFloat:touchPoint.y]};
    
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:sdata];
    [self.networkManager sendData:sendingData withType:TOUCH_DATA];
}

- (void)sendGyroData:(CMGyroData*)gdata
{
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:gdata];
    [self.networkManager sendData:sendingData withType:GYRO_DATA];
}

- (void)sendAccelerometerData:(CMAccelerometerData*)accdata
{
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:accdata];
    [self.networkManager sendData:sendingData withType:ACCL_DATA];
}

- (void)sendMotionData:(CMDeviceMotion*)mdata
{
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:mdata];
    [self.networkManager sendData:sendingData withType:MOTION_DATA];
}

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
            
            if ([event isEqualToString:@"camera"])
            {
                [self subscribeToCameraEvents:(id)self];
            } else if ([event isEqualToString:@"motion"])
            {
                [self subscribeToGyroEvents:(id)self];
            } else if ([event isEqualToString:@"touch"])
            {
                [self subscribeToTouchEvents:(id)self];
            }
        }
    }
    else if (dataType == CAPTURE_DATA) {
        
        NSDictionary *rdict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
        CGRect captureRect = CGRectMake([[rdict objectForKey:@"x"] floatValue], [[rdict objectForKey:@"y"] floatValue], [[rdict objectForKey:@"width"] floatValue], [[rdict objectForKey:@"height"] floatValue]);
        
        for (id<PVCaptureManagerCameraDelegate> delegate in _cameraDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didRecievedFaceCaptureAtRect:)])
                [delegate PVCaptureManager:self didRecievedFaceCaptureAtRect:captureRect];
        }
        
    } else if (dataType == WINSIZE_DATA)
    {
        
        NSDictionary *rdict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
        CGSize winSize = CGSizeMake([[rdict objectForKey:@"width"] floatValue], [[rdict objectForKey:@"height"] floatValue]);
        
        for (id<PVCaptureManagerDelegate> delegate in _delegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didRecievedWindowSize:)])
                [delegate PVCaptureManager:self didRecievedWindowSize:winSize];
        }
        
    } else if (dataType == GYRO_DATA)
    {
        CMGyroData *gdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        for (id<PVCaptureManagerGyroDelegate> delegate in _gyroDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didRecievedGyroscopeData:)])
                [delegate PVCaptureManager:self didRecievedGyroscopeData:gdata];
        }
        
    } else if (dataType == ACCL_DATA)
    {
        CMAccelerometerData *accdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        for (id<PVCaptureManagerGyroDelegate> delegate in _gyroDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didRecievedAccelerometerData:)])
                [delegate PVCaptureManager:self didRecievedAccelerometerData:accdata];
        }
    } else if (dataType == MOTION_DATA)
    {
        CMDeviceMotion *mdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        for (id<PVCaptureManagerGyroDelegate> delegate in _gyroDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didRecievedMotionData:)])
                [delegate PVCaptureManager:self didRecievedMotionData:mdata];
        }
    } else if (dataType == TOUCH_DATA)
    {
        NSDictionary *tdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        CGPoint point = CGPointMake([[tdata objectForKey:@"x"] floatValue], [[tdata objectForKey:@"y"] floatValue]);
        
        for (id<PVCaptureManagerTouchDelegate> delegate in _touchDelegates) {
            if ([delegate respondsToSelector:@selector(PVCaptureManager:didReceivedTouchAtPosition:)])
                [delegate PVCaptureManager:self didReceivedTouchAtPosition:point];
        }
    } else if (dataType == TIME_DATA)
    {
            NSNumber *timeData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            double diff = [[NSDate date] timeIntervalSince1970] - [timeData doubleValue];
        
        NSString *str = [NSString stringWithFormat:@"%f\n", diff*1000];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"file.txt"];
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
        
        NSLog(@"%f", diff*1000);
    }
    
}

@end


@implementation PVCaptureManager (SubscribeMethods)

- (void)subscribeToAllEvents:(id<PVCaptureManagerCameraDelegate, PVCaptureManagerGyroDelegate>) delegate
{
    [self subscribeToCameraEvents:delegate];
    [self subscribeToGyroEvents:delegate];
}

- (void)subscribeToCameraEvents:(id<PVCaptureManagerCameraDelegate>) delegate
{
    if (![self.cameraDelegates containsObject:delegate])
        [self.cameraDelegates addObject:delegate];
    
    if (self.appType == PVApplicationTypeClient) {
    
        NSMutableDictionary *commands = [NSMutableDictionary dictionary];
        [commands setObject:@"subscribe" forKey:@"type"];
        [commands setObject:@"camera" forKey:@"event"];
        
        NSData *hdata = [NSKeyedArchiver archivedDataWithRootObject:commands];
        
        assert(hdata != nil);
        
        [self.networkManager sendData:hdata withType:CONTROL_DATA];
    }
}

- (void)subscribeToGyroEvents:(id<PVCaptureManagerGyroDelegate>) delegate
{
    if (![self.gyroDelegates containsObject:delegate])
        [self.gyroDelegates addObject:delegate];
    
    if (self.appType == PVApplicationTypeClient) {
        
        NSMutableDictionary *commands = [NSMutableDictionary dictionary];
        [commands setObject:@"subscribe" forKey:@"type"];
        [commands setObject:@"motion" forKey:@"event"];
        
        NSData *hdata = [NSKeyedArchiver archivedDataWithRootObject:commands];
        
        assert(hdata != nil);
        
        [self.networkManager sendData:hdata withType:CONTROL_DATA];
    } else {
        
        [self.gyroCapture startMotionEvents];
    }
}

- (void)subscribeToTouchEvents:(id<PVCaptureManagerTouchDelegate>) delegate
{
    if (![self.touchDelegates containsObject:delegate])
        [self.touchDelegates addObject:delegate];
    
    if (self.appType == PVApplicationTypeClient) {
        
        NSMutableDictionary *commands = [NSMutableDictionary dictionary];
        [commands setObject:@"subscribe" forKey:@"type"];
        [commands setObject:@"touch" forKey:@"type"];
        
        NSData *hdata = [NSKeyedArchiver archivedDataWithRootObject:commands];
        
        assert(hdata != nil);
        
        [self.networkManager sendData:hdata withType:CONTROL_DATA];
    } else {
        //[self.touchCapture startTouchEvents:];
    }
}

@end
