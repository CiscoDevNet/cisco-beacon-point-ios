//
//  MotionCommon.m
//  Mist
//
//  Created by Mist on 4/26/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import "MotionCommon.h"
#import "Default.h"
static NSString *kMotionMode = @"mode";
@interface MotionCommon ()

@property (nonatomic, strong) NSDictionary *motionSettings;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) CMMotionActivityManager *activityManager;
@property (nonatomic, strong) NSOperationQueue *motionQueue;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSMutableArray *averageInfo;
@property (nonatomic, strong) MSTPoint *previousPoint;

@property (nonatomic, strong) CMDeviceMotion *deviceMotion;
@property (nonatomic, strong) CMGyroData *gyroData;
@property (nonatomic, strong) CMMagnetometerData *magnoData;
@property (nonatomic, strong) CLHeading *headingData; // direction in angle
@property (nonatomic, assign) CLLocationDirection previousDirection; // direction in angle

@end

@implementation MotionCommon

+(instancetype)sharedInstance{
    static MotionCommon *_sharedInstance = nil;
    if (!_sharedInstance) {
        @synchronized (self) {
            _sharedInstance = [[self alloc] init];
        }
    }
    return _sharedInstance;
}

-(id)init{
    if (self = [super init]) {
        int DURATION = 0.1;
        
        self.averageInfo = [[NSMutableArray alloc] init];
        self.motionManager = [[CMMotionManager alloc] init];
        
        self.activityManager = [[CMMotionActivityManager alloc] init];
        
        self.motionManager.accelerometerUpdateInterval = DURATION;
        self.motionManager.gyroUpdateInterval = DURATION;
        self.motionManager.deviceMotionUpdateInterval = DURATION;
        self.motionManager.magnetometerUpdateInterval = DURATION;
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.pausesLocationUpdatesAutomatically = false;
        self.locationManager.startUpdatingHeading;
    }
    return self;
}

-(NSOperationQueue *)motionQueue{
    if (!_motionQueue) {
        _motionQueue = [[NSOperationQueue alloc] init];
    }
    return _motionQueue;
}

-(NSDictionary *)handleMotion:(MSTPoint *)point{
    MSTPoint *finalPoint = point;
    bool canMove = false;
    bool showYellow = false;
    self.motionSettings = [[Default currentSettings] objectForKey:@"motion_settings"];
    if (self.motionSettings) {
        
        if ([[self.motionSettings objectForKey:@"status"] boolValue]) {
            NSNumber *mode = [self.motionSettings objectForKey:kMotionMode];
            
            switch (mode.integerValue) {
                case kMotionTagBasic:{
                    NSDictionary *response = [self calculateBasicMotion:point];
                    canMove = [response[@"canMove"] boolValue];
                    showYellow = canMove;
                    break;
                }
                case kMotionTagDevice:{
                    [self startMotion];
                    NSDictionary *response =  [self calculateDeviceMotion:point];
                    canMove = [response[@"canMove"] boolValue];
                    showYellow = canMove;
                    break;
                }
                case kMotionTagDeviceSimple:{
                    [self startMotion];
                    NSDictionary *response =  [self calculateBasicMotion:point];
                    canMove = [response[@"canMove"] boolValue];
                    showYellow = canMove;
                    break;
                }
            }
        } else {
            canMove = true;
            showYellow = point.hasMotion;
            [self stopMotion];
        }
        
        bool sticky = [[self.motionSettings objectForKey:[NSString stringWithFormat:@"switch-%@",@(kMotionTagSticky)]] boolValue];
        if (sticky) {
            finalPoint = [self calculateAverageMotion:point];
        } else {
            [self.averageInfo removeAllObjects];
        }
    } else { // if no mode is on, fall back to the no logic behavior
        canMove = true;
        showYellow = point.hasMotion;
        finalPoint = point;
    }
    NSDictionary *result = @{@"canMove":@(canMove),
                             @"showYellow":@(showYellow),
                             @"point": finalPoint};
    return result;
}

-(NSDictionary *)calculateBasicMotion:(MSTPoint *)point{
    return @{@"canMove":@((bool)point.hasMotion),@"point":point};
}

-(MSTPoint *)calculateAverageMotion:(MSTPoint *)point{
    MSTPoint *finalPoint = point;
    NSString *average = [self.motionSettings objectForKey:@"average"]; // todo: consider the average amount
    if (average == nil) {
        if (self.averageInfo.count == [average integerValue]) {
            [self.averageInfo removeObjectAtIndex:0];
        }
        
        [self.averageInfo addObject:[[MSTPoint alloc] initWithX:point.x andY:point.y]];
        
        __block double x = 0;
        __block double y = 0;
        [self.averageInfo enumerateObjectsUsingBlock:^(MSTPoint *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"a: %@ %lu",obj,(unsigned long)idx);
            x += obj.x;
            y += obj.y;
        }];
        
        finalPoint = [[MSTPoint alloc] initWithX:(x/self.averageInfo.count) andY:(y/self.averageInfo.count)];
    } else {
#ifdef DEBUG
//        [Logger info:@"Average motion value for device motion setting is not set. Not averaging."];
#endif
    }
    return finalPoint;
}

-(NSDictionary *)calculateSimpleDeviceMotion:(MSTPoint *)point{
    bool canMove = [self canMoveBasedOnAccelerometerThreshold];
    return @{@"canMove":@(canMove),@"point":point};
}

/**
 *  Device motion algorithm
 *
 *  @param point receives a LE location
 *
 *  @return return the rule to render the dot.
 */
-(NSDictionary *)calculateDeviceMotion:(MSTPoint *)point{
    if ([self hasDirectionChanged]) {
        return @{@"canMove":@(false),@"point":point};
    } else {
        bool canMove = [self canMoveBasedOnAccelerometerThreshold];
        return @{@"canMove":@(canMove),@"point":point};
    }
}

-(bool)hasDirectionChanged{
    NSLog(@"heading = %.2f %.2f",self.headingData.trueHeading, self.previousDirection);
    bool hasChanged;
    if (fabs(self.headingData.trueHeading-self.previousDirection) > 10) {
        hasChanged = true;
    } else {
        hasChanged = false;
    }
    self.previousDirection = self.headingData.trueHeading;
    return hasChanged;
}

/**
 *  Check to see if the bluedot should move
 *
 *  @param vector provide a acceleration vector
 *
 *  @return true means it can move, false means it can't move
 */
-(bool)canMoveBasedOnAccelerometerThreshold{
//    Accelerometer orientation
//    https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAcceleration_Class/Art/device_axes.jpg
    
    UIAccelerationValue accelX = self.deviceMotion.userAcceleration.x; // ignoring x because it's left to right
    UIAccelerationValue accelY = self.deviceMotion.userAcceleration.y; // can be forward or up depending on your phone orientation. Refer to the axes image above.
    UIAccelerationValue accelZ = self.deviceMotion.userAcceleration.z; // can be forward or up depending on your phone orientation. Refer to the axes image above.
    
    accelX *= 0.1; // weight this lowest
    
    //    UIAccelerationValue vector = sqrt(pow(data.userAcceleration.x, 2)+pow(data.userAcceleration.y, 2)+pow(data.userAcceleration.z, 2));
    UIAccelerationValue vector = sqrt(pow(accelY, 2)+pow(accelZ, 2));
    
    NSString *threshold = [self.motionSettings objectForKey:@"threshold"];
    
    NSLog(@"threadhold = %f %@",vector, threshold);
    
    if (vector > [threshold doubleValue]) {
        return true;
    } else {
        return false;
    }
}

#pragma mark - Motion Methods

-(void)startMotion{
    [self.motionManager startDeviceMotionUpdatesToQueue:self.motionQueue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        [Default performBlockOnMainThread:^{
            self.deviceMotion = motion;
            if ([self.delegate respondsToSelector:@selector(deviceMotionUpdates:)]) {
                [self.delegate deviceMotionUpdates:motion];
            }
        }];
    }];
    
    [self.motionManager startGyroUpdatesToQueue:self.motionQueue withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        [Default performBlockOnMainThread:^{
            self.gyroData = gyroData;
            if ([self.delegate respondsToSelector:@selector(gyroUpdates:)]) {
                [self.delegate gyroUpdates:gyroData];
            }
        }];
    }];
    
    [self.motionManager startMagnetometerUpdatesToQueue:self.motionQueue withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
        [Default performBlockOnMainThread:^{
            self.magnoData = magnetometerData;
            if ([self.delegate respondsToSelector:@selector(magnoUpdates:)]) {
                [self.delegate magnoUpdates:magnetometerData];
            }
        }];
    }];
    
    [self.activityManager startActivityUpdatesToQueue:self.motionQueue withHandler:^(CMMotionActivity * _Nullable activity) {       
        [Default performBlockOnMainThread:^{
            if ([self.delegate respondsToSelector:@selector(activityUpdates:)]) {
                [self.delegate activityUpdates:activity];
            }
        }];
    }];
    
    [self.locationManager startUpdatingHeading];
}

-(void)stopMotion{
    [self.motionManager stopDeviceMotionUpdates];
    [self.motionManager stopGyroUpdates];
    [self.motionManager stopMagnetometerUpdates];
    [self.locationManager stopUpdatingHeading];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading{
        self.headingData = newHeading;
        if ([self.delegate respondsToSelector:@selector(headingUpdates:)]) {
            [self.delegate headingUpdates:newHeading];
        }
}

@end
