//
//  PVRootViewController.m
//  povemdct
//
//  Created by Roman Filippov on 24.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVRootViewController.h"

@interface PVRootViewController ()

@property (nonatomic, assign) UIViewController *rootViewController;
@property (nonatomic, assign) UIViewController *prevViewController;

@property (nonatomic, retain) NSMutableArray *viewControllers;

@end

@implementation PVRootViewController

- (id)initWithRootViewController:(UIViewController*)rootViewController
{
    self = [super init];
    if (self) {
        self.viewControllers = [NSMutableArray array];
        [self.viewControllers addObject:rootViewController];
        self.rootViewController = rootViewController;
        [self addChildViewController:rootViewController];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.rootViewController == nil)
        self.rootViewController = [self.viewControllers objectAtIndex:0];
    
    [self.view addSubview:self.rootViewController.view];
}

- (void)pushViewController:(UIViewController*)viewController animated:(BOOL)animated
{
    CGRect rect = self.view.bounds;
    self.prevViewController = self.rootViewController;
    self.rootViewController = viewController;
    [self.viewControllers addObject:viewController];
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    viewController.view.frame = CGRectMake(rect.size.width, 0, rect.size.width, rect.size.height);
    
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.prevViewController.view.frame = CGRectMake(-rect.size.width, 0, rect.size.width, rect.size.height);
            self.rootViewController.view.frame = rect;
        }completion:^(BOOL finished){
           
            [self.prevViewController removeFromParentViewController];
            [self.viewControllers removeObject:self.prevViewController];
        }];
    } else {
        self.rootViewController.view.frame = rect;
        [self.prevViewController removeFromParentViewController];
        [self.viewControllers removeObject:self.prevViewController];
    }
    
}

- (void)popViewControllerAnimated:(BOOL)animated
{
    if ([self.viewControllers count]<2)
        return;
    
    CGRect rect = self.view.bounds;
    self.prevViewController = self.rootViewController;
    self.rootViewController = [self.viewControllers objectAtIndex:1];
    [self.viewControllers addObject:self.rootViewController];
    [self addChildViewController:self.rootViewController];
    [self.view addSubview:self.rootViewController.view];
    self.rootViewController.view.frame = CGRectMake(rect.size.width, 0, rect.size.width, rect.size.height);
    
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.prevViewController.view.frame = CGRectMake(-rect.size.width, 0, rect.size.width, rect.size.height);
            self.rootViewController.view.frame = rect;
        }completion:^(BOOL finished){
            
            [self.prevViewController removeFromParentViewController];
            [self.viewControllers removeObject:self.prevViewController];
        }];
    } else {
        self.rootViewController.view.frame = rect;
        [self.prevViewController removeFromParentViewController];
        [self.viewControllers removeObject:self.prevViewController];
    }
}

- (void)layoutSubviews
{
    self.rootViewController.view.frame = self.view.bounds;
}

- (void)dealloc
{
    self.viewControllers = nil;
    [super dealloc];
}

@end
