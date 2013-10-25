//
//  NSData+NSValue.h
//  povemdct
//
//  Created by Roman Filippov on 25.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (NSValue)

+ (NSData*) dataWithValue:(NSValue*)value;
+ (NSData*) dataWithNumber:(NSNumber*)number;
+ (NSValue *)valueWithData:(NSData *)data;

@end
