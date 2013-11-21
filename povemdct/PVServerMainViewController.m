//
//  PVServerMainViewController.m
//  povemdct
//
//  Created by Roman Filippov on 22.11.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVServerMainViewController.h"
#import "PVMainViewController.h"
#import "PVGyroCaptureViewController.h"

@interface PVServerMainViewController ()

@property (nonatomic, retain) UITabBarController *tabBar;

@end

@implementation PVServerMainViewController

- (id)initViewController
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.tabBar = [[[UITabBarController alloc] init] autorelease];
    
    PVMainViewController *mainVC = [[PVMainViewController alloc] init];
    PVGyroCaptureViewController *gyroVC = [[PVGyroCaptureViewController alloc] initViewController];
    
    self.tabBar.viewControllers = [NSArray arrayWithObjects:mainVC, gyroVC, nil];
    
    [self.view addSubview:self.tabBar.view];
}

- (void)dealloc
{
    self.tabBar = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
