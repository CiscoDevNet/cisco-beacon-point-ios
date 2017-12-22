//
//  VitrualBeaconViewController.m
//  SampleApp
//
//  Created by Mist on 19/08/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import "VitrualBeaconViewController.h"
#import "MistManager.h"
#import "Default.h"
#import "Toast+UIView.h"
#import "AlertViewCommon.h"
#import "Logger.h"
@interface VitrualBeaconViewController ()
@property (nonatomic, assign) bool isInitialLoad;
@end

@implementation VitrualBeaconViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isInitialLoad = true;
    // Do any additional setup after loading the view.
        [self willActivateVC];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // To connect to Mist SDK
    [[MistManager sharedInstance] addEvent:@"didConnect" forTarget:self];
    [[MistManager sharedInstance] addEvent:@"didReceiveNotificationMessage" forTarget:self];
    //
    
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[MistManager sharedInstance] removeEvent:@"didConnect" forTarget:self];
    [[MistManager sharedInstance] removeEvent:@"didReceiveNotificationMessage" forTarget:self];
    
}

-(void)willActivateVC{

    

    if (self.isInitialLoad) {
        [self startEnv];
        self.isInitialLoad = false;
   
    }
    
    
    //    [self updateIndoorMapView];
}
-(void)startEnv{
    [[Logger sharedInstance]info:@"Starting env"];
    
    if ([MistManager sharedInstance].isMSTCentralManagerRunning) {
        [[MistManager sharedInstance] disconnect];
    }
    
    [[MistManager sharedInstance] connect];
    [AlertViewCommon showStaticHUDMessage:[NSString stringWithFormat:@"Connecting"] inView:self.view];
}

#pragma mark - MSTCentralManagerDelegate

-(void)mistManager:(MSTCentralManager *)manager didConnect:(BOOL)isConnected{
    if (isConnected) {
        [AlertViewCommon hideStaticHUDMessageNow];
    }
}

-(void)mistManager:(MSTCentralManager *)manager didReceiveNotificationMessage:(NSDictionary *)payload{

        NSDictionary *message = [payload objectForKey:@"message"];
        if ([[payload objectForKey:@"type"] isEqualToString:@"zones-events"]) {
            [self handleZoneEvents:message];
        }
        if ([[payload objectForKey:@"type"] isEqualToString:@"zone-event-vb"]) {
            [self handleZoneVBEvents:message];
        }
}


#pragma mark Methods
/* Showing Virtual Beacon Notification Messages */
-(void)handleZoneVBEvents:(NSDictionary *)payload{
    NSString *name = [[payload objectForKey:@"UserID"] substringWithRange:(NSRange){0,5}];
    name = [NSString stringWithFormat:@"%@'s",name];
    if ([[Default getUUIDString] isEqualToString:[payload objectForKey:@"UserID"]]) {
        name = @"You're";
    }
    
    
    NSDictionary *vb;
    @synchronized ([[MistManager sharedInstance] virtualBeacons]) {
        NSDictionary *vbs = [[MistManager sharedInstance] virtualBeacons];
        vb = [[vbs objectForKey:[payload objectForKey:@"vbID"]] copy];
    }
    NSString *msg;
    
        if (![Default isEmptyString:[vb objectForKey:@"message"]]) {
            msg = [vb objectForKey:@"message"];
        } else {
            msg = [NSString stringWithFormat:@"%@ %@ %@",
                   name,
                   @"near",
                   [payload objectForKey:@"Extra"]];
        }
    NSLog(@"%@",msg);
    
//    [Default performBlockOnMainThread:^{
//        self.vbnotificationtextView.text = msg;
//    } ];
    
}

#pragma mark Zone Notification

-(void)handleZoneEvents:(NSDictionary *)payload{
    NSString *name = [[payload objectForKey:@"UserID"] substringWithRange:(NSRange){0,5}];
    name = [NSString stringWithFormat:@"%@'s",name];
    if ([[Default getUUIDString] isEqualToString:[payload objectForKey:@"UserID"]]) {
        name = @"You're";
    }
    
    NSString *msg = [NSString stringWithFormat:@"%@ %@ %@",
                     name,
                     [payload objectForKey:@"Trigger"],
                     [payload objectForKey:@"Extra"]
                     ];
    
//  [self.view makeToast:msg];
    
    [Default performBlockOnMainThread:^{
    self.zoneNotificationTextView.text = msg;
    }];


}




/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
