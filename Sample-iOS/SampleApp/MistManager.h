//
//  MistManager.h
//  Mist
//
//  Created by Mist on 7/1/15.
//  Copyright © 2016 Mist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MistSDK/MistSDK.h>

#define SIM false

/* MistManager - a proxy object for the SDK to interface with other viewControllers */

@interface MistManager : NSObject

@property (nonatomic, strong) NSDictionary *virtualBeacons;
@property (nonatomic, strong) NSMutableArray *zoneEventsMsg;
@property (nonatomic, strong) MSTDeviceClient *client;
@property (nonatomic, strong) NSMutableDictionary *clientInformation;
@property (nonatomic, strong) MSTMap *currentMap;
@property (nonatomic, strong) NSDictionary *lockscreenInfo;

@property (nonatomic, assign) NSString *sessionid;
@property (nonatomic, assign) NSString *csrftoken;
@property (nonatomic, strong) NSString *siteId;
@property (nonatomic, strong) MSTPoint *userLocation;
@property (nonatomic) bool enableUDP;
@property (nonatomic) bool shouldReconnect;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL didAlreadyStart;
@property (nonatomic, strong) NSMutableArray *simulateFuncs;

@property (nonatomic) long virtualAPTestMin;

+(instancetype)sharedInstance;

/**
 *  Connect to the Mist Cloud
 */
-(void)connect;

/**
 *  Disconnect from the Mist Cloud
 */
-(void)disconnect;

/**
 *  Disconect and reconnect only if Mist Cloud is currently connected
 */
-(void)reconnect;

/**
 *  Subscribe to event and pass a target to handle the event
 *
 *  @param event The event to register.
 *  @param target The handler for the event.
 */
-(void)addEvent:(NSString *)event forTarget:(id)target;

/**
 *  Unsubscribe to event and pass a target to handle the event
 *
 *  @param event The event to unregister.
 *  @param target The handler for the event.
 */
-(void)removeEvent:(NSString *)event forTarget:(id)target;

/**
 *  Subscribe to event and pass a target to handle the event
 *
 *  @param event The event to register.
 *  @param target The handler for the event.
 */
-(void)addEvents:(NSArray *)events forTarget:(id)target;

/**
 *  Unsubscribe to event and pass a target to handle the event
 *
 *  @param events The event to unregister.
 *  @param targets The handler for the event.
 */
-(void)removeEvents:(NSArray *)events forTarget:(id)target;

/**
 *  Update the client information
 *
 *  @param payload The payload to save to the client information
 */
-(void)saveClientInformation:(NSDictionary *)payload;

/**
 *  Handle the registration of lock screen notification. Set the enableLockScreenNotification variable and then call this function.
 */
-(void)handleRegisterLockScreenNotification;

#pragma mark - MSTCentralManager features

/**
 * Check if the SDK is still connect, scanning beacons etc. 
 * Use to before attempting to disconnect. It may not be connected.
 */
-(bool) isMSTCentralManagerRunning;

/**
 * Setting the wakeup feature, so SDK can attempt to scan in the background.
 */
-(void) setWakeUpAppSetting:(bool)boolean;

#pragma mark - proxy to childViewController

-(void)handleShowWebContent:(NSUInteger)index;

-(void)displayNotificationForVBID:(NSString *)vbID;

#pragma mark -

- (CLLocationCoordinate2D) getLatitudeLongitudeUsingMapOriginForX: (double) x AndY: (double) y;

/**
 *  Retrieve the current Mist UUID that was used to identify the client.
 *
 *  @return uuid NSUUID
 */
+(NSUUID *)getMistUUID;

-(void)sendLogs:(NSDictionary *)data;

@end
