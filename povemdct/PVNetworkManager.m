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
#import "NSMutableArray+NonRetaining.h"

static PVNetworkManager *sharedNetworkManager = nil;

@interface PVNetworkManager()
{
    int _numberOfSends;
    int _headerSize;
    
}

@property (retain, nonatomic) GCDAsyncUdpSocket *udpSocket;
@property (retain, nonatomic) GCDAsyncSocket *tcpSocket;

@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) NSString *msg;
@property (nonatomic, retain) NSMutableArray *delegates;

@property (assign) dispatch_queue_t socketQueue;

@property (assign) PVApplicationType appType;

@property (nonatomic, retain) NSMutableArray *connectedDevices;
@property (nonatomic, retain) NSMutableArray *connectedSockets;

@property (assign) NSUInteger inTCPPort;
@property (assign) NSUInteger inUDPPort;

@end

@implementation PVNetworkManager

- (id)init
{
    
    if (self = [super init]) {
        
        _numberOfSends = 5;
        
        self.delegates = [NSMutableArray nonRetainingArray];
        self.inTCPPort = 9996;         // port for incoming tcp connections
        self.inUDPPort = 9995;
        self.host = @"255.255.255.255";     // multicast address
        self.socketQueue = nil;
        _headerSize = -1;
        self.connectedDevices = [NSMutableArray array];
        self.connectedSockets = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    self.delegates = nil;
    self.host = nil;
    self.msg = nil;
    self.connectedDevices = nil;
    self.connectedSockets = nil;
    
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
    if (![self.connectedDevices containsObject:device]) {
        
        NSString *host = [device objectForKey:@"host"];
        uint16_t port = [[device objectForKey:@"port"] intValue];
        NSError *error = nil;
        if (![self.tcpSocket connectToHost:host onPort:self.inTCPPort error:&error])
        {
            NSLog(@"%@",[error description]);
            return;
        }
        if (![self.udpSocket connectToHost:host onPort:port error:&error])
        {
            NSLog(@"%@",[error description]);
            return;
        }
        
        NSLog(@"TCP Connected to %@:%lu",host,(unsigned long)self.inTCPPort);
        NSLog(@"UDP Connected to %@:%hu",host,port);
        [self.connectedDevices addObject:device];
    }
}

- (BOOL)setupSockets
{
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:(id)self delegateQueue:dispatch_get_main_queue()];
    self.tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:(id)self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
	
    if (![self.udpSocket enableBroadcast:YES error:&error])
    {
        NSLog(@"BroadCast Error!");
        return NO;
    }

   // NSLog(@"TCP is Ready at port: %lu", (unsigned long)self.inTCPPort);
   // NSLog(@"UDP is Ready at port: %lu", (unsigned long)self.inUDPPort);
    
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
        self.msg = @"pvm_server";
        NSError *error = nil;
        
        if (![self.tcpSocket acceptOnPort:self.inTCPPort error:&error])
        {
            NSLog(@"%@",[error localizedDescription]);
            return;
        }
        if (![self.udpSocket bindToPort:self.inUDPPort error:&error])
        {
            NSLog(@"Bind error!");
            return;
        }
        if (![self.udpSocket beginReceiving:&error])
        {
            NSLog(@"Error !");
            return;
        }
    }
}

- (void)setupClientSocket
{
    if ([self setupSockets])
    {
        self.msg = @"pvm_client";
        if (![self.udpSocket bindToPort:self.inUDPPort error:nil])
        {
            NSLog(@"Bind error!");
            return;
        }
        if (![self.udpSocket beginReceiving:nil])
        {
            NSLog(@"Error !");
            return;
        }
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

- (void)sendNotionalData:(NSData*)data_to_send withType:(int)dataType
{
    NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:(int)dataType], @"type", data_to_send, @"data", nil];
    NSData *hdata = [NSKeyedArchiver archivedDataWithRootObject:headers];
    
    NSDictionary *device = [self.connectedDevices objectAtIndex:0];
    NSString *host = [device objectForKey:@"host"];
    uint16_t port = [[device objectForKey:@"port"] intValue];
    
    [self.udpSocket sendData:hdata toHost:host port:self.inUDPPort withTimeout:-1 tag:dataType];;
}

- (void)sendData:(NSData*)data_to_send withType:(int)dataType
{
    if (!IS_SERVICE_DATA(dataType))
    {
        [self sendNotionalData:data_to_send withType:dataType];
        return;
    }
    
    NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:(int)dataType], @"type", [NSNumber numberWithInt:(int)[data_to_send length]], @"size", nil];
    [self sendHeaders:headers];
    
    assert([self.connectedSockets count] > 0 || [self.connectedDevices count] > 0);
    NSString *host;
    uint16_t port;
    if ([self.connectedSockets count] > 0) {
        GCDAsyncSocket *newSocket = [self.connectedSockets objectAtIndex:0];
        host = [newSocket connectedHost];
        port = [newSocket connectedPort];
    } else {
        NSDictionary *device = [self.connectedDevices objectAtIndex:0];
        host = [device objectForKey:@"host"];
        port = [[device objectForKey:@"port"] intValue];
    }
    
    if (host != nil)
        [self sendData:data_to_send toDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]} withType:dataType];
}

- (void)sendHeaders:(NSDictionary*)headers
{
    assert([self.connectedSockets count] > 0 || [self.connectedDevices count] > 0);
    NSString *host;
    uint16_t port;
    if ([self.connectedSockets count] > 0) {
        GCDAsyncSocket *newSocket = [self.connectedSockets objectAtIndex:0];
        host = [newSocket connectedHost];
        port = [newSocket connectedPort];
    } else {
        NSDictionary *device = [self.connectedDevices objectAtIndex:0];
        host = [device objectForKey:@"host"];
        port = [[device objectForKey:@"port"] intValue];
    }
    
    NSDictionary *conDevice = @{@"host": host, @"port" : [NSNumber numberWithInt:port]};
    
    NSString *selfHost = self.tcpSocket.localHost;
    uint16_t selfPort = self.tcpSocket.localPort;
    
    NSDictionary *selfDevice = @{@"host": selfHost, @"port": [NSNumber numberWithInt:selfPort]};
    
    NSMutableDictionary *dictionaryToSend = [NSMutableDictionary dictionaryWithDictionary:headers];
    [dictionaryToSend setObject:selfDevice forKey:@"device"];
    
    NSData *hdata = [NSKeyedArchiver archivedDataWithRootObject:dictionaryToSend];
    assert(hdata != nil);
    
    
    // send header size
    NSUInteger hsize = [hdata length];
    NSData *headerSize = [NSData dataWithBytes:&hsize length:sizeof(hsize)];
    [self sendData:headerSize toDevice:conDevice withType:CONNECT_DATA];
    [self sendData:hdata toDevice:conDevice withType:HEADER_DATA];
    
    /*NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    // NSTimeInterval is defined as double
    NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];
    NSData *timeData = [NSKeyedArchiver archivedDataWithRootObject:timeStampObj];
    int tsize = [timeData length];
    NSData *tSizeData = [NSData dataWithBytes:&tsize length:sizeof(tsize)];
    [self sendData:tSizeData toDevice:conDevice withType:CONNECT_DATA];
    [self sendData:timeData toDevice:conDevice withType:TIME_DATA];*/
    

}

- (void)sendData:(NSData*)data_to_send
{
    [self sendData:data_to_send withType:CAPTURE_DATA];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(int)tag
{
    if (tag == CAPTURE_DATA)
         NSLog(@"Data sent from server!");
}

- (void)searchHosts
{
    int tag = 123;
    NSDictionary *data_to_send = [NSDictionary dictionaryWithObject:_msg forKey:@"connect-message"];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:data_to_send];
    
    for (int i=0; i<_numberOfSends; ++i) {
        [_udpSocket sendData:data toHost:_host port:self.inUDPPort withTimeout:-1 tag:tag];
    }
    
    /*if (![self.udpSocket beginReceiving:nil])
    {
        NSLog(@"Error !");
        return;
    }*/
}

#pragma mark - UDP Socket delegate methods

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSDictionary *dataDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    NSAssert(dataDict != nil, @"UDP Data can not be nil!");
    
    if (self.appType == PVApplicationTypeServer)
    {
        //NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *msg = [dataDict objectForKey:@"connect-message"];
        if ([msg rangeOfString:@"pvm_client"].location != NSNotFound)
        {
            NSString *host = nil;
            uint16_t port = 0;
            [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
            
            NSDictionary *data_to_send_dict = [NSDictionary dictionaryWithObject:_msg forKey:@"connect-message"];
            NSData *data_to_send = [NSKeyedArchiver archivedDataWithRootObject:data_to_send_dict];
            
            for (int i=0; i<_numberOfSends; ++i) {
                [sock sendData:data_to_send toAddress:address withTimeout:-1 tag:123];
            }
        }
    } else {
        
        NSString *msg = [dataDict objectForKey:@"connect-message"];
        if (msg != nil) {
            if ([msg rangeOfString:@"pvm_server"].location != NSNotFound)
            {
                NSString *host = nil;
                uint16_t port = 0;
                [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
                
                //[sock sendData:[self.msg dataUsingEncoding:NSUTF8StringEncoding] toAddress:address withTimeout:-1 tag:123];
                
                for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
                    if ([delegate respondsToSelector:@selector(PVNetworkManager:didFoundDevice:)]) {
                        [delegate PVNetworkManager:self didFoundDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]}];
                    }
                }
                
                return;
            }
            
            if([msg rangeOfString:@"pvm_client"].location != NSNotFound)
                return;
        }
        
        NSString *host = nil;
        uint16_t port = 0;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        
        int dataType = [[dataDict objectForKey:@"type"] intValue];
        NSData *receivedData = [dataDict objectForKey:@"data"];
        
        for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(PVNetworkManager:didReceivedData:fromDevice:withType:)]) {
                [delegate PVNetworkManager:self didReceivedData:receivedData fromDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]} withType:dataType];
            }
        }


    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    NSString *host = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
    NSLog(@"Connected by UDP to host %@:%d", host, port);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
	// You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
	// You could add checks here
}

#pragma mark - TCP Socket delegate methods

- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    
    @synchronized(_connectedSockets)
    {
        [_connectedSockets addObject:newSocket];
    }
    
    if (self.appType == PVApplicationTypeServer)
    {
        NSString *host = [newSocket connectedHost];
        uint16_t port = [newSocket connectedPort];
        NSDictionary *conDevice = @{@"host": host, @"port" : [NSNumber numberWithInt:port]};
        self.tcpSocket = newSocket;
        NSLog(@"Socket accepted %@:%d",host, port);
        
        if (![self.connectedDevices containsObject:conDevice])
        {
            [self.connectedDevices addObject:conDevice];
        }
        
        if (self.appType == PVApplicationTypeServer)
            [self.tcpSocket readDataToLength:HEADER_LENGTH_MSG_SIZE withTimeout:-1 tag:CONNECT_DATA];
        
        
        for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(PVNetworkManager:didConnectedToDevice:)]) {
                [delegate PVNetworkManager:self didConnectedToDevice:conDevice];
            }
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    
    NSLog(@"Connected by TCP to host %@:%d", host, port);
    
    if (self.appType == PVApplicationTypeClient)
        [self.tcpSocket readDataToLength:HEADER_LENGTH_MSG_SIZE withTimeout:-1 tag:CONNECT_DATA];
    
    
    //if (self.appType == PVApplicationTypeClient) {
        for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(PVNetworkManager:didConnectedToDevice:)]) {
                [delegate PVNetworkManager:self didConnectedToDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]}];
            }
        }
    //}
}


- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
    if (tag == CONNECT_DATA)
    {
        [data getBytes:&_headerSize length:sizeof(_headerSize)];
        
        if (_headerSize != -1)
            [self.tcpSocket readDataToLength:_headerSize withTimeout:-1 tag:HEADER_DATA];
        
        return;
        
    } else if (tag == HEADER_DATA)
    {
        NSDictionary *hdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        int htype = [[hdata objectForKey:@"type"] intValue];
        int hsize = [[hdata objectForKey:@"size"] intValue];
        
        assert(hsize>0);
        
        [self.tcpSocket readDataToLength:hsize withTimeout:-1 tag:htype];
        
        return;
    }
    
    
    NSString *host = [sender connectedHost];
    uint16_t port = [sender connectedPort];
    
    for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(PVNetworkManager:didReceivedData:fromDevice:withType:)]) {
            [delegate PVNetworkManager:self didReceivedData:data fromDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]} withType:tag];
        }
    }
    
    if (self.appType == PVApplicationTypeClient)
        [self.tcpSocket readDataToLength:HEADER_LENGTH_MSG_SIZE withTimeout:-1 tag:CONNECT_DATA];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"Socket disconnectedq with error: %@", [err description]);
    @synchronized(_connectedSockets)
    {
        [_connectedSockets removeObject:sock];
    }
}


@end
