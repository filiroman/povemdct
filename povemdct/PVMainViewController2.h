//
//  PVMainViewController.h
//  povemdct
//
//  Created by Roman Filippov on 27.09.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <opencv2/highgui/cap_ios.h>

@interface PVMainViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    NSString *_qualityPreset;
}

// Current frames per second
@property (nonatomic, readonly) float fps;

@property (nonatomic, assign) BOOL showDebugInfo;

// AVFoundation components
@property (nonatomic, readonly) AVCaptureSession *captureSession;
@property (nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (nonatomic, readonly) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;


// -1: default, 0: back camera, 1: front camera
@property (nonatomic, assign) int camera;

// These should only be modified in the initializer
@property (nonatomic, assign) NSString * const qualityPreset;
@property (nonatomic, assign) BOOL captureGrayscale;

@end
