//
//  ViewController.h
//  FaceTracker
//
//  Created by Robin Summerhill on 9/22/11.
//  Copyright 2011 Aptogo Limited. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//
#import <AVFoundation/AVFoundation.h>
#import <opencv2/opencv.hpp>

@protocol PVCameraCaptureDelegate;

@interface PVCameraCaptureManager : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_captureDevice;
    AVCaptureVideoDataOutput *_videoOutput;
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
    
    int _camera;
    BOOL _captureGrayscale;
    
    // Fps calculation
    CMTimeValue _lastFrameTimestamp;
    float *_frameTimes;
    int _frameTimesIndex;
    int _framesToAverage;
    
    NSString * _qualityPreset;
    
    float _captureQueueFps;
    float _fps;
    
}

// Current frames per second
@property (nonatomic, readonly) float fps;

@property (nonatomic, assign) BOOL showDebugInfo;
@property (nonatomic, assign) BOOL torchOn;

// delegate
@property (nonatomic, assign) id<PVCameraCaptureDelegate> delegate;

// AVFoundation components
@property (nonatomic, readonly) AVCaptureSession *captureSession;
@property (nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (nonatomic, readonly) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;


// -1: default, 0: back camera, 1: front camera
@property (nonatomic, assign) int camera;

// These should only be modified in the initializer
@property (nonatomic, assign) NSString * qualityPreset;
@property (nonatomic, assign) BOOL captureGrayscale;

- (CGAffineTransform)affineTransformForVideoFrame:(CGRect)videoFrame orientation:(AVCaptureVideoOrientation)videoOrientation;
- (void)startCaptureEvents;
- (void)stopCaptureEvents;

+ (id)sharedManager;

@end

@protocol PVCameraCaptureDelegate <NSObject>

- (void)cameraCaptureManager:(PVCameraCaptureManager*)manager processedFrame:(cv::Mat &)frame withVideoTect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)orientation;

@end
