//
//  PVRootViewController.h
//  povemdct
//
//  Created by Roman Filippov on 24.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PVRootViewController : UIViewController

- (id)initWithRootViewController:(UIViewController*)rootViewController;
- (void)pushViewController:(UIViewController*)viewController animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;

@end
