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

- (void)sendFaceCaptureWithRect:(CGRect)captureRect
{
    NSDictionary *sdata = @{@"x": [NSNumber numberWithFloat:captureRect.origin.x], @"y" : [NSNumber numberWithFloat:captureRect.origin.y], @"width" : [NSNumber numberWithFloat:captureRect.size.width], @"height" : [NSNumber numberWithFloat:captureRect.size.height]};
    NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:sdata];
    [self.networkManager sendData:sendingData];
}

- (void)PVNetworkManager:(PVNetworkManager*)manager didReceivedData:(NSData*)data fromDevice:(NSDictionary*)device
{
    NSDictionary *rdict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    CGRect captureRect = CGRectMake([[rdict objectForKey:@"x"] floatValue], [[rdict objectForKey:@"y"] floatValue], [[rdict objectForKey:@"width"] floatValue], [[rdict objectForKey:@"height"] floatValue]);
    if ([self.delegate respondsToSelector:@selector(PVCaptureManager:didRecievedFaceCaptureAtRect:)])
        [self.delegate PVCaptureManager:self didRecievedFaceCaptureAtRect:captureRect];
}


@end
