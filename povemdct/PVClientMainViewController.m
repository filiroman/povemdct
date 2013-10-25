//
//  PVClientMainViewController.m
//  povemdct
//
//  Created by Roman Filippov on 25.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import "PVClientMainViewController.h"
#import "PVCaptureManager.h"

@interface PVClientMainViewController ()

@property (retain, nonatomic) UILabel *tLabel;
@property (retain, nonatomic) UITextView *textView;
@property (retain, nonatomic) PVCaptureManager *captureManager;

@end

@implementation PVClientMainViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        self.captureManager = [PVCaptureManager sharedManager];
        self.captureManager.delegate = (id)self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor grayColor]];
    
    self.tLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.tLabel.text = NSLocalizedString(@"client_main_label", nil);
    self.tLabel.font = [UIFont systemFontOfSize:20.0f];
    self.tLabel.textColor = [UIColor redColor];
    [self.view addSubview:self.tLabel];
    
    self.textView = [[[UITextView alloc] init] autorelease];
    self.textView.editable = NO;
    self.textView.scrollEnabled = YES;
    self.textView.pagingEnabled = YES;
    self.textView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.textView];
    
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    CGRect rect = self.view.bounds;

    CGFloat labelWidth = 90;
    CGFloat labelHeight = 40;
    
    self.tLabel.frame = CGRectMake(rect.size.width/2 - labelWidth/2, 40, labelWidth, labelHeight);
    
    CGFloat textViewOffset = 20;
    
    self.textView.frame = CGRectMake(textViewOffset, self.tLabel.frame.origin.y + 20 + labelHeight, rect.size.width - textViewOffset*2, rect.size.height - textViewOffset - self.tLabel.frame.origin.y - 20 - labelHeight);
}

- (void)dealloc
{
    self.captureManager = nil;
    [super dealloc];
}


- (void)PVCaptureManager:(PVCaptureManager*)manager didRecievedFaceCaptureAtRect:(CGRect)captureRect
{
    NSLog(@"Face captured at client!");
    NSString *logString = [NSString stringWithFormat:@"\nFace captured at rect: %@", NSStringFromCGRect(captureRect)];
    
    //dispatch_async(dispatch_get_main_queue(), ^{
    @synchronized(_textView) {
        NSString *newString = [self.textView.text stringByAppendingString:logString];
        self.textView.text = newString;
        NSRange range = NSMakeRange(self.textView.text.length - 1, 1);
        [self.textView scrollRangeToVisible:range];
    }
    //});
}

@end
