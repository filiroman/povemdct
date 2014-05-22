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
#import "PVCaptureManager.h"

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
@property (nonatomic, retain) NSMutableArray *connectingCandidates;

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
        self.host = @"255.255.255.255";     // broadcast address
        self.socketQueue = nil;
        _headerSize = -1;
        self.connectedDevices = [NSMutableArray array];
        self.connectedSockets = [NSMutableArray array];
        self.connectingCandidates = [NSMutableArray array];
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

- (void)connectWithDevice:(NSDictionary*)device_to_connect
{
    @synchronized (_connectedDevices) {
        
        NSDictionary *device = [device_to_connect objectForKey:@"device"];
        
        NSString *host = [device objectForKey:@"host"];
        uint16_t port = [[device objectForKey:@"tcp_port"] intValue];
        
        BOOL found = NO;
        
        for (NSDictionary *ddict in _connectedDevices) {
            
            NSDictionary *connectedDevice = [ddict objectForKey:@"device"];
            NSString *thost = [connectedDevice objectForKey:@"host"];
            uint16_t tport = [[connectedDevice objectForKey:@"tcp_port"] intValue];
            
            if ([thost isEqualToString:host] && tport == port)
            {
                found = YES;
                break;
            }
        }
        
        if (found)
            return;
        else
        {
            NSError *error = nil;
            
            GCDAsyncSocket *newSocket = [[GCDAsyncSocket alloc] initWithDelegate:(id)self delegateQueue:dispatch_get_main_queue()];
            
            if (![newSocket connectToHost:host onPort:port error:&error])
            {
                NSLog(@"%@",[error description]);
                return;
            }
            
            NSDictionary *conDevice = [NSDictionary dictionaryWithObjectsAndKeys:@{@"host" : host, @"tcp_port" : [device objectForKey:@"tcp_port"], @"tcp_socket" : newSocket}, @"device", [device_to_connect objectForKey:@"capabilities"], @"capabilities", nil];
            
            NSLog(@"TCP Connected to %@:%d",host,port);
            //NSLog(@"UDP Connected to %@:%hu",host,port);
            
            [_connectedDevices addObject:conDevice];
        }
    }
}

- (BOOL)setupSockets
{
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:(id)self delegateQueue:dispatch_get_main_queue()];
    self.tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:(id)self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    
    if (![self.udpSocket bindToPort:self.inUDPPort error:&error])
    {
        NSLog(@"Bind error!");
        return NO;
    }
    if (![self.udpSocket beginReceiving:&error])
    {
        NSLog(@"UDP Socket Error !");
        return NO;
    }
	
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


/*
 * Write data to device (host and port) with definite type via TCP socket. Using for control data types.
 *
 */
- (void)sendData:(NSData*)data_to_send toDevice:(NSDictionary*)choosenDevice withType:(long)dataType;
{
    /*if (self.tcpSocket.isConnected)
        [self.tcpSocket writeData:data_to_send withTimeout:0 tag:dataType];
    else
        NSLog(@"TCP Socket is not connected! Data did not send");*/
    
    NSString *requestedHost = [choosenDevice objectForKey:@"host"];
    GCDAsyncSocket *reqSocket = nil;
    
    for (NSDictionary *connectedDevice in _connectedDevices) {
        NSString *host = [[connectedDevice objectForKey:@"device"] objectForKey:@"host"];
        
        if ([requestedHost isEqualToString:host])
        {
            reqSocket = [[connectedDevice objectForKey:@"device"] objectForKey:@"tcp_socket"];
            break;
        }
    }
    
    if (reqSocket != nil)
    {
        [reqSocket writeData:data_to_send withTimeout:-1 tag:dataType];
    } else
    {
        NSLog(@"ERROR! No connected socket with the device found!");
    }
}

/*
 * Write data to device (host and port) with definite type via UDP socket. Using for captured data types.
 *
 */
- (void)sendNotionalData:(NSData*)data_to_send withType:(int)dataType toDevice:(NSDictionary*)device
{
    NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:(int)dataType], @"type", data_to_send, @"data", nil];
    NSData *hdata = [NSKeyedArchiver archivedDataWithRootObject:headers];

    NSString *host = [device objectForKey:@"host"];
    uint16_t port = self.inUDPPort;
    //[[device objectForKey:@"tcp_port"] intValue];
    
    [self.udpSocket sendData:hdata toHost:host port:port withTimeout:-1 tag:dataType];;
}

- (void)sendData:(NSData*)data_to_send withType:(int)dataType toDevice:(NSDictionary*)device
{
    if (!IS_SERVICE_DATA(dataType))
    {
        [self sendNotionalData:data_to_send withType:dataType toDevice:device];
        return;
    }
    
    NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:(int)dataType], @"type", [NSNumber numberWithInt:(int)[data_to_send length]], @"size", nil];
    
    [self sendHeaders:headers toDevice:device];
    
    /*assert([self.connectedSockets count] > 0 || [self.connectedDevices count] > 0);
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
    
    if (host != nil)*/
    [self sendData:data_to_send toDevice:device withType:dataType];
}

- (void)sendHeaders:(NSDictionary*)headers toDevice:(NSDictionary*)device
{
    assert([self.connectedSockets count] > 0 || [self.connectedDevices count] > 0);
    NSString *host = [device objectForKey:@"host"];
    uint16_t port = [[device objectForKey:@"tcp_port"] intValue];
    
    NSDictionary *conDevice = @{@"host": host, @"tcp_port" : [NSNumber numberWithInt:port]};
    
    //NSMutableDictionary *dictionaryToSend = [NSMutableDictionary dictionaryWithDictionary:headers];
    //[dictionaryToSend setObject:selfDevice forKey:@"from"];
    
    NSData *hdata = [NSKeyedArchiver archivedDataWithRootObject:headers];
    assert(hdata != nil);
    
    
    // send header size
    uint32_t hsize = [hdata length];
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
    //[self sendData:data_to_send withType:CAPTURE_DATA];
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
}

#pragma mark - UDP Socket delegate methods

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSDictionary *generalDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSDictionary *dataDict = [generalDict objectForKey:@"device"];
    
    NSAssert(generalDict != nil, @"UDP Data can not be nil!");
    
    if (self.appType == PVApplicationTypeServer)
    {
        //NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *msg = [generalDict objectForKey:@"connect-message"];
        if ([msg rangeOfString:@"pvm_client"].location != NSNotFound && msg != nil)
        {
            NSString *host = nil;
            uint16_t port = 0;
            [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
            
            NSRange cleanRange = [host rangeOfString:@":" options:NSBackwardsSearch];
            
            NSString *cleanedHost = nil;
            
            if (cleanRange.location != NSNotFound)
                cleanedHost = [host substringFromIndex:cleanRange.location+1];
            else
                cleanedHost = host;
            
            NSDictionary *cdict = @{@"host": cleanedHost, @"port" : [NSNumber numberWithInt:port]};
            
            @synchronized(_connectingCandidates)
            {
                if ([_connectingCandidates containsObject:cdict])
                    return;
                
                [_connectingCandidates addObject:cdict];
            }
            
            // to do: include device capabilities to header
            
            
            
            int tcpSocketPort = arc4random() % 10000 + 5000;
            
            GCDAsyncSocket *newSocket = [[GCDAsyncSocket alloc] initWithDelegate:(id)self delegateQueue:dispatch_get_main_queue()];
            
            @synchronized(_connectedSockets)
            {
                [_connectedSockets addObject:newSocket];
            }
            
            while (![newSocket acceptOnPort:tcpSocketPort error:nil])
            {
                tcpSocketPort = arc4random() % 10000 + 5000;
            }
            
            NSDictionary *data_to_send_dict = [NSDictionary dictionaryWithObjectsAndKeys:_msg, @"connect-message", [NSNumber numberWithInt:tcpSocketPort], @"tcp_port", nil];
            
            NSString *dCapabilities = [[PVCaptureManager sharedManager] deviceCapabilities];
            
            NSDictionary *final_dict = [NSDictionary dictionaryWithObjectsAndKeys:data_to_send_dict, @"device", dCapabilities, @"capabilities", nil];
            
            NSData *data_to_send = [NSKeyedArchiver archivedDataWithRootObject:final_dict];
            
            for (int i=0; i<_numberOfSends; ++i) {
                [sock sendData:data_to_send toAddress:address withTimeout:-1 tag:123];
            }
        }
        
        int dataType = [[generalDict objectForKey:@"type"] intValue];
        NSData *receivedData = [generalDict objectForKey:@"data"];
        
        if (dataType == TIME_DATA)
        {
            NSNumber *timeData = [NSKeyedUnarchiver unarchiveObjectWithData:receivedData];
            double diff = [[NSDate date] timeIntervalSince1970] - [timeData doubleValue];
            
            NSString *str = [NSString stringWithFormat:@"%f\n", diff*1000];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"file.txt"];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
                [str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            else {
            
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
                [fileHandle closeFile];
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
                
                //NSNumber *tcpConnectPort = [dataDict objectForKey:@"tcp_port"];
                
                /*NSDictionary *data_to_send_dict = [NSDictionary dictionaryWithObject:@"start_connection" forKey:@"connect-message"];
                NSData *data_to_send = [NSKeyedArchiver archivedDataWithRootObject:data_to_send_dict];
                
                [sock sendData:data_to_send toAddress:address withTimeout:-1 tag:123];*/
                
                NSMutableDictionary *deviceDict = [NSMutableDictionary dictionaryWithDictionary:[generalDict objectForKey:@"device"]];
                [deviceDict setObject:host forKey:@"host"];
                
                NSDictionary *final_dict = [NSDictionary dictionaryWithObjectsAndKeys:deviceDict, @"device", [generalDict objectForKey:@"capabilities"], @"capabilities", nil];
                
                for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
                    if ([delegate respondsToSelector:@selector(PVNetworkManager:didFoundDevice:)]) {
                        [delegate PVNetworkManager:self didFoundDevice:final_dict];
                    }
                }
                
                return;
            }
            
        }
        
        NSString *selfData = [generalDict objectForKey:@"connect-message"];
        if (selfData != nil)
            if([selfData rangeOfString:@"pvm_client"].location != NSNotFound)
                return;
        
        NSString *host = nil;
        uint16_t port = 0;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        
        int dataType = [[generalDict objectForKey:@"type"] intValue];
        NSData *receivedData = [generalDict objectForKey:@"data"];
        
        if (dataType == TIME_DATA) {
            NSLog(@"Time recieved and sent!");
            [sock sendData:data toAddress:address withTimeout:-1 tag:123];
            return;
        }
        
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

- (void)socket:(GCDAsyncSocket *)sender  didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    if (self.appType == PVApplicationTypeServer)
    {
        
        for (GCDAsyncSocket *oldSocket in _connectedSockets) {
            if ([oldSocket isEqual:sender])
            {
                [_connectedSockets removeObject:oldSocket];
                break;
            }
        }
        
        NSString *host = [newSocket connectedHost];
        uint16_t port = [newSocket connectedPort];
        NSMutableDictionary *conDevice = [NSMutableDictionary dictionaryWithDictionary:@{@"host": host, @"tcp_port" : [NSNumber numberWithInt:port], @"tcp_socket" : newSocket}];
        
        NSLog(@"Socket accepted %@:%d",host, port);
        
        @synchronized(_connectedDevices)
        {
            
            if (![_connectedDevices containsObject:conDevice])
            {
                [_connectedDevices addObject:conDevice];
            }
            /*for (NSMutableDictionary *dict in _connectedDevices) {
                NSString *fhost = [dict objectForKey:@"host"];
                
                if ([fhost isEqualToString:host])
                {
                    conDevice = dict;
                    break;
                }
            }
            
            if (conDevice == nil)
            {
                
                [_connectedDevices addObject:conDevice];
            } else
            {
                [conDevice setObject:[NSNumber numberWithInt:port] forKey:@"tcp_port"];
                [conDevice setObject:newSocket forKey:@"tcp_socket"];
            }*/
        }
        
        [newSocket readDataToLength:HEADER_LENGTH_MSG_SIZE withTimeout:-1 tag:CONNECT_DATA];
        
        
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
    
    //if (self.appType == PVApplicationTypeClient)
    //[sock readDataToLength:HEADER_LENGTH_MSG_SIZE withTimeout:-1 tag:CONNECT_DATA];
    
    
    //if (self.appType == PVApplicationTypeClient) {
    
    NSDictionary *foundDevice = nil;
    
    for (NSDictionary *device_dict in _connectedDevices) {

        NSDictionary *device = [device_dict objectForKey:@"device"];
        NSString *fhost = [device objectForKey:@"host"];
        
        if ([host isEqualToString:fhost])
        {
            foundDevice = device_dict;
            
            break;
        }
    }
    
    if (foundDevice == nil)
        return;
    
    NSDictionary *device = [foundDevice objectForKey:@"device"];
    NSDictionary *finalDict = [NSDictionary dictionaryWithObjectsAndKeys:@{@"host" : host, @"tcp_port" : [device objectForKey:@"tcp_port"]}, @"device", [foundDevice objectForKey:@"capabilities"], @"capabilities", nil];
    
    for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(PVNetworkManager:didConnectedToDevice:)]) {
            [delegate PVNetworkManager:self didConnectedToDevice:finalDict];
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
            [sender readDataToLength:_headerSize withTimeout:-1 tag:HEADER_DATA];
        
        return;
        
    } else if (tag == HEADER_DATA)
    {
        NSDictionary *hdata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        int htype = [[hdata objectForKey:@"type"] intValue];
        int hsize = [[hdata objectForKey:@"size"] intValue];
        
        assert(hsize>0);
        
        [sender readDataToLength:hsize withTimeout:-1 tag:htype];
        
        return;
    }
    
    
    NSString *host = [sender connectedHost];
    uint16_t port = [sender connectedPort];
    
    for (id<PVNetworkManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(PVNetworkManager:didReceivedData:fromDevice:withType:)]) {
            [delegate PVNetworkManager:self didReceivedData:data fromDevice:@{@"host": host, @"port" : [NSNumber numberWithInt:port]} withType:tag];
        }
    }
    
    if (self.appType == PVApplicationTypeServer)
        [sender readDataToLength:HEADER_LENGTH_MSG_SIZE withTimeout:-1 tag:CONNECT_DATA];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"Socket disconnectedq with error: %@", [err description]);
    /*@synchronized(_connectedSockets)
    {
        [_connectedSockets removeObject:sock];
    }*/
}


@end
