//
//  PVManager.m
//  povemdct
//
//  Created by Roman Filippov on 13.12.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVManager.h"
#import "PVNetworkManager.h"
#import "PVActivityView.h"
#import "PVCaptureManager.h"

static PVManager *sharedManager;

@interface PVManager ()

//@property (retain, nonatomic) NSDictionary *choosenDevice;
@property (retain, nonatomic) NSMutableArray *devices;

@property (retain, nonatomic) PVNetworkManager *networkManager;
@property (assign, nonatomic) PVApplicationType applcationType;

@property (nonatomic, assign) id delegate;

@end

@implementation PVManager

- (id) init
{
    if (self = [super init])
    {
        self.devices = [[NSMutableArray alloc] init];
        self.networkManager = [PVNetworkManager sharedManager];
        self.captureManager = [PVCaptureManager sharedManager];
        [_networkManager start:(id)self];
    }
    return self;
}

- (void)dealloc
{
    self.devices = nil;
    self.networkManager = nil;
    self.captureManager = nil;
    [super dealloc];
}

+ (id) sharedManager
{
    if (sharedManager == nil)
        sharedManager = [[PVManager alloc] init];
    
    return sharedManager;
}

- (void) startClientSide:(id<PVManagerDelegate>)delegate
{
    _applcationType = PVApplicationTypeClient;
    _delegate = delegate;
    
    [self.networkManager setupSocketForApplicationType:_applcationType];
    self.captureManager = [PVCaptureManager sharedManager];
    self.captureManager.appType = _applcationType;
}

- (void) startServerSize:(id<PVManagerDelegate>)delegate
{
    _applcationType = PVApplicationTypeServer;
    _delegate = delegate;
    
    [self.networkManager setupSocketForApplicationType:PVApplicationTypeServer];
    self.captureManager = [PVCaptureManager sharedManager];
    self.captureManager.appType = _applcationType;
}


#pragma mark PVNetworkManager delegate

- (void)PVNetworkManager:(PVNetworkManager*)manager didFoundDevice:(NSDictionary*)device
{
    [self.networkManager connectWithDevice:device];
    
}

- (void)PVNetworkManager:(PVNetworkManager*)manager didConnectedToDevice:(NSDictionary*)device
{
    
    if (![_devices containsObject:device]) {
        
        [_devices addObject:device];
    }
    
    if (self.applcationType == PVApplicationTypeClient)
    {
        [self.delegate PVManagerDidEstablishedConnection:self];

    } else {

    }
}



@end
