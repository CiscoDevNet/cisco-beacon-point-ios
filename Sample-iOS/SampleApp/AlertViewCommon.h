//
//  AlertViewCommon.h
//  Mist
//
//  Created by Mist on 3/24/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AlertViewCommon : NSObject

+(void)showHUDMessage:(NSString *)msg inView:(UIView*)view forDuration:(NSTimeInterval)interval;

+(void)showStaticHUDMessage:(NSString *)msg inView:(UIView*)view;

+(void)updateStaticHUDMessage:(NSString *)msg;

+(void)hideStaticHUDMessageNow;

+(void)hideStaticHUDMessageAfterDuration:(NSTimeInterval)interval;

+(void)hideAllHUDsForView:(UIView *)view;

@end
