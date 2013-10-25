//
//  PVActivityView.m
//  povemdct
//
//  Created by Roman Filippov on 24.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVActivityView.h"

static PVActivityView *sharedActivityView;

@implementation PVActivityView

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (id) sharedActivityView
{
    if (sharedActivityView == nil)
        sharedActivityView = [[PVActivityView alloc] init];
    
    return sharedActivityView;
}

- (void)startAnimating
{
    self.hidden = NO;
    [super startAnimating];
}

- (void)stopAnimating
{
    self.hidden = YES;
    [super stopAnimating];
}

@end
