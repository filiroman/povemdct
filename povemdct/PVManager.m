//
//  PVManager.m
//  povemdct
//
//  Created by Roman Filippov on 13.12.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVManager.h"
#import "PVNetworkManager.h"
#import "PVCaptureManager.h"

static PVManager *sharedManager;

@interface PVManager ()

@property (retain, nonatomic) NSMutableArray *foundDevices;
@property (retain, nonatomic) NSMutableArray *connectedDevices;

@property (retain, nonatomic) PVNetworkManager *networkManager;
@property (assign, nonatomic) PVApplicationType applcationType;

@property (nonatomic, assign) id delegate;

@end

@implementation PVManager

- (id) init
{
    if (self = [super init])
    {
        self.foundDevices = [[[NSMutableArray alloc] init] autorelease];
        self.connectedDevices = [[[NSMutableArray alloc] init] autorelease];
        self.networkManager = [PVNetworkManager sharedManager];
        self.captureManager = [PVCaptureManager sharedManager];
        [_networkManager start:(id)self];
    }
    return self;
}

- (void)dealloc
{
    self.foundDevices = nil;
    self.connectedDevices = nil;
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

- (void) connectWithDevice:(NSDictionary*)device
{
    NSDictionary *fdevice = nil;
    for (NSDictionary *dv in _foundDevices) {
        NSDictionary *fd = [dv objectForKey:@"device"];
        
        if ([device isEqual:fd])
        {
            fdevice = [dv retain];
            [_foundDevices removeObject:dv];
            break;
        }
    }
    
    if (fdevice != nil)
        [self.networkManager connectWithDevice:[fdevice autorelease]];
}

#pragma mark PVNetworkManager delegate

- (void)PVNetworkManager:(PVNetworkManager*)manager didFoundDevice:(NSDictionary*)device
{
    if (![_foundDevices containsObject:device]) {
        
        [_foundDevices addObject:device];
    }
    
    NSDictionary *foundedDevice = [device objectForKey:@"device"];
    NSString *capabilities = [device objectForKey:@"capabilities"];
    if ([self.delegate respondsToSelector:@selector(PVManager:didFoundDevice:withCapabilities:)])
        [self.delegate PVManager:self didFoundDevice:foundedDevice withCapabilities:capabilities];
}

- (void)PVNetworkManager:(PVNetworkManager*)manager didConnectedToDevice:(NSDictionary*)device
{
    
    NSDictionary *connectedDevice = [device objectForKey:@"device"];
    NSString *capabilities = [device objectForKey:@"capabilities"];
    
    if (self.applcationType == PVApplicationTypeClient)
    {
        [self.delegate PVManager:self didEstablishedConnectionWithDevice:connectedDevice withCapabilities:capabilities];

    } else {

    }
}



@end
