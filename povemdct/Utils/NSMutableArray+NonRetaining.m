//
//  NSMutableArray+NonRetaining.m
//  povemdct
//
//  Created by Roman Filippov on 10.12.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "NSMutableArray+NonRetaining.h"

@implementation NSMutableArray (NonRetaining)

+ (id) nonRetainingArray
{
    NSMutableArray *arr = (NSMutableArray *)CFArrayCreateMutable(nil, 0, nil);
    
    return [arr autorelease];
}

@end
