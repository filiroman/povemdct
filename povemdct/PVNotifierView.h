//
//  PVNotifierView.h
//  povemdct
//
//  Created by Roman Filippov on 24.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PVNotifierView : NSObject

+ (PVNotifierView *) sharedNotifier;

- (void) showLoading;
- (void) showLoadingWithText:(NSString *) text;
- (void) showLoadingWithLocalizedText:(NSString *) localizedText;

- (void) showLoadingAnimate:(BOOL) animate;
- (void) showLoadingWithText:(NSString *) text animate:(BOOL) animate;
- (void) showLoadingWithLocalizedText:(NSString *) localizedText animate:(BOOL) animate;

- (void) showText:(NSString *) text;
- (void) showText:(NSString *) text autoHide:(BOOL) autoHide;

- (void) showIcon:(UIImage *) icon;
- (void) showIcon:(UIImage *) icon autoHide:(BOOL) autoHide;

- (void) showCheckIconWithText:(NSString *) text;
- (void) showCheckIconWithLocalizedText:(NSString *) localizedText;
- (void) showFailedIcon;

- (void) showIcon:(UIImage *) icon withText:(NSString *) text;
- (void) showIcon:(UIImage *) icon withText:(NSString *) text autoHide:(BOOL) autoHide;
- (void) showIcon:(UIImage *) icon withText:(NSString *) text autoHideTimeout:(CGFloat) autoHideTimeout;

- (void) hide;

@end
