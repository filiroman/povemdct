//
//  PVAccelerometerData.m
//  povemdct
//
//  Created by Roman Filippov on 08.05.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "PVAccelerometerData.h"

@implementation PVAccelerometerData

#if TARGET_OS_IPHONE
+ (id) accelerometerDataWithData:(CMAccelerometerData*)gdata;
{
    PVAccelerometerData *accelerometerData = [[PVAccelerometerData alloc] init];
    
    PVAcceleration accl;
    accl.x = gdata.acceleration.x;
    accl.y = gdata.acceleration.y;
    accl.z = gdata.acceleration.z;
    
    accelerometerData.acceleration = accl;
    
    return [accelerometerData autorelease];
}
#endif

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if( self )
    {
        PVAcceleration accl;
        NSData *rdata = [aDecoder decodeObjectForKey:@"acceleration"];
        [rdata getBytes:&accl length:sizeof(accl)];
        self.acceleration = accl;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    NSData *rdata = [NSData dataWithBytes:&_acceleration length:sizeof(_acceleration)];
    [encoder encodeObject:rdata forKey:@"acceleration"];
}

@end
