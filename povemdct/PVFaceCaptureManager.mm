//
//  PVMainViewController.m
//  povemdct
//
//  Created by Roman Filippov on 11.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVFaceCaptureManager.h"
#import "PVCameraCaptureManager.h"
#import "PVCaptureManager.h"

// Name of face cascade resource file without xml extension
NSString * const kFaceCascadeFilename = @"haarcascade_frontalface_alt2";

// Options for cv::CascadeClassifier::detectMultiScale
const int kHaarOptions =  CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_DO_ROUGH_SEARCH;

@interface PVFaceCaptureManager ()

@property (retain, nonatomic) PVCaptureManager *captureManager;
@property (retain, nonatomic) PVCameraCaptureManager *cameraCaptureManager;

@end

@implementation PVFaceCaptureManager
{
    cv::CascadeClassifier _faceCascade;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        self.cameraCaptureManager = [PVCameraCaptureManager sharedManager];
        self.cameraCaptureManager.delegate = (id)self;
        self.cameraCaptureManager.captureGrayscale = YES;
        self.cameraCaptureManager.qualityPreset = AVCaptureSessionPresetMedium;
        
        NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:kFaceCascadeFilename ofType:@"xml"];
        
        
        
        if (!_faceCascade.load([faceCascadePath UTF8String])) {
            NSLog(@"Could not load face cascade: %@", faceCascadePath);
        }
        
        //self.captureManager = [PVCaptureManager sharedManager];

    }
    return self;
}

- (void)dealloc
{
    self.cameraCaptureManager = nil;
    self.captureManager = nil;
    
    [super dealloc];
}


- (void)startCaptureSession
{
    if (self.captureManager == nil)
        self.captureManager = [PVCaptureManager sharedManager];
    
    if (self.cameraCaptureManager.captureSession == nil)
        [self.cameraCaptureManager startCaptureEvents];
    
    if (!self.cameraCaptureManager.captureSession.running)
        [self.cameraCaptureManager.captureSession startRunning];
}

- (void)stopCaptureSession
{
    if (self.cameraCaptureManager.captureSession.running) {
        [self.cameraCaptureManager.captureSession stopRunning];
        [self.cameraCaptureManager stopCaptureEvents];
    }
}


// MARK: VideoCaptureViewController overrides

- (void)cameraCaptureManager:(PVCameraCaptureManager*)manager processedFrame:(cv::Mat &)frame withVideoTect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)orientation;
{
    // Shrink video frame to 320X240
    cv::resize(frame, frame, cv::Size(), 0.5f, 0.5f, CV_INTER_LINEAR);
    rect.size.width /= 2.0f;
    rect.size.height /= 2.0f;
    
    // Rotate video frame by 90deg to portrait by combining a transpose and a flip
    // Note that AVCaptureVideoDataOutput connection does NOT support hardware-accelerated
    // rotation and mirroring via videoOrientation and setVideoMirrored properties so we
    // need to do the rotation in software here.
    cv::transpose(frame, frame);
    CGFloat temp = rect.size.width;
    rect.size.width = rect.size.height;
    rect.size.height = temp;
    
    if (orientation == AVCaptureVideoOrientationLandscapeRight)
    {
        // flip around y axis for back camera
        cv::flip(frame, frame, 1);
    }
    else {
        // Front camera output needs to be mirrored to match preview layer so no flip is required here
    }
    
    orientation = AVCaptureVideoOrientationPortrait;
    
    // Detect faces
    std::vector<cv::Rect> faces;
    
    _faceCascade.detectMultiScale(frame, faces, 1.1, 2, kHaarOptions, cv::Size(60, 60));
    
    CGAffineTransform t = [self.cameraCaptureManager affineTransformForVideoFrame:rect orientation:orientation];
    
    for (int i = 0; i < faces.size(); i++) {
        
        CGRect faceRect;
        faceRect.origin.x = faces[i].x;
        faceRect.origin.y = faces[i].y;
        faceRect.size.width = faces[i].width;
        faceRect.size.height = faces[i].height;
        
        faceRect = CGRectApplyAffineTransform(faceRect, t);
        
        [self.captureManager sendFaceCaptureWithRect:faceRect];
    }
}

- (NSString*)deviceCapabilities
{
    return @"face_capture";
}


@end
