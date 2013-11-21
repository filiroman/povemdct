//
//  WPNetworkManager.m
//  WirelessPlayer
//
//  Created by Roman Filippov on 18.06.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVNetworkManager.h"
#import "GCDAsyncUdpSocket.h"
#import "GCDAsyncSocket.h"

static PVNetworkManager *sharedNetworkManager = nil;

@interface PVNetworkManager()
{
    int numberOfSends;
}

@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) NSString *msg;
@property (nonatomic, retain) NSMutableArray *delegates;

@property (assign) dispatch_queue_t socketQueue;

@property (assign) PVApplicationType appType;

@property (nonatomic, retain) NSMutableArray *connectedDevices;

@end

@implementation PVNetworkManager

- (id)init
{
    
    if (self = [super init]) {
        
        numberOfSends = 5;
        
        self.delegates = [[[NSMutableArray alloc] init] autorelease];
        self.inPort = 9998;         // port for incoming connections
        self.outMultiPort = 9998;       //port for outcoming udp multicast
        self.host = @"255.255.255.255";     // multicast address
        self.socketQueue = nil;
        self.connectedDevices = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    self.delegates = nil;
    self.host = nil;
    self.msg = nil;
    self.connectedDevices = nil;
    
    [self.udpSocket close], self.udpSocket = nil;
    [self.tcpSocket disconnect], self.tcpSocket = nil;
    [super dealloc];
}

- (void)start:(id)delegate
{
    [_delegates addObject:delegate];
}

- (void)stop:(id)delegate
{
    [_delegates removeObject:delegate];
}

/*- (dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GCDAsyncSocket *)sock
{
    if (self.socketQueue == nil) {
        self.socketQueue = dispatch_queue_create("com.rf.povemdct.socketsqueue", NULL);
    } else {
        dispatch_retain(self.socketQueue);
    }
    return self.socketQueue;
}*/

- (void)connectWithDevice:(NSDictionary*)device
{
    NSString *host = [device objectForKey:@"host"];
    uint16_t port = [[device objectForKey:@"port"] intValue];
    NSError *error = nil;
    if (![self.tcpSocket connectToHost:host onPort:port error:&error])
    {
        NSLog(@"%@",[error description]);
        return;
    }
    NSLog(@"Starting connect to %@:%d",host,port);
    
}

- (BOOL)setupSockets
{
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:(id)self delegateQueue:dispatch_get_main_queue()];
    self.tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:(id)self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
	
	while (![self.udpSocket bindToPort:self.inPort error:&error])
	{
        self.inPort = arc4random() % UINT16_MAX + 5000;
	}
	if (![self.udpSocket beginReceiving:&error])
	{
        NSLog(@"Error!");
		return NO;
	}
    if (![self.udpSocket enableBroadcast:YES error:&error])
    {
        NSLog(@"Error!");
        return NO;
    }
    NSLog(@"Ready! at port:%d", self.inPort);
    return YES;
}

- (void)setupSocketForApplicationType:(PVApplicationType)appType;
{
    self.appType = appType;
    if (self.appType == PVApplicationTypeClient)
        [self setupClientSocket];
    else
        [self setupServerSocket];
}

- (void)setupServerSocket
{
    if ([self setupSockets])
    {
        //[self searchHosts];
        self.msg = @"pvm_server";
        NSError *error = nil;
        if (![self.tcpSocket acceptOnPort:self.inPort error:&error])
        {
            NSLog(@"%@",[error localizedDescription]);
        }
    }
}

- (void)setupClientSocket
{
    if ([self setupSockets])
    {
        self.msg = @"pvm_client";
        [self searchHosts];
    }
}

+ (id)sharedManager
{
    if (sharedNetworkManager == nil) {
        sharedNetworkManager = [[PVNetworkManager alloc] init];
    }
    return sharedNetworkManager;
}

- (void)sendData:(NSData*)data_to_send toDevice:(NSDictionary*)choosenDevice withType:(long)dataType;
{
    if (self.tcpSocket.isConnected)
        [self.tcpSocket writeData:data_to_send withTimeout:0 tag:dataType];
    
}

- (void)sendData:(NSData*)data_to_send withType:(long)dataType
{
    GCDAsyncSocket *newSocket = [self.connectedDevices objectAtIndex:0];
    NSString *host = [newSocket connectedHost];
    uint16_t port = [newSocket connectedPort];
    
    if (host != nil)
        [self sendData:data_to_send toDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]} withType:dataType];
}

- (void)sendData:(NSData*)data_to_send
{
    [self sendData:data_to_send withType:CAPTURE_DATA];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    if (tag == CAPTURE_DATA)
         NSLog(@"Data sent from server!");
}

- (void)searchHosts
{
    int tag = 123;
    NSData *data = [_msg dataUsingEncoding:NSUTF8StringEncoding];
    
    for (int i=0; i<numberOfSends; ++i) {
        [_udpSocket sendData:data toHost:_host port:_outMultiPort withTimeout:-1 tag:tag];
    }
}

#pragma mark - Socket delegate methods

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    if (self.appType == PVApplicationTypeServer)
    {
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([msg rangeOfString:@"pvm_client"].location != NSNotFound)
        {
            NSString *host = nil;
            uint16_t port = 0;
            [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
            
            NSData *data_to_send = [self.msg dataUsingEncoding:NSUTF8StringEncoding];
            for (int i=0; i<numberOfSends; ++i) {
                [sock sendData:data_to_send toAddress:address withTimeout:-1 tag:123];
            }
        }
    } else {
        
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([msg rangeOfString:@"pvm_server"].location != NSNotFound)
        {
            NSString *host = nil;
            uint16_t port = 0;
            [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
            
            [sock sendData:[self.msg dataUsingEncoding:NSUTF8StringEncoding] toAddress:address withTimeout:-1 tag:123];
            
            for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
                if ([delegate respondsToSelector:@selector(PVNetworkManager:didFoundDevice:)]) {
                    [delegate PVNetworkManager:self didFoundDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]}];
                }
            }
        }

    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
	// You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
	// You could add checks here
}

- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    
    @synchronized(_connectedDevices)
    {
        [_connectedDevices addObject:newSocket];
    }
    
    if (self.appType == PVApplicationTypeServer)
    {
        NSString *host = [newSocket connectedHost];
        uint16_t port = [newSocket connectedPort];
        self.tcpSocket = newSocket;
        NSLog(@"Socket accepted %@:%d",host, port);
        for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(PVNetworkManager:didConnectedToDevice:)]) {
                [delegate PVNetworkManager:self didConnectedToDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]}];
            }
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    
    NSLog(@"Connected to host %@:%d", host, port);
    
    //[self.tcpSocket readDataToLength:378 withTimeout:-1 tag:CAPTURE_DATA];
    
    
    if (self.appType == PVApplicationTypeClient) {
        for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(PVNetworkManager:didConnectedToDevice:)]) {
                [delegate PVNetworkManager:self didConnectedToDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]}];
            }
        }
    }
}


- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
    NSString *host = [sender connectedHost];
    uint16_t port = [sender connectedPort];
    
    for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(PVNetworkManager:didReceivedData:fromDevice:withType:)]) {
            [delegate PVNetworkManager:self didReceivedData:data fromDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]} withType:tag];
        }
    }
    
    if (tag == CAPTURE_DATA) {
        
        //NSLog(@"Capture data received on client side");
        [self.tcpSocket readDataToLength:378 withTimeout:-1 tag:CAPTURE_DATA];
        
    } else if (tag == WINSIZE_DATA)
    {
        NSLog(@"Winsize data received");
    }
    
    else
        NSLog(@"Other data received");
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"Socket disconnected");
    @synchronized(_connectedDevices)
    {
        [_connectedDevices removeObject:sock];
    }
}


@end
