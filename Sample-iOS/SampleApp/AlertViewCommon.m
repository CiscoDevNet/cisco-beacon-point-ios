//
//  AlertViewCommon.m
//  Mist
//
//  Created by Mist on 3/24/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import "Default.h"
#import "AlertViewCommon.h"

static MBProgressHUD *_staticHUD;

@implementation AlertViewCommon

+(void)showHUDMessage:(NSString *)msg inView:(UIView*)view forDuration:(NSTimeInterval)interval{
    [Default performBlockOnMainThread:^{
        MBProgressHUD *hub = [MBProgressHUD showHUDAddedTo:view animated:YES];
        hub.labelText = msg;
        [hub hide:true afterDelay:interval];
    }];
}

+(void)showStaticHUDMessage:(NSString *)msg inView:(UIView*)view{
    [Default performBlockOnMainThread:^{
        if (!_staticHUD) {
            _staticHUD = [MBProgressHUD showHUDAddedTo:view animated:true];
        }
        _staticHUD.labelText = msg;
    }];
}

+(void)updateStaticHUDMessage:(NSString *)msg{
    [Default performBlockOnMainThread:^{
        _staticHUD.labelText = msg;
    }];
}

+(void)hideStaticHUDMessageNow{
    [Default performBlockOnMainThread:^{
        [_staticHUD hide:true];
        _staticHUD = nil;
    }];
}

+(void)hideStaticHUDMessageAfterDuration:(NSTimeInterval)interval{
    [Default performBlockOnMainThread:^{
        [_staticHUD hide:true afterDelay:interval];
        _staticHUD = nil;
    }];
}

@end
