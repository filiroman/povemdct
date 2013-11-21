//
//  PVGyroCaptureViewController.m
//  povemdct
//
//  Created by Roman Filippov on 21.11.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import "PVGyroCaptureViewController.h"

#define SEGMENTED_GYRO 0
#define SEGMENTED_ACCL 1

#define UPDATE_SPEED 1.0f / 15.0f

@interface PVGyroCaptureViewController ()

@property (nonatomic, retain) CMMotionManager *motionManager;

@property (nonatomic, retain) UILabel *gyro_xaxis;
@property (nonatomic, retain) UILabel *gyro_yaxis;
@property (nonatomic, retain) UILabel *gyro_zaxis;

@property (nonatomic, retain) UISegmentedControl *segmentedControl;

@end

@implementation PVGyroCaptureViewController

- (id)initViewController
{
    self = [super init];
    if (self) {
        
        self.motionManager = [[[CMMotionManager alloc] init] autorelease];
    }
    return self;
}

- (void)setupAccelerometer
{
    if ([self.motionManager isGyroActive])
        [self.motionManager stopGyroUpdates];
    
    //accelerometer
    if([self.motionManager isAccelerometerAvailable])
    {
        /* Start the accelerometer if it is not active already */
        if([self.motionManager isAccelerometerActive] == NO)
        {
            /* Update us 2 times a second */
            [self.motionManager setAccelerometerUpdateInterval:UPDATE_SPEED];
            
            /* Add on a handler block object */
            
            /* Receive the accelerometer data on this block */
            
            [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                
                NSString *x = [[NSString alloc] initWithFormat:@"x:%.02f", accelerometerData.acceleration.x];
                self.gyro_xaxis.text = x;
                
                NSString *y = [[NSString alloc] initWithFormat:@"y:%.02f", accelerometerData.acceleration.y];
                self.gyro_yaxis.text = y;
                
                NSString *z = [[NSString alloc] initWithFormat:@"z:%.02f", accelerometerData.acceleration.z];
                self.gyro_zaxis.text = z;
               
                
            }];
            
        }
    }
    else
    {
        NSLog(@"Accelerometer not Available!");
    }
}

- (void)setupGyroscope
{
    
    if ([self.motionManager isAccelerometerActive])
        [self.motionManager stopAccelerometerUpdates];
    
    //Gyroscope
    if([self.motionManager isGyroAvailable])
    {
        /* Start the gyroscope if it is not active already */
        if([self.motionManager isGyroActive] == NO)
        {
            /* Update us 2 times a second */
            [self.motionManager setGyroUpdateInterval:UPDATE_SPEED];
            
            /* Add on a handler block object */
            
            /* Receive the gyroscope data on this block */
            [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
                                            withHandler:^(CMGyroData *gyroData, NSError *error)
             {
                 NSString *x = [[NSString alloc] initWithFormat:@"x:%.02f",gyroData.rotationRate.x];
                 self.gyro_xaxis.text = x;
                 
                 NSString *y = [[NSString alloc] initWithFormat:@"y:%.02f",gyroData.rotationRate.y];
                 self.gyro_yaxis.text = y;
                 
                 NSString *z = [[NSString alloc] initWithFormat:@"z:%.02f",gyroData.rotationRate.z];
                 self.gyro_zaxis.text = z;
             }];
        }
    }
    else
    {
        NSLog(@"Gyroscope not Available!");
    }
}

- (void)dealloc
{
    self.motionManager = nil;
    
    [self.segmentedControl removeFromSuperview];
    self.segmentedControl = nil;
    
    [self.gyro_xaxis removeFromSuperview];
    self.gyro_xaxis = nil;
    
    [self.gyro_yaxis removeFromSuperview];
    self.gyro_yaxis = nil;
    
    [self.gyro_zaxis removeFromSuperview];
    self.gyro_zaxis = nil;
    
    [super dealloc];
}

- (void)layoutSubviews
{
    CGRect rect = [UIScreen mainScreen].bounds;
    
    _segmentedControl.frame = CGRectMake(rect.size.width/2 - 100, rect.size.height/3, 200, 60);
    
    _gyro_xaxis.frame = CGRectMake(20, rect.size.height/3 + 80, 60, 30);
    _gyro_yaxis.frame = CGRectMake(rect.size.width/2 - 30, rect.size.height/3 + 80, 60, 30);
    _gyro_zaxis.frame = CGRectMake(rect.size.width - 60 - 20, rect.size.height/3 + 80, 60, 30);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Gyro", @"Accelerometer", nil]];
    
    [_segmentedControl addTarget:self
                         action:@selector(segmentedControlISelectedIndexChanged:)
               forControlEvents:UIControlEventValueChanged];
    
    [self.segmentedControl setSelectedSegmentIndex:SEGMENTED_GYRO];
    
    self.gyro_xaxis = [[[UILabel alloc] init] autorelease];
    self.gyro_yaxis = [[[UILabel alloc] init] autorelease];
    self.gyro_zaxis = [[[UILabel alloc] init] autorelease];
    
    [self.gyro_xaxis setTextAlignment:NSTextAlignmentCenter];
    [self.gyro_yaxis setTextAlignment:NSTextAlignmentCenter];
    [self.gyro_zaxis setTextAlignment:NSTextAlignmentCenter];

    [self.view addSubview:_gyro_xaxis];
    [self.view addSubview:_gyro_yaxis];
    [self.view addSubview:_gyro_zaxis];
    [self.view addSubview:_segmentedControl];

    [self layoutSubviews];
}

- (void)segmentedControlISelectedIndexChanged:(UISegmentedControl*)sender
{
    if (sender.selectedSegmentIndex == SEGMENTED_GYRO)
    {
        [self setupGyroscope];
    } else {
        
        [self setupAccelerometer];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
