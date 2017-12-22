//
//  Default.h
//  Mist
//
//  Created by Mist on 7/8/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kDeviceID                     @"device-id"

#define kRange                        @"range"
#define kMonitor                      @"monitor"
#define kLocation                     @"location"

#define kDebugMode                    @"bob"
#define kShowDebuggerConsole          @"show-debugger-console"
#define kEnableUDP                    @"enable-udp"
#define kEnableDR                     @"enable-dr"
#define kEnableRemoteLogging          @"enable-remote-logging"

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 \
alpha:(a)]

#define HSVCOLOR(h,s,v) [UIColor colorWithHue:(h) saturation:(s) value:(v) alpha:1]
#define HSVACOLOR(h,s,v,a) [UIColor colorWithHue:(h) saturation:(s) value:(v) alpha:(a)]
#define RGBA(r,g,b,a) (r)/255.0, (g)/255.0, (b)/255.0, (a)


static NSString *kEnableLockscreenNotification = @"Lock screen notification";
static NSString *kEnableTransmitTestBeacon = @"Transmit Test Beacon";
static NSString *kEnableTransmitAppModifiedBluedot = @"Transmit App-modified Dot";
#define kEnableSmoothing              @"enable-smoothing"
#define kEnableVirtualAP              @"Enable Virtual AP"
#define kEnableNotification           @"enable-notification"


static NSMutableDictionary *localSettings;

// tag 10
typedef NS_ENUM(NSInteger, kMotionTag){
    kMotionTagBasic = 10,
    kMotionTagDevice = 11,
    kMotionTagSticky = 12,
    kMotionTagDeviceSimple = 13,
    kMotionTagSendMotionFlagToLE = 14,
};

@interface Default : NSObject

+(void)updateSettings:(NSDictionary *)settings withCompletion:(void(^)(void))callback;
+(NSMutableDictionary *)currentSettings;
+(void)appDefault;
+(NSString *)defaultFontName;
+(NSString *)newDefaultFontName;
+(UIColor *)defaultColor;
+(UIColor*)defaultSystemTintColor;

+(CGFloat)degreesToRadians:(CGFloat)degrees;
+(CGFloat)radiansToDegrees:(CGFloat)radians;

// Returns the OS version in float. e.g 9.0.1 = 9.0
+(float)OSVersion;

// Use this if you want to update the UI on the mainthread
+(void)performBlockOnMainThread:(void(^)(void))callback;

#pragma mark - new UI Specs

+(UIColor *)newBackgroundColor;
+(UIColor *)cellTextColor;
+(CAGradientLayer*) showFloorBackground;
+(UIColor *)newBlueBackgroundColor;
+(NSString *)newFont;

+(NSString*)getStringFromBeacons:(NSString*)beaconString;

+(NSString *)getUUIDString;
+(bool)useCustomTheme;
+(bool)isEmptyString:(NSString *)str;

@end
