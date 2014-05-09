//
//  PVGyroData.m
//  povemdct
//
//  Created by Roman Filippov on 06.05.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "PVGyroData.h"

@implementation PVGyroData

#if TARGET_OS_IPHONE
+ (id) gyroDataWithData:(CMGyroData*)gdata
{
    PVGyroData *gyroscopeData = [[PVGyroData alloc] init];
    
    PVRotationRate rrate;
    rrate.x = gdata.rotationRate.x;
    rrate.y = gdata.rotationRate.y;
    rrate.z = gdata.rotationRate.z;
    
    gyroscopeData.rotationRate = rrate;
    
    return [gyroscopeData autorelease];
}
#endif

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if( self )
    {
        PVRotationRate rrate;
        NSData *rdata = [aDecoder decodeObjectForKey:@"rotationRate"];
        [rdata getBytes:&rrate length:sizeof(rrate)];
        self.rotationRate = rrate;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    NSData *rdata = [NSData dataWithBytes:&_rotationRate length:sizeof(_rotationRate)];
    [encoder encodeObject:rdata forKey:@"rotationRate"];
}

@end
