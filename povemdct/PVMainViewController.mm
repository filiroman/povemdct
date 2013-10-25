//
//  PVMainViewController.m
//  povemdct
//
//  Created by Roman Filippov on 11.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVMainViewController.h"
#import "PVCaptureManager.h"

// Name of face cascade resource file without xml extension
NSString * const kFaceCascadeFilename = @"haarcascade_frontalface_alt2";

// Options for cv::CascadeClassifier::detectMultiScale
const int kHaarOptions =  CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_DO_ROUGH_SEARCH;

@interface PVMainViewController ()
{
    cv::CascadeClassifier _faceCascade;
}

@property (retain, nonatomic) UIButton *switchButton;
@property (retain, nonatomic) UIButton *startButton;

@property (retain, nonatomic) PVCaptureManager *captureManager;

@end

@implementation PVMainViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.captureGrayscale = YES;
        self.qualityPreset = AVCaptureSessionPresetMedium;
        
        self.captureManager = [PVCaptureManager sharedManager];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Load the face Haar cascade from resources
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:kFaceCascadeFilename ofType:@"xml"];
    
    if (!_faceCascade.load([faceCascadePath UTF8String])) {
        NSLog(@"Could not load face cascade: %@", faceCascadePath);
    }
    
    self.switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.switchButton setTitle:@"Switch" forState:UIControlStateNormal];
    [self.switchButton addTarget:self action:@selector(switchPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.switchButton];
    
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton addTarget:self action:@selector(startPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startButton];
    
    [self layoutSubviews];
}

- (void)dealloc
{
    self.switchButton = nil;
    self.startButton = nil;
    
    [super dealloc];
}

- (void)layoutSubviews
{
    CGRect screen = self.view.bounds;
    self.startButton.frame = CGRectMake(screen.size.width/4 - 40, screen.size.height - 80, 80, 40);
    self.switchButton.frame = CGRectMake(screen.size.width/4*3 - 40, screen.size.height - 80, 80, 40);
    
}

- (void)startPressed
{
    if (self.captureSession.running)
    {
        [self.captureSession stopRunning];
        [self.videoPreviewLayer setHidden:YES];
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    }
    else
    {
        [self.captureSession startRunning];
        [self.videoPreviewLayer setHidden:NO];
        [self.startButton setTitle:@"Stop" forState:UIControlStateNormal];
    }
    
}


- (void) switchPressed
{
    if (self.camera == 1) {
        self.camera = 0;
    }
    else
    {
        self.camera = 1;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// MARK: VideoCaptureViewController overrides

- (void)processFrame:(cv::Mat &)mat videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)videOrientation
{
    // Shrink video frame to 320X240
    cv::resize(mat, mat, cv::Size(), 0.5f, 0.5f, CV_INTER_LINEAR);
    rect.size.width /= 2.0f;
    rect.size.height /= 2.0f;
    
    // Rotate video frame by 90deg to portrait by combining a transpose and a flip
    // Note that AVCaptureVideoDataOutput connection does NOT support hardware-accelerated
    // rotation and mirroring via videoOrientation and setVideoMirrored properties so we
    // need to do the rotation in software here.
    cv::transpose(mat, mat);
    CGFloat temp = rect.size.width;
    rect.size.width = rect.size.height;
    rect.size.height = temp;
    
    if (videOrientation == AVCaptureVideoOrientationLandscapeRight)
    {
        // flip around y axis for back camera
        cv::flip(mat, mat, 1);
    }
    else {
        // Front camera output needs to be mirrored to match preview layer so no flip is required here
    }
    
    videOrientation = AVCaptureVideoOrientationPortrait;
    
    // Detect faces
    std::vector<cv::Rect> faces;
    
    _faceCascade.detectMultiScale(mat, faces, 1.1, 2, kHaarOptions, cv::Size(60, 60));
    
    // Dispatch updating of face markers to main queue
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self displayFaces:faces
              forVideoRect:rect
          videoOrientation:videOrientation];
    });
}

// Update face markers given vector of face rectangles
- (void)displayFaces:(const std::vector<cv::Rect> &)faces
        forVideoRect:(CGRect)rect
    videoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    NSArray *sublayers = [NSArray arrayWithArray:[self.view.layer sublayers]];
    int sublayersCount = [sublayers count];
    int currentSublayer = 0;
    
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for (CALayer *layer in sublayers) {
        NSString *layerName = [layer name];
		if ([layerName isEqualToString:@"FaceLayer"])
			[layer setHidden:YES];
	}
    
    // Create transform to convert from vide frame coordinate space to view coordinate space
    CGAffineTransform t = [self affineTransformForVideoFrame:rect orientation:videoOrientation];
    
    for (int i = 0; i < faces.size(); i++) {
        
        CGRect faceRect;
        faceRect.origin.x = faces[i].x;
        faceRect.origin.y = faces[i].y;
        faceRect.size.width = faces[i].width;
        faceRect.size.height = faces[i].height;
        
        faceRect = CGRectApplyAffineTransform(faceRect, t);
        
        CALayer *featureLayer = nil;
        
        while (!featureLayer && (currentSublayer < sublayersCount)) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ([[currentLayer name] isEqualToString:@"FaceLayer"]) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
        
        if (!featureLayer) {
            // Create a new feature marker layer
			featureLayer = [[CALayer alloc] init];
            featureLayer.name = @"FaceLayer";
            featureLayer.borderColor = [[UIColor redColor] CGColor];
            featureLayer.borderWidth = 10.0f;
			[self.view.layer addSublayer:featureLayer];
			[featureLayer release];
		}
        
        featureLayer.frame = faceRect;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.captureManager sendFaceCaptureWithRect:faceRect];
        });
    }
    
    [CATransaction commit];
}


@end
