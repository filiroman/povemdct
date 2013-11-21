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

static PVCaptureManager *sharedManager;

@interface PVCaptureManager ()

@property (retain, nonatomic) PVNetworkManager *networkManager;

@end

@implementation PVCaptureManager

- (id)init
{
    if (self = [super init])
    {
        self.networkManager = [PVNetworkManager sharedManager];
        [self.networkManager start:(id)self];
    }
    return self;
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

#pragma mark network methods

- (void)PVNetworkManager:(PVNetworkManager*)manager didReceivedData:(NSData*)data fromDevice:(NSDictionary*)device withType:(long)dataType
{
    if (dataType == CAPTURE_DATA) {
        
        NSDictionary *rdict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
        CGRect captureRect = CGRectMake([[rdict objectForKey:@"x"] floatValue], [[rdict objectForKey:@"y"] floatValue], [[rdict objectForKey:@"width"] floatValue], [[rdict objectForKey:@"height"] floatValue]);
        if ([self.delegate respondsToSelector:@selector(PVCaptureManager:didRecievedFaceCaptureAtRect:)])
            [self.delegate PVCaptureManager:self didRecievedFaceCaptureAtRect:captureRect];
    } else if (dataType == WINSIZE_DATA)
    {
        
        NSDictionary *rdict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
        CGSize winSize = CGSizeMake([[rdict objectForKey:@"width"] floatValue], [[rdict objectForKey:@"height"] floatValue]);
        if ([self.delegate respondsToSelector:@selector(PVCaptureManager:didRecievedWindowSize:)])
            [self.delegate PVCaptureManager:self didRecievedWindowSize:winSize];
    } else if (dataType == GYRO_DATA)
    {
        CMGyroData *gdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([self.delegate respondsToSelector:@selector(PVCaptureManager:didRecievedGyroscopeData:)])
            [self.delegate PVCaptureManager:self didRecievedGyroscopeData:gdata];
    } else if (dataType == ACCL_DATA)
    {
        CMAccelerometerData *accdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([self.delegate respondsToSelector:@selector(PVCaptureManager:didRecievedAccelerometerData:)])
            [self.delegate PVCaptureManager:self didRecievedAccelerometerData:accdata];
    }
}


@end
