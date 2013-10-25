//
//  UIMainViewController.m
//  WirelessPlayer
//
//  Created by Roman Filippov on 10.06.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVObserverViewController.h"
#import "PVNetworkManager.h"
#import "GCDAsyncUdpSocket.h"
#import "PVActivityView.h"
#import "PVRootViewController.h"
#import "PVMainViewController.h"
#import "PVClientMainViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>


@interface PVObserverViewController ()

@property (retain, nonatomic) NSDictionary *choosenDevice;
@property (retain, nonatomic) NSMutableArray *devices;

@property (retain, nonatomic) UITableView *tableView;
@property (retain, nonatomic) UIButton *clientButton;
@property (retain, nonatomic) UIButton *serverButton;

@property (retain, nonatomic) PVNetworkManager *networkManager;
@property (assign, nonatomic) PVApplicationType applcationType;

@property (retain, nonatomic) PVActivityView *actView;

#define EXPORT_NAME @"exported.m4a"

@end

@implementation PVObserverViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        self.devices = [[NSMutableArray alloc] init];
        self.networkManager = [PVNetworkManager sharedManager];
        [_networkManager start:(id)self];
        
        self.actView = [PVActivityView sharedActivityView];
    }
    return self;
}

- (void)dealloc
{
    self.devices = nil;
    self.tableView = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor grayColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.alpha = 0.0f;
    self.tableView.backgroundColor = [UIColor lightGrayColor];
    self.tableView.layer.cornerRadius = 5.0f;
    self.tableView.clipsToBounds = YES;
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = (id)self;
    self.tableView.delegate = (id)self;
    
    self.clientButton = [UIButton buttonWithType:UIButtonTypeSystem];
    CALayer *btnLayer = [self.clientButton layer];
    [btnLayer setMasksToBounds:YES];
    [btnLayer setCornerRadius:5.0f];
    [self.clientButton setBackgroundColor:[UIColor lightGrayColor]];
    self.clientButton.tag = 0;
    [self.clientButton setTitle:NSLocalizedString(@"client_button", nil) forState:UIControlStateNormal];
    [self.clientButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.clientButton];
    
    [self.view addSubview:self.actView];
    self.actView.center=self.view.center;
    self.actView.hidden = YES;
    
    self.serverButton = [UIButton buttonWithType:UIButtonTypeSystem];
    CALayer *btnLayer2 = [self.serverButton layer];
    [btnLayer2 setMasksToBounds:YES];
    [btnLayer2 setCornerRadius:5.0f];
    [self.serverButton setBackgroundColor:[UIColor lightGrayColor]];
    self.serverButton.tag = 1;
    [self.serverButton setTitle:NSLocalizedString(@"server_button", nil) forState:UIControlStateNormal];
    [self.serverButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.serverButton];
    
    [self layoutSubviews];
    //[_networkManager setupSocket];
    //[_networkManager searchHosts];
}

- (void)buttonPressed:(id)sender
{
    int tag = ((UIButton*)sender).tag;
    self.applcationType = tag;
    
    [self.networkManager setupSocketForApplicationType:self.applcationType];
    
    [self configureViews];
    
}

- (void)configureViews
{
    if (self.applcationType == PVApplicationTypeClient)
    {
        [UIView animateWithDuration:0.5f animations:^{
            
            self.tableView.alpha = 1.0f;
            self.clientButton.alpha = 0.0f;
            self.serverButton.alpha = 0.0f;
            
        } completion:^(BOOL finished){
            self.tableView.hidden = NO;
            self.clientButton.hidden = YES;
            self.serverButton.hidden = YES;
        }];
    } else {
        [UIView animateWithDuration:0.5f animations:^{
            
            self.clientButton.alpha = 0.0f;
            self.serverButton.alpha = 0.0f;
            
        } completion:^(BOOL finished){
            self.clientButton.hidden = YES;
            self.serverButton.hidden = YES;
            [self.actView startAnimating];
        }];
    }
}

- (void)layoutSubviews
{
    CGRect screen = self.view.bounds;
    
    CGFloat x_offset = 15;
    CGFloat y_offset = 60;
    
    self.tableView.frame = CGRectMake(x_offset, y_offset, screen.size.width-x_offset*2, screen.size.height-y_offset*2);
    
    CGFloat buttonsWidth = 80;
    CGFloat buttonsHeight = 40;
    
    self.clientButton.frame = CGRectMake(screen.size.width/2 - buttonsWidth/2, screen.size.height/2-3*buttonsHeight/2, buttonsWidth, buttonsHeight);
    self.serverButton.frame = CGRectMake(screen.size.width/2 - buttonsWidth/2, screen.size.height/2+3*buttonsHeight/2, buttonsWidth, buttonsHeight);
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary *domain = [_devices objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@:%d",[domain objectForKey:@"host"], [[domain objectForKey:@"port"] intValue]];
    
    return cell;
}

- (void)PVNetworkManager:(PVNetworkManager*)manager didFoundDevice:(NSDictionary*)device
{
    //NSString *host = [device objectForKey:@"host"];
    //uint16_t port = [[device objectForKey:@"port"] intValue];
    
    if (![_devices containsObject:device]) {
        
        [_devices addObject:device];
        [self.tableView reloadData];
    }
}

- (void)PVNetworkManager:(PVNetworkManager*)manager didConnectedToDevice:(NSDictionary*)device
{
    [self.actView stopAnimating];
    
    if (self.applcationType == PVApplicationTypeClient)
    {
        //self.tableView.hidden = YES;
        self.choosenDevice = device;
        PVRootViewController *root = (PVRootViewController*)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
        PVClientMainViewController *mainVC = [[PVClientMainViewController alloc] init];
        [root pushViewController:mainVC animated:YES];
        [mainVC release];
    } else {
        
        self.choosenDevice = device;
        PVRootViewController *root = (PVRootViewController*)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
        PVMainViewController *mainVC = [[PVMainViewController alloc] init];
        [root pushViewController:mainVC animated:YES];
        [mainVC release];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.choosenDevice = [_devices objectAtIndex:indexPath.row];
    [self.networkManager connectWithDevice:_choosenDevice];
    [self.actView startAnimating];
    //[_networkManager sendData:nil toDevice:_choosenDevice];
}


@end
