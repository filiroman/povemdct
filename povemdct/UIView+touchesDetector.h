//
//  UIView+touchesDetector.h
//  povemdct
//
//  Created by Roman Filippov on 28.05.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (touchesDetector)

+ (void)load;

- (void)pv_touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)pv_touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)pv_touchesCanceled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
