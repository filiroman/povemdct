//
//  PVMotionData.m
//  povemdct
//
//  Created by Roman Filippov on 08.05.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "PVMotionData.h"

@implementation PVMotionData

#if TARGET_OS_IPHONE
    + (id) motionDataWithData:(CMDeviceMotion*)gdata
    {
        PVMotionData *motionData = [[PVMotionData alloc] init];
        
        PVRotationRate rrate;
        rrate.x = gdata.rotationRate.x;
        rrate.y = gdata.rotationRate.y;
        rrate.z = gdata.rotationRate.z;
        
        PVAcceleration userAccl;
        userAccl.x = gdata.userAcceleration.x;
        userAccl.y = gdata.userAcceleration.y;
        userAccl.z = gdata.userAcceleration.z;
        
        PVAcceleration grav;
        grav.x = gdata.gravity.x;
        grav.y = gdata.gravity.y;
        grav.z = gdata.gravity.z;
        
        motionData.rotationRate = rrate;
        motionData.userAcceleration = userAccl;
        motionData.gravity = grav;
        
        return [motionData autorelease];
    }
#endif

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if( self )
    {
        PVAcceleration accl;
        NSData *rdata = [aDecoder decodeObjectForKey:@"userAcceleration"];
        [rdata getBytes:&accl length:sizeof(accl)];
        self.userAcceleration = accl;
        
        PVAcceleration gravity;
        NSData *gdata = [aDecoder decodeObjectForKey:@"gravity"];
        [gdata getBytes:&gravity length:sizeof(gravity)];
        self.gravity = gravity;
        
        PVRotationRate rrate;
        NSData *rrdata = [aDecoder decodeObjectForKey:@"rotationRate"];
        [rrdata getBytes:&rrate length:sizeof(rrate)];
        self.rotationRate = rrate;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    NSData *uadata = [NSData dataWithBytes:&_userAcceleration length:sizeof(_userAcceleration)];
    [encoder encodeObject:uadata forKey:@"userAcceleration"];
    
    NSData *gdata = [NSData dataWithBytes:&_gravity length:sizeof(_gravity)];
    [encoder encodeObject:gdata forKey:@"gravity"];
    
    
    NSData *rdata = [NSData dataWithBytes:&_rotationRate length:sizeof(_rotationRate)];
    [encoder encodeObject:rdata forKey:@"rotationRate"];
}


@end
