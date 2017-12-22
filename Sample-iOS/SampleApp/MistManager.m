//
//  MistManager.m
//  Mist
//
//  Created by Mist on 7/1/15.
//  Copyright © 2016 Mist. All rights reserved.
//

#import "MistManager.h"
#import "Default.h"
#import "AlertViewCommon.h"
#import "Logger.h"

@interface MistManager () <MSTCentralManagerDelegate, MSTProximityDelegate>{}

@property (nonatomic, strong) MSTCentralManager *mstCentralManager;
@property (nonatomic, strong) NSMutableDictionary *appSettings;
@property (nonatomic, strong) NSMutableDictionary *callbacks;
@property (nonatomic, strong) NSOperationQueue *backgroundQueue;
@property (nonatomic, strong) NSUUID *mistUUID;
@property (nonatomic, assign) BOOL shouldTestAppModifiedLocation;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) int secondsBehind;

@end


@implementation MistManager

+(instancetype)sharedInstance{
    static MistManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
        _sharedInstance.backgroundQueue = [[NSOperationQueue alloc] init];
    });
    
    return _sharedInstance;
}

-(id)init{
    self = [super init];
    if (self) {
        self.callbacks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)reconnect{
    [self sendLogs:@{@"SDKDownAttemptingToRestartFromApp":@""}];
    
    if (_isConnected) {
        [self disconnect];
        self.appSettings = [Default currentSettings];
        [self connect];
    }
}

-(void)connect{
    // If simulate flag is set, simulate the SDK's responses.
   
    
    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
        self.secondsBehind = 0;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkIfLEIsDelayed) userInfo:nil repeats:true];
    
    if (_isConnected) {
        NSLog(@"MistManager is still connected. Please call disconnect first");
        return;
    }
    self.zoneEventsMsg = [[NSMutableArray alloc] init];
    self.virtualBeacons = [[NSDictionary alloc] init];
    
    self.appSettings = [Default currentSettings];
    
    NSLog(@"mistID (%@)",[self.appSettings objectForKey:kDeviceID]);
    NSLog(@"id (%@)",[self.appSettings objectForKey:@"tokenID"]);
    NSLog(@"secret (%@)",[self.appSettings objectForKey:@"tokenSecret"]);
    
    [[MSTRestAPI sharedInstance] logout];
    
    // Make sure the logs are saved for this orgID
    [[Logger sharedInstance] setFilePrefix:[self.appSettings objectForKey:@"tokenID"]];
    
    [[MSTRestAPI sharedInstance] setEnv:[self.appSettings objectForKey:@"tokenEnvType"]];
    
    self.mstCentralManager = [[MSTCentralManager alloc] initWithOrgID:[self.appSettings objectForKey:@"tokenID"]
                                                   AndOrgSecret:[self.appSettings objectForKey:@"tokenSecret"]];

    if (true) {
        [self.mstCentralManager setShouldCompressData:true];
        [self sendLogs:@{@"setShouldCompressData":@""}];
    }
 
    [self.mstCentralManager backgroundAppSetting:true];
    [self.mstCentralManager setSentTimeInBackgroundInMins:0.5 restTimeInBackgroundInMins:5];
    
    if ([[self.appSettings objectForKey:kShowDebuggerConsole] boolValue]) {
        [self.mstCentralManager setShouldShowVerboseLogs:[[self.appSettings objectForKey:kShowDebuggerConsole] boolValue]];
        [self sendLogs:@{@"setShouldShowVerboseLogs":@""}];
    }
    
    if ([[self.appSettings objectForKey:kEnableUDP] boolValue]) {
        [self.mstCentralManager setShouldUseUDP:[[self.appSettings objectForKey:kEnableUDP] boolValue]];
        [self sendLogs:@{@"setShouldUseUDP ON":@""}];
    } else {
        [self.mstCentralManager setShouldUseUDP:[[self.appSettings objectForKey:kEnableUDP] boolValue]];
        [self sendLogs:@{@"setShouldUseUDP OFF":@""}];
    }
    
    if ([[self.appSettings objectForKey:kEnableDR] boolValue]) {
        [self.mstCentralManager setShouldUseDeadReckoning:[[self.appSettings objectForKey:kEnableDR] boolValue]];
        [self sendLogs:@{@"setShouldUseDeadReckoning ON":@""}];
    } else {
        [self.mstCentralManager setShouldUseDeadReckoning:[[self.appSettings objectForKey:kEnableDR] boolValue]];
        [self sendLogs:@{@"setShouldUseDeadReckoning OFF":@""}];
    }
    
    // enable lock screen / wake up
    if ([[self.appSettings objectForKey:kEnableLockscreenNotification] boolValue]) {
        [self.mstCentralManager wakeUpAppSetting:[[self.appSettings objectForKey:kEnableLockscreenNotification] boolValue]];
        [self sendLogs:@{@"wakeUpAppSetting ON":@""}];
    } else {
        [self.mstCentralManager wakeUpAppSetting:[[self.appSettings objectForKey:kEnableLockscreenNotification] boolValue]];
        [self sendLogs:@{@"wakeUpAppSetting OFF":@""}];
    }
    
    // enable virtual AP
    if ([[self.appSettings objectForKey:kEnableVirtualAP] boolValue]) {
        [self.mstCentralManager startTestsForDurationInMins:self.virtualAPTestMin];
        [self sendLogs:@{@"startTestsForDurationInMins":@""}];
    }
    
    @try {
        if ([[self.appSettings objectForKey:kEnableTransmitTestBeacon] boolValue]) {
            [self.mstCentralManager startAssetTransmission];
        } else {
            [self.mstCentralManager stopAssetTransmission];
        }
    } @catch (NSException *exception) {
        NSLog(@"Caught exception when enabling kEnableTransmitTestBeacon = %@", exception);
    }
    
    [self.mstCentralManager setEnviroment:[self.appSettings objectForKey:@"tokenEnvType"]];
    
    if ([[self.appSettings objectForKey:kMonitor] boolValue] && [[self.appSettings objectForKey:kMonitor] boolValue]) {
        [self.mstCentralManager requestAuthorization:AuthorizationTypeALWAYS];
    } else {
        [self.mstCentralManager requestAuthorization:AuthorizationTypeUSE];
    }
    
    if ([[self.appSettings objectForKey:kEnableSmoothing] integerValue] > 0) {
        self.mstCentralManager.isSmoothingEnabled = true;
        self.mstCentralManager.smoothingNumber = [[self.appSettings objectForKey:kEnableSmoothing] integerValue];
    } else {
        self.mstCentralManager.isSmoothingEnabled = false;
    }
    
    if ([self.appSettings objectForKey:@"motion_settings"]) {
        NSDictionary *motionSettings = [self.appSettings objectForKey:@"motion_settings"];
        
        if ([[motionSettings objectForKey:[NSString stringWithFormat:@"switch-%@",@(kMotionTagSendMotionFlagToLE)]] boolValue]) {
            self.mstCentralManager.shouldSendDeviceIsMoving = true;
        } else {
            self.mstCentralManager.shouldSendDeviceIsMoving = false;
        }
    }
    
    if ([[self.appSettings objectForKey:kMonitor] boolValue]) {
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"b9407f30-f5f8-466e-aff9-25556b57fe6d"] identifier:@"estimote"];
        [self.mstCentralManager setMonitoringInBackground:@[region]];
    }
    if ([[self.appSettings objectForKey:kRange] boolValue]) {
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"b9407f30-f5f8-466e-aff9-25556b57fe6d"] identifier:@"estimote"];
        [self.mstCentralManager setRangingInBackground:@[region]];
    }
    
    // Setting PF Setting
    NSDictionary *pfInfo = [self.appSettings objectForKey:@"pf_params"];
    if (pfInfo) {
        [self applyPFParams:pfInfo];
    }
    
    self.mstCentralManager.delegate = self;
    self.mstCentralManager.proximityDelegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mstCentralManager setAppState:[[UIApplication sharedApplication] applicationState]];
        [self.mstCentralManager startLocationUpdates];
    });
    
    _isConnected = true;
}

-(void)disconnect{
    if (SIM) {
        return;
    }
    
    [self.mstCentralManager stopLocationUpdates];
    if (_isConnected) {
        self.mstCentralManager = nil;
        self.currentMap = nil;
        self.clientInformation = nil;
    }
    _isConnected = false;
    
    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
        self.secondsBehind = 0;
    }
}

-(void)addEvent:(NSString *)event forTarget:(id)target{
    @synchronized (self) {
        NSMutableArray *targets = [self.callbacks objectForKey:event];
        if (targets) {
            [targets addObject:target];
        } else {
            NSMutableArray *targets = [[NSMutableArray alloc] init];
            [targets addObject:target];
            [self.callbacks setObject:targets forKey:event];
        }
    }
}

-(void)removeEvent:(NSString *)event forTarget:(id)target{
    @synchronized (self) {
        NSMutableArray *targets = [self.callbacks objectForKey:event];
        int index = -1;
        if (targets) {
            for (int i = 0 ; i < targets.count ; i++) {
                if ([targets objectAtIndex:i] == target) {
                    index = i;
                }
            }
            if (index > -1) {
                [targets removeObjectAtIndex:index];
            }
        }
    }
}

-(void)addEvents:(NSArray *)events forTarget:(id)target{
    [events enumerateObjectsUsingBlock:^(NSString *event, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addEvent:event forTarget:target];
    }];
}

-(void)removeEvents:(NSArray *)events forTarget:(id)target{
    [events enumerateObjectsUsingBlock:^(NSString *event, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeEvent:event forTarget:target];
    }];
}

#pragma mark - MSTCentralManager

#pragma mark - MSTCentralManager features

-(bool)isMSTCentralManagerRunning{
    return self.mstCentralManager.isRunning;
}

-(void)setWakeUpAppSetting:(bool)boolean{
    [self.mstCentralManager wakeUpAppSetting:boolean];
}

#pragma mark - MSTCentralManager private APIs

-(void)persistAndApplyPFParams:(NSDictionary *)info{
    // Persisting pf info
    NSMutableDictionary *appSettings = [[Default currentSettings] mutableCopy];
    [appSettings setObject:info forKey:@"pf_params"];
    [Default updateSettings:appSettings withCompletion:nil];
    
    // Using the saved version
    self.appSettings = [Default currentSettings];
    
    // Apply if it's running
    if (self.isMSTCentralManagerRunning) {
        [self applyPFParams:info];
    }
}

-(void)applyPFParams:(NSDictionary *)info{
    [self.mstCentralManager setPFWayFindingParam1:[[info objectForKey:@"way1"] intValue]
                                           param2:[[info objectForKey:@"way2"] intValue]];
    
    [self.mstCentralManager setSpeed:[[info objectForKey:@"speed"] floatValue]];
    
    [self.mstCentralManager setSdsParam1:[[info objectForKey:@"speed_sd"] intValue]
                                  param2:[[info objectForKey:@"speed_sd_est"] intValue]
                                  param3:[[info objectForKey:@"angle_sd_1sd"] intValue]
                                  param4:[[info objectForKey:@"angle_sd_2sd"] intValue]
                                  param4:[[info objectForKey:@"le_sd"] intValue]];
}

#pragma mark - FROM CLOUD

#pragma mark - FIXME: Refactor the following pattern

- (CLLocationCoordinate2D) getLatitudeLongitudeUsingMapOriginForX: (double) x AndY: (double) y{
    return [self.mstCentralManager getLatitudeLongitudeUsingMapOriginForX:x AndY:y];
}

-(void)mistManager:(MSTCentralManager *)manager didConnect:(BOOL)isConnected{
#ifdef DEBUG
    [[Logger sharedInstance] debug:[NSString stringWithFormat:@"didConnect = %d",isConnected]];
#endif
    
    _isConnected = isConnected;
    
    NSMutableArray *targets = [self.callbacks objectForKey:@"didConnect"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didConnect:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didConnect:isConnected];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateMap:(MSTMap *)map at:(NSDate *)dateUpdated{
    self.siteId = map.siteId;
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateMap"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateMap:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateMap:map at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didReceivedVirtualBeacons:(NSArray *)virtualBeacons{
    NSMutableDictionary *oneTimeDict = [[NSMutableDictionary alloc] init];
    [virtualBeacons enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [oneTimeDict setObject:obj forKey:[obj objectForKey:@"id"]];
    }];
    
    self.virtualBeacons = [[NSDictionary alloc] initWithDictionary:oneTimeDict];
    
    NSMutableArray *targets = [self.callbacks objectForKey:@"didReceivedVirtualBeacons"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didReceivedVirtualBeacons:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didReceivedVirtualBeacons:virtualBeacons];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didReceivedClientInformation:(NSDictionary *)clientInformation{
    self.clientInformation = [[NSMutableDictionary alloc] initWithDictionary:clientInformation];
    
    NSMutableArray *targets = [self.callbacks objectForKey:@"didReceivedClientInformation"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didReceivedClientInformation:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didReceivedClientInformation:clientInformation];
                }];
            }
        }
    }
}

-(void)manager:(MSTCentralManager *) manager receivedLogMessage: (NSString *)message forCode:(MSTCentralManagerStatusCode)code{
#ifdef DEBUG
    [[Logger sharedInstance] info:message];
#endif
    
    if (code < MSTCentralManagerStatusCodeSentJSON) {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        if (code == MSTCentralManagerStatusCodeDisconnected) {
            [AlertViewCommon showHUDMessage:message inView:window forDuration:1];
        } else {
            [AlertViewCommon showHUDMessage:message inView:window forDuration:3];
        }
    }
    
    if ([self.callbacks objectForKey:@"receivedLogMessage"]) {
        NSMutableArray *targets = [self.callbacks objectForKey:@"receivedLogMessage"];
        if ([targets count] > 0) {
            for (id target in targets) {
                if ([target respondsToSelector:@selector(manager:receivedLogMessage:forCode:)]) {
                    [self.backgroundQueue addOperationWithBlock:^{
                        [target manager:manager receivedLogMessage:message forCode:code];
                    }];
                }
            }
        }
    }
}

-(void)manager:(MSTCentralManager *)manager receivedVerboseLogMessage:(NSString *)message{
    // write the logs for debugging
    NSLog(@"DEBUG: verboseMsg: %@", message);
    
    if ([self.callbacks objectForKey:@"receivedVerboseLogMessage"]) {
        NSMutableArray *targets = [self.callbacks objectForKey:@"receivedVerboseLogMessage"];
        if ([targets count] > 0) {
            for (id target in targets) {
                if ([target respondsToSelector:@selector(manager:receivedVerboseLogMessage:)]) {
                    [self.backgroundQueue addOperationWithBlock:^{
                        [target manager:manager receivedVerboseLogMessage:message];
                    }];
                }
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didReceiveNotificationMessage:(NSDictionary *)payload{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didReceiveNotificationMessage"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didReceiveNotificationMessage:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didReceiveNotificationMessage:payload];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager willUpdateRelativeLocation:(MSTPoint *)relativeLocation inMaps:(NSArray *)maps at:(NSDate *)dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"willUpdateRelativeLocation"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:willUpdateRelativeLocation:inMaps:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager willUpdateRelativeLocation:relativeLocation inMaps:maps at:dateUpdated];
                }];
            }
        }
    }
}
-(void)mistManager:(MSTCentralManager *)manager didUpdateBeaconList:(NSArray *) beaconList at: (NSDate *) dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateBeaconList"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateBeaconList:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateBeaconList:beaconList at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager willUpdateLocation:(CLLocationCoordinate2D)location inMaps:(NSArray *)maps withSource:(SourceType)locationSource at:(NSDate *)dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"willUpdateLocation"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:willUpdateLocation:inMaps:withSource:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager willUpdateLocation:location inMaps:maps withSource:locationSource at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateRelativeLocation:(MSTPoint *)relativeLocation inMaps:(NSArray *)maps at:(NSDate *)dateUpdated{
    
    [self sendLogs:@{@"didUpdateRelativeLocation":relativeLocation.description}];
    self.secondsBehind = 0;
    
    self.userLocation = relativeLocation;
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateRelativeLocation"];
    
    if (targets) {
        if ([targets count] > 0) {
            for (id target in targets) {
                if ([target respondsToSelector:@selector(mistManager:didUpdateRelativeLocation:inMaps:at:)]) {
                    [self.backgroundQueue addOperationWithBlock:^{
                        [target mistManager:manager didUpdateRelativeLocation:relativeLocation inMaps:maps at:dateUpdated];
                    }];
                }
            }
        }
    }
    
    /* LAB STUFF */
    
//    NSUInteger tx = [self.mstCentralManager getAccumulativeTXSize];
//    NSLog(@"tx bytes = %lu",(unsigned long)tx);
//
//    NSUInteger rx = [self.mstCentralManager getAccumulativeRXSize];
//    NSLog(@"rx bytes = %lu",(unsigned long)rx);
    
    // TEMPORARY: testing app modified location
    if ([[self.appSettings objectForKey:kEnableTransmitAppModifiedBluedot] boolValue]) {
        NSLog(@"sending");
        CLLocationCoordinate2D latlong = [self.mstCentralManager getLatitudeLongitudeUsingMapOriginForX:relativeLocation.x AndY:relativeLocation.y];
        [self.mstCentralManager sendAppModifiedLocation:latlong];
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateLocation:(CLLocationCoordinate2D)location inMaps:(NSArray *)maps withSource:(SourceType)locationSource at:(NSDate *)dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateLocation"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateLocation:inMaps:withSource:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateLocation:location inMaps:maps withSource:locationSource at:dateUpdated];
                }];
            }
        }
    }
}

- (void) mistManager:(MSTCentralManager *)manager didUpdateSecondEstimate: (MSTPoint *) estimate inMaps: (NSArray *) maps at: (NSDate *) dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateSecondEstimate"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateSecondEstimate:inMaps:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateSecondEstimate:estimate inMaps:maps at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager beaconsSent:(NSMutableArray*)beacons{
    NSMutableArray *targets = [self.callbacks objectForKey:@"beaconsSent"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:beaconsSent:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager beaconsSent:beacons];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager time:(double)time sinceSentForCounter:(NSString *)index{
    NSMutableArray *targets = [self.callbacks objectForKey:@"sinceSentForCounter"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:time:sinceSentForCounter:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager time:time sinceSentForCounter:index];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdatePle:(NSInteger)ple andIntercept:(NSInteger)intercept inMaps:(NSArray *)maps at:(NSDate *)dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdatePle"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdatePle:andIntercept:inMaps:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdatePle:ple andIntercept:intercept inMaps:maps at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager requestOutTimeInt:(NSTimeInterval)interval{
    NSMutableArray *targets = [self.callbacks objectForKey:@"requestOutTimeInt"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:requestOutTimeInt:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager requestOutTimeInt:interval];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager requestInTimeIntsHistoric:(NSDictionary *)timeIntsHistoric{
    NSMutableArray *targets = [self.callbacks objectForKey:@"requestInTimeIntsHistoric"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:requestInTimeIntsHistoric:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager requestInTimeIntsHistoric:timeIntsHistoric];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateHeading:(CLHeading *)headingInformation{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateHeading"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateHeading:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateHeading:headingInformation];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateLEHeading:(NSDictionary *)heading{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateLEHeading"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateLEHeading:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateLEHeading:heading];
                }];
            }
        }
    }
}


-(void)mistManager:(MSTCentralManager *)manager restartScan:(NSString *)message{
    NSMutableArray *targets = [self.callbacks objectForKey:@"requestInTimeIntsHistoric"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateHeading:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager restartScan:message];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateStatus:(MSTCentralManagerSettingStatus)isEnabled ofSetting:(MSTCentralManagerSettingType)type{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateStatus"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateStatus:ofSetting:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateStatus:isEnabled ofSetting:type];
                }];
            }
        }
    }
}

#pragma mark -

#pragma mark - MSTProximityDelegate

-(void)didUpdatedBeacons:(NSArray *)beacons{
#ifdef DEBUG
    [[Logger sharedInstance] info:beacons.description];
#endif
}

-(void)didDiscoverBeaconProximityInformation:(NSDictionary *)proximityInformation forLocation:(CGPoint)currentLocation{
    NSLog(@"MSTProximityDelegate single = %@",proximityInformation);
}

-(void)didDiscoverBeaconsProximityInformation:(NSArray *)proximityInformations forLocation:(CGPoint)currentLocation{
    NSLog(@"MSTProximityDelegate all = %@",proximityInformations);
}

#pragma mark -

- (void) dispatchSelector:(SEL)selector target:(id)target objects:(NSArray*)objects onMainThread:(BOOL)onMainThread {
    if(target && [target respondsToSelector:selector]) {
        NSMethodSignature* signature = [target methodSignatureForSelector:selector];
        if(signature) {
            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
            @try {
                [invocation setTarget:target];
                [invocation setSelector:selector];
                
                if (objects) {
                    NSInteger objectsCount	= [objects count];
                    
                    for(NSInteger i = 0; i < objectsCount; i++) {
                        NSObject *obj = [objects objectAtIndex:i];
                        [invocation setArgument:&obj atIndex:i+2];
                    }
                }
                
                if (onMainThread) {
                    [invocation performSelectorOnMainThread:@selector(invoke)
                                                 withObject:nil
                                              waitUntilDone:NO];
                } else {
                    [invocation performSelector:@selector(invoke)
                                       onThread:[NSThread currentThread]
                                     withObject:nil
                                  waitUntilDone:NO];
                }
            } @catch (NSException * e) {
                [e raise];
            } @finally {
                
            }
        }
    }
}

#pragma mark -

#pragma mark - TO CLOUD

-(void)saveClientInformation:(NSDictionary *)payload{
    [self.mstCentralManager saveClientInformation:[payload mutableCopy]];
}

#pragma mark -

#pragma mark - proxy to childViewController

-(void)handleShowWebContent:(NSUInteger)selectedIndex{
    NSMutableArray *targets = [self.callbacks objectForKey:@"handleShowWebContent"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(handleShowWebContent:)]) {
                [target handleShowWebContent:selectedIndex];
            }
        }
    }
}

-(void)displayNotificationForVBID:(NSString *)vbID{
    NSMutableArray *targets = [self.callbacks objectForKey:@"handleShowWebContent"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(handleShowWebContent:)]) {
                [target displayNotificationForVBID:vbID];
            }
        }
    }
}

#pragma mark - Logging and debugging codes below

+(NSUUID *)getMistUUID{
    return [MistIDGenerator getMistUUID];
}

-(void)handleRegisterLockScreenNotification{
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings
                                                                             settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge
                                                                             categories:nil]];
    }
}

-(void)sendLogs:(NSDictionary *)data{
    dispatch_async(dispatch_queue_create("apps-logs", DISPATCH_QUEUE_SERIAL), ^{
        // if remote logging is
        if ([[self.appSettings objectForKey:kEnableRemoteLogging] boolValue]) {
            [self.mstCentralManager sendAppLogs:data];

        }
    });
}

-(void)checkIfLEIsDelayed{
    // increment the seconds that the app doesn't receive back a location
    self.secondsBehind += 1;
    
    // if LE is 2 seconds behind, App will complain
    if (self.secondsBehind > 2) {
        [self sendLogs:@{@"LEISBEHIND":[NSString stringWithFormat:@"Location is behind by %d", self.secondsBehind]}];
    }
}

#pragma mark - Mocking functions

-(id)getTargetsForKey:(NSString *)key{
    return [self.callbacks objectForKey:key];
}

@end
