//
//  MotionCommon.h
//  Mist
//
//  Created by Mist on 4/26/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MistSDK/MistSDK.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

@protocol MotionCommonDelegate;

@interface MotionCommon : NSObject <CLLocationManagerDelegate>

@property (nonatomic, weak) id <MotionCommonDelegate> delegate;

+(instancetype)sharedInstance;

-(NSDictionary *)handleMotion:(MSTPoint *)point;

-(NSDictionary *)calculateBasicMotion:(MSTPoint *)point;

-(NSDictionary *)calculateDeviceMotion:(MSTPoint *)point;

-(void)startMotion;

-(void)stopMotion;

@end

@protocol MotionCommonDelegate <NSObject>

-(void)deviceMotionUpdates:(CMDeviceMotion *)data;

-(void)gyroUpdates:(CMGyroData *)data;

-(void)magnoUpdates:(CMMagnetometerData *)data;

-(void)headingUpdates:(CLHeading *)data;

-(void)activityUpdates:(CMMotionActivity *)data;

@end
