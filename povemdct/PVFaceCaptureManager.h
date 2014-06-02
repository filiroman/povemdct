//
//  MainViewController.h
//  povemdct
//
//  Created by Roman Filippov on 11.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//


@interface PVFaceCaptureManager : NSObject

- (void)startCaptureSession;
- (void)stopCaptureSession;

- (NSString*)deviceCapabilities;

@end
