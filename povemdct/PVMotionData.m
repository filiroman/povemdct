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

- (id) initWithRotationRate:(PVRotationRate)rrate userAcceleration:(PVAcceleration)uaccl gravity:(PVAcceleration)gravity attitude:(PVAttitude*)attitude magneticField:(PVCalibratedMagneticField)mfield
{
    if (self = [super init])
    {
        _rotationRate = rrate;
        _userAcceleration = uaccl;
        _gravity = gravity;
        _attitude = [attitude retain];
        _magneticField = mfield;
    }
    return self;
}

+ (id) motionDataWithData:(CMDeviceMotion*)gdata
{
    CMRotationRate crrate = gdata.rotationRate;
    PVRotationRate rrate = *(PVRotationRate*) &crrate;
    /*rrate.x = gdata.rotationRate.x;
    rrate.y = gdata.rotationRate.y;
    rrate.z = gdata.rotationRate.z;*/
    
    CMAcceleration uaccl = gdata.userAcceleration;
    PVAcceleration userAccl = *(PVAcceleration*) &uaccl;
    /*userAccl.x = gdata.userAcceleration.x;
    userAccl.y = gdata.userAcceleration.y;
    userAccl.z = gdata.userAcceleration.z;*/
    
    CMAcceleration gravAccl = gdata.gravity;
    PVAcceleration grav = *(PVAcceleration*) &gravAccl;
    /*grav.x = gdata.gravity.x;
    grav.y = gdata.gravity.y;
    grav.z = gdata.gravity.z;*/
    
    PVCalibratedMagneticField field;
    
    PVMotionData *motionData = [[PVMotionData alloc] initWithRotationRate:rrate userAcceleration:userAccl gravity:grav attitude:nil magneticField:field];
    
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
        _userAcceleration = accl;
        
        PVAcceleration gravity;
        NSData *gdata = [aDecoder decodeObjectForKey:@"gravity"];
        [gdata getBytes:&gravity length:sizeof(gravity)];
        _gravity = gravity;
        
        PVRotationRate rrate;
        NSData *rrdata = [aDecoder decodeObjectForKey:@"rotationRate"];
        [rrdata getBytes:&rrate length:sizeof(rrate)];
        _rotationRate = rrate;
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
