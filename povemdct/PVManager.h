//
//  PVManager.h
//  povemdct
//
//  Created by Roman Filippov on 13.12.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PVApplicationTypeClient = 0,
    PVApplicationTypeServer = 1,
} PVApplicationType;

@class PVCaptureManager;

@protocol PVManagerDelegate;

@interface PVManager : NSObject

@property (retain, nonatomic) PVCaptureManager *captureManager;

+ (id) sharedManager;

- (void) startClientSide:(id<PVManagerDelegate>)delegate;
- (void) startServerSize:(id<PVManagerDelegate>)delegate;

//- (void)sendCommands:(NSDictionary*)commands;

@end


@protocol PVManagerDelegate <NSObject>

- (void)PVManagerDidEstablishedConnection:(PVManager*)manager;

@end

/*@interface PVManager (SubscribeMethods)

- (void)subscribeToAllEvents:(id<PVCaptureManagerCameraDelegate, PVCaptureManagerGyroDelegate>) delegate;
- (void)subscribeToCameraEvents:(id<PVCaptureManagerCameraDelegate>) delegate;
- (void)subscribeToGyroEvents:(id<PVCaptureManagerGyroDelegate>) delegate;

@end*/