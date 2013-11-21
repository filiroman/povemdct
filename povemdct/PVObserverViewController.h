//
//  UIMainViewController.h
//  WirelessPlayer
//
//  Created by Roman Filippov on 10.06.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
    PVApplicationTypeClient = 0,
    PVApplicationTypeServer = 1
} PVApplicationType;

@interface PVObserverViewController : UIViewController

- (id)initViewController;

@end
