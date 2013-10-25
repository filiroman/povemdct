//
//  NSData+NSValue.m
//  povemdct
//
//  Created by Roman Filippov on 25.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "NSData+NSValue.h"

@implementation NSData (NSValue)

/*+(NSData*) dataWithValue:(NSValue*)value
{
    NSUInteger size;
    const char* encoding = [value objCType];
    NSGetSizeAndAlignment(encoding, &size, NULL);
    
    void* ptr = malloc(size);
    [value getValue:ptr];
    NSData* data = [NSData dataWithBytes:ptr length:size];
    free(ptr);
    
    return data;
}*/

+ (NSData *)dataWithValue:(NSValue *)value {
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}

+ (NSValue *)valueWithData:(NSData *)data {
    return (NSValue *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
}

 

+(NSData*) dataWithNumber:(NSNumber*)number
{
    return [NSData dataWithValue:(NSValue*)number];
}

@end
