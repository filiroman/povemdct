//
//  PVTouchCaptureManager.h
//  povemdct
//
//  Created by Roman Filippov on 16.12.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PVTouchCaptureManager : NSObject

- (void)startTouchEvents;
- (void)stopTouchEvents;

+ (id)sharedManager;
- (NSString*)deviceCapabilities;

@end
