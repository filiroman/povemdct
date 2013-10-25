//
//  WPNetworkManager.h
//  WirelessPlayer
//
//  Created by Roman Filippov on 18.06.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#define CONNECT_DATA 123
#define CAPTURE_DATA 2

#import <Foundation/Foundation.h>
#import "PVObserverViewController.h"

@class GCDAsyncSocket;
@class GCDAsyncUdpSocket;
@class PVCaptureManager;

@protocol PVNetworkManagerDelegate;

@interface PVNetworkManager : NSObject

@property (retain, nonatomic) GCDAsyncUdpSocket *udpSocket;
@property (retain, nonatomic) GCDAsyncSocket *tcpSocket;


@property (assign) NSUInteger inPort;
@property (assign) NSUInteger outMultiPort;

+ (id)sharedManager;
- (void)setupSocketForApplicationType:(PVApplicationType)appType;
- (void)searchHosts;
- (void)start:(id<PVNetworkManagerDelegate>)delegate;
- (void)stop:(id<PVNetworkManagerDelegate>)delegate;
- (void)sendData:(NSData*)data_to_send toDevice:(NSDictionary*)choosenDevice withType:(long)dataType;
- (void)sendData:(NSData*)data_to_send;

- (void)connectWithDevice:(NSDictionary*)device;

@end


@protocol PVNetworkManagerDelegate <NSObject>

- (void)PVNetworkManager:(PVNetworkManager*)manager didFoundDevice:(NSDictionary*)device;
- (void)PVNetworkManager:(PVNetworkManager*)manager didConnectedToDevice:(NSDictionary*)device;
- (void)PVNetworkManager:(PVNetworkManager*)manager didReceivedData:(NSData*)data fromDevice:(NSDictionary*)device;

@end