//
//  PVAttitude.m
//  povemdct
//
//  Created by Roman Filippov on 10.05.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "PVAttitude.h"

@implementation PVAttitude

- (id)initWithRoll:(double)roll pitch:(double)pitch yaw:(double)yaw rotationMatrix:(PVRotationMatrix)rmat quartenion:(PVQuaternion)quartenion
{
    if (self = [super init])
    {
        _roll = roll;
        _pitch = pitch;
        _yaw = yaw;
        _rotationMatrix = rmat;
        _quaternion = quartenion;
    }
    
    return self;
}

@end
