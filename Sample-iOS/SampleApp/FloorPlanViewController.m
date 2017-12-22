//
//  FloorPlanViewController.m
//  SampleApp
//
//  Created by Mist on 17/08/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import "FloorPlanViewController.h"
#import "MistManager.h"
#import "AlertViewCommon.h"
#import "Logger.h"
#import "Default.h"
#import "Toast+UIView.h"
#import "MSTWayfinder.h"
#import "MotionCommon.h"
#import "DistanceCommon.h"

#define kSnapToPathThresholdDistance 2.5
#define kHysteresisToGoOffpath 5
#define TURN_THRESHOLD 30

@interface FloorPlanViewController ()< MSTFloorViewDelegate, MSTWayfinderDelegate,UIGestureRecognizerDelegate,CLLocationManagerDelegate>{
    NSLayoutConstraint *widthConstraint;
    NSLayoutConstraint *heightConstraint;
    UITapGestureRecognizer *_doubleTap;
    UIPanGestureRecognizer *_pan;
    UIPinchGestureRecognizer *_pinch;
    UIRotationGestureRecognizer *_rotation;
    bool _allowPan;
}
@property (nonatomic, assign) bool isInitialLoad;
@property (nonatomic, strong) NSString *currentMapName;
@property (nonatomic, strong) NSMutableDictionary *appSettings;
@property (nonatomic, strong) MSTWayfinder       *indoorMapView;
@property (nonatomic, strong) NSMutableDictionary *nodes;
@property (nonatomic, strong) MSTMap *currentMap;
@property (nonatomic, strong) NSMutableArray *dots;
@property (nonatomic, strong) MSTGraph *graph;
@property (nonatomic, strong) NSMutableDictionary *maps;
@property (nonatomic) CGPoint prevFVPoint;
@property (nonatomic, strong) NSMutableArray *currentWaypathArray;
@property (nonatomic, assign) bool addedWayfinding;
@property (nonatomic, strong) CLHeading *headingInformation;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) int numOfTimesOffPath;
@end

@implementation FloorPlanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.currentMapName = @"";
    self.isInitialLoad = true;
    self.maps = [[NSMutableDictionary alloc] init];
    
    self.dots = [[NSMutableArray alloc] init];
    
    _prevFVPoint = CGPointZero;
    [self willActivateVC];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    if ([self.locationManager respondsToSelector:@selector
         (requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    if ([self.locationManager respondsToSelector:@selector
         (requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    
    
    _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
    _doubleTap.numberOfTapsRequired = 2;
    [self.mainFlrView addGestureRecognizer:_doubleTap];
    
    _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    _pan.delegate = self;
    _allowPan = true;
    [self.mainFlrView addGestureRecognizer:_pan];
    
    _pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinch:)];
    _pinch.delegate = self;
    [self.mainFlrView addGestureRecognizer:_pinch];

}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // To connect to Mist SDK
    [[MistManager sharedInstance] addEvent:@"didConnect" forTarget:self];

    [[MistManager sharedInstance] addEvent:@"willUpdateLocation" forTarget:self];
    //
    [[MistManager sharedInstance] addEvent:@"didUpdateMap" forTarget:self];
    [[MistManager sharedInstance] addEvent:@"didUpdateLocation" forTarget:self];
    //
    [[MistManager sharedInstance] addEvent:@"willUpdateRelativeLocation" forTarget:self];
    
    //
    [[MistManager sharedInstance] addEvent:@"didUpdateRelativeLocation" forTarget:self];
    [[MistManager sharedInstance] addEvent:@"didUpdateHeading" forTarget:self];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
   
    [[MistManager sharedInstance] removeEvent:@"didConnect" forTarget:self];
    [[MistManager sharedInstance] removeEvent:@"didUpdateMap" forTarget:self];
    [[MistManager sharedInstance] removeEvent:@"willUpdateRelativeLocation" forTarget:self];
    [[MistManager sharedInstance] removeEvent:@"didUpdateRelativeLocation" forTarget:self];
    [[MistManager sharedInstance] removeEvent:@"didUpdateHeading" forTarget:self];
    [[MistManager sharedInstance] removeEvent:@"didUpdateLocation" forTarget:self];
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


-(void)willActivateVC{
    self.appSettings = [Default currentSettings];
    
    if (self.isInitialLoad) {
        [self startEnv];
        self.isInitialLoad = false;
    }

}

-(void)startEnv{

    
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

-(void)mistManager:(MSTCentralManager *)manager didReceivedVirtualBeacons:(NSDictionary *)virtualBeacons{

}

-(void)mistManager:(MSTCentralManager *)manager didUpdateMap:(MSTMap *)map at:(NSDate *)dateUpdated{
    [Default performBlockOnMainThread:^{
        [self performMapDidUpdate:map];
    }];
}

-(void)mistManager:(MSTCentralManager *)manager willUpdateRelativeLocation:(MSTPoint *)relativeLocation inMaps:(NSArray *)maps at:(NSDate *)dateUpdated{
    //    NSLog(@"homevc willUpdateRelativeLocation");
    
    [Default performBlockOnMainThread:^{
        [self.view makeToast:@"Received relative location. Fetching map data."];
    }];
}

-(void)mistManager:(MSTCentralManager *)manager willUpdateLocation:(CLLocationCoordinate2D)location inMaps:(NSArray *)maps withSource:(SourceType)locationSource at:(NSDate *)dateUpdated{
    //    NSLog(@"homevc willUpdateLocation");
}
-(void)mistManager:(MSTCentralManager *)manager didUpdateLocation:(CLLocationCoordinate2D)location inMaps:(NSArray *)maps withSource:(SourceType)locationSource at:(NSDate *)dateUpdated{
    
    //    MSTMap *map = [maps lastObject];
    //    NSString *msg = [NSString stringWithFormat:@"    didUpdateLocation = %f %f in map = %@ [%f %f] source = %ld",location.latitude,location.longitude,map.mapId,map.mapOrigin.latitude,map.mapOrigin.longitude,locationSource];
    //    NSLog(@"homevc didUpdateLocation = %@",msg);
    
    
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateRelativeLocation:(MSTPoint *)cloudPoint inMaps:(NSArray *)maps at:(NSDate *)dateUpdated{
        MSTMap *map = [maps lastObject];
    
        [Default performBlockOnMainThread:^{
            
            switch (map.mapType) {
                case MapTypeGOOGLE:{
                    
                    
                }
                case MapTypeIMAGE:{
                    if (self.indoorMapView.superview) { // if the floorplan is being displayed
                        
                        // if the new mapID is different from the currentMapID show the new map
                        if (![self.currentMap.mapId isEqualToString:map.mapId]) {
                            self.currentMap = map;
                            [self addIndoorMap:self.currentMap];
                            if (self.currentMap.wayfindingPath && [self.currentMap.wayfindingPath isKindOfClass:[NSDictionary class]]) {
                                [self loadWayfindingData:self.currentMap.wayfindingPath];
                            }
                        }
                        
                        bool donotRenderFloorplanFeatures = false;
                        if (!donotRenderFloorplanFeatures) {
                            /************** Draw blue dot **************/
                            [[MistManager sharedInstance] sendLogs:@{@"beforeMotion":[NSString stringWithFormat:@"%@",cloudPoint]}];
                            
                            NSDictionary *result = [[MotionCommon sharedInstance] handleMotion:cloudPoint];
                            
                            [[MistManager sharedInstance] sendLogs:@{@"afterMotion":[NSString stringWithFormat:@"%@",result]}];
                            
                            MSTPoint *leEst = (MSTPoint *)result[@"point"];
                            CGPoint leEstCGPoint = [self.indoorMapView scaleUpPoint:[self.indoorMapView convertMetersToPixels:[leEst convertToCGPoint]]];;
                            
                            if (leEst.type == MSTPointTypeLE) {
                                
                                [[MistManager sharedInstance] sendLogs:@{@"renderLE":[NSString stringWithFormat:@"%@",leEst]}];
                                
                                [self.indoorMapView drawDotViewAtCGPoint:leEstCGPoint forIndex:0
                                                              shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                        shouldShowMotion:[[result objectForKey:@"showYellow"] boolValue]];
                            }
                            if (leEst.type == MSTPointTypeDR) {
                                
                                [[MistManager sharedInstance] sendLogs:@{@"renderDR":[NSString stringWithFormat:@"%@",leEst]}];
                                
                                [self.indoorMapView drawDotViewAtCGPoint:leEstCGPoint forIndex:0
                                                              shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                               withColor:[UIColor redColor]];
                            }
                            
                            if (leEst.type == MSTPointTypeLast) {
                                
                                // logging last dot
                                [[MistManager sharedInstance] sendLogs:@{@"renderLast":[NSString stringWithFormat:@"%@",leEst]}];
                                
                                // draw the bluedot using dead-reckoning
                                [Default performBlockOnMainThread:^{
                                    [self.indoorMapView drawDotViewAtCGPoint:leEstCGPoint forIndex:0
                                                                  shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                                   withColor:[UIColor colorWithRed:0.7271 green:0.7271 blue:0.7271 alpha:1.0]];
                                }];
                            }
                            
                            /****************************/
                            
                            /************** Draw Wayfinding **************/
                            /****************************/
                            
                            
                            if (self.addedWayfinding) {
                                
                                // Convert relative point to indoorMapView point
                                CGPoint fvPoint = [self.indoorMapView getFloorviewPointFromCloudPoint:CGPointMake(leEst.x, leEst.y)];
                                
                                
                                // Snap to path
                                CGPoint startingFVPoint;
                                
                                if (snapToPathSwitch.isOn) {
                                    
                                    CGPoint stpPoint = [self.indoorMapView closestPointOnAllPaths:fvPoint];
                                    startingFVPoint = stpPoint;
                                    
                                    // SNAP TO PATH 2.0
                                    if ((_prevFVPoint.x != 0 && _prevFVPoint.y != 0) && (_prevFVPoint.x != stpPoint.x) && (_prevFVPoint.y != stpPoint.y)) {
                                        
                                        // Scans ahead for any corners and save them into cornersBetweenTwoPoints
                                        NSMutableArray *cornersBetweenTwoPoints = [self.indoorMapView pointsBetweenPoint:stpPoint andPoint:_prevFVPoint];
                                        
                                        [Default performBlockOnMainThread:^{
                                            
                                            //                                        NSLog(@"cornersBetweenTwoPoints = %@ from %@ to %@",cornersBetweenTwoPoints, NSStringFromCGPoint(stpPoint), NSStringFromCGPoint(_prevFVPoint));
                                            
                                            // if there are corner points between current stp point and previous stp point, walk the corners
                                            if (cornersBetweenTwoPoints.count > 0) {
                                                
                                                // walk the corners the corners
                                                [cornersBetweenTwoPoints enumerateObjectsUsingBlock:^(NSString *cornerPoint, NSUInteger idx, BOOL * _Nonnull stop) {
                                                    dispatch_async(dispatch_queue_create("com.mist.mist.stp", DISPATCH_QUEUE_SERIAL), ^{
                                                        
                                                        if (idx % 2) {
                                                            //                                                        [self renderDebugSTPPoints:cornerPoint]; // DEBUG for STP2.0
                                                            
                                                            CGPoint p1 = [self.indoorMapView getCloudPointFromFloorviewPoint:fvPoint];
                                                            CGPoint p2 = [self.indoorMapView getCloudPointFromFloorviewPoint:stpPoint];
                                                            double distance = [DistanceCommon distanceBetweenPoint:p1 andPoint:p2];
                                                            
                                                            // if the distance between the raw dot and the stp dot is within kSnapToPathThresholdDistance, snap it onto the path
                                                            if (distance < kSnapToPathThresholdDistance) {
                                                                
                                                                [Default performBlockOnMainThread:^{
                                                                    [self.indoorMapView drawSnapToPathUsingCGPoint:CGPointFromString(cornerPoint)
                                                                                                        shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                                                                      withDuration:0.5];
                                                                }];
                                                            } else { // otherwise let the client walk on the raw dot
                                                                
                                                                // user is consistently off path, let them go off path after kHysteresisToGoOffpath
                                                                if (_numOfTimesOffPath > kHysteresisToGoOffpath) {
                                                                    
                                                                    [Default performBlockOnMainThread:^{
                                                                        [self.indoorMapView drawSnapToPathUsingCGPoint:fvPoint
                                                                                                            shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                                                                          withDuration:0.5];
                                                                    }];
                                                                } else { // if the user hasn't reached hysteresis
                                                                    _numOfTimesOffPath++;
                                                                    
                                                                    [Default performBlockOnMainThread:^{
                                                                        [self.indoorMapView drawSnapToPathUsingCGPoint:CGPointFromString(cornerPoint)
                                                                                                            shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                                                                          withDuration:0.5];
                                                                    }];
                                                                }
                                                            }
                                                        }
                                                    });
                                                }];
                                                
                                            } else { // if there aren't corner points, snap the client to the nearest point on the path
                                                
                                                CGPoint p1 = [self.indoorMapView getCloudPointFromFloorviewPoint:fvPoint];
                                                CGPoint p2 = [self.indoorMapView getCloudPointFromFloorviewPoint:stpPoint];
                                                double distance = [DistanceCommon distanceBetweenPoint:p1 andPoint:p2];
                                                
                                                // if the distance between the raw dot and the stp dot is within kSnapToPathThresholdDistance, snap it onto the path
                                                if (distance < kSnapToPathThresholdDistance) {
                                                    _numOfTimesOffPath = 0; // once the user is within the distance of the path, reset the num of times they can go off road
                                                    
                                                    [Default performBlockOnMainThread:^{
                                                        [self.indoorMapView drawSnapToPathUsingCGPoint:stpPoint
                                                                                            shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                                                          withDuration:0.5];
                                                    }];
                                                } else { // otherwise let the client walk on the raw dot
                                                    
                                                    // user is consistently off path, let them go off path after kHysteresisToGoOffpath
                                                    if (_numOfTimesOffPath > kHysteresisToGoOffpath) {
                                                        
                                                        [Default performBlockOnMainThread:^{
                                                            [self.indoorMapView drawSnapToPathUsingCGPoint:fvPoint
                                                                                                shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                                                              withDuration:0.5];
                                                        }];
                                                    } else { // if the user hasn't reached hysteresis, snap them on the path
                                                        _numOfTimesOffPath++;
                                                        
                                                        [Default performBlockOnMainThread:^{
                                                            [self.indoorMapView drawSnapToPathUsingCGPoint:stpPoint
                                                                                                shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                                                              withDuration:0.5];
                                                        }];
                                                    }
                                                }
                                            }
                                        }];
                                        
                                    } else { // if previous stp point is not available, behave like STP 1.0
                                        
                                        CGPoint p1 = [self.indoorMapView getCloudPointFromFloorviewPoint:fvPoint];
                                        CGPoint p2 = [self.indoorMapView getCloudPointFromFloorviewPoint:stpPoint];
                                        double distance = [DistanceCommon distanceBetweenPoint:p1 andPoint:p2];
                                        
                                        // if the distance between the raw dot and the stp dot is within kSnapToPathThresholdDistance, snap it onto the path
                                        if (distance < kSnapToPathThresholdDistance) {
                                            _numOfTimesOffPath = 0; // once the user is within the distance of the path, reset the num of times they can go off road
                                            
                                            [Default performBlockOnMainThread:^{
                                                [self.indoorMapView drawSnapToPathUsingCGPoint:stpPoint
                                                                                    shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                                                  withDuration:0.5];
                                            }];
                                        } else { // otherwise let the client walk on the raw dot
                                            
                                            // user is consistently off path, let them go off path after kHysteresisToGoOffpath
                                            if (_numOfTimesOffPath > kHysteresisToGoOffpath) {
                                                
                                                [Default performBlockOnMainThread:^{
                                                    [self.indoorMapView drawSnapToPathUsingCGPoint:fvPoint
                                                                                        shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                                                      withDuration:0.5];
                                                }];
                                            } else { // if the user hasn't reached hysteresis, snap them on the path
                                                _numOfTimesOffPath++;
                                                
                                                [Default performBlockOnMainThread:^{
                                                    [self.indoorMapView drawSnapToPathUsingCGPoint:stpPoint
                                                                                        shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                                                                      withDuration:0.5];
                                                }];
                                            }
                                        }
                                    }
                                    
                                    
                                    //                                [self cleanupDebugSTPPoints]; // DEBUG for STP2.0
                                    _prevFVPoint = stpPoint;
                                    
                                    /**
                                     *  If the distance is less than the threshold snap the bluedot to the path, otherwise render the bluedot
                                     */
                                    // OLD SNAP TO PATH
                                    //                                CGPoint p1 = [self.indoorMapView getCloudPointFromFloorviewPoint:fvPoint];
                                    //                                CGPoint p2 = [self.indoorMapView getCloudPointFromFloorviewPoint:stpPoint];
                                    //                                double distance = [DistanceCommon distanceBetweenPoint:p1 andPoint:p2];
                                    //                                if (distance < kSnapToPathThresholdDistance) {
                                    //                                    startingFVPoint = stpPoint;
                                    //                                    [self.indoorMapView drawSnapToPath:stpPoint
                                    //                                                            shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                    //                                                      shouldShowMotion:[[result objectForKey:@"showYellow"] boolValue]];
                                    //                                } else {
                                    //                                    startingFVPoint = fvPoint; // use the bluedot
                                    //                                    [self.indoorMapView drawSnapToPath:fvPoint
                                    //                                                            shouldMove:[[result objectForKey:@"canMove"] boolValue]
                                    //                                                      shouldShowMotion:[[result objectForKey:@"showYellow"] boolValue]];
                                    //                                }
                                    
                                    
                                } else {
                                    [Default performBlockOnMainThread:^{
                                        [self.indoorMapView removeSnapToPath];
                                    }];
                                    startingFVPoint = fvPoint; // use the bluedot
                                }
                                
                                // Begin wayfinding
                                if (self.indoorMapView.isWayfindingEnabled) {
                                    
                                    [[MistManager sharedInstance] sendLogs:@{@"renderWayfinding":[NSString stringWithFormat:@"%@",NSStringFromCGPoint(startingFVPoint)]}];
                                    
                                    [Default performBlockOnMainThread:^{
                                        [self.indoorMapView setOriginNodeUsingPoint:startingFVPoint]; // set the starting point for the wayfinding path
                                    }];
                                    
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L), ^{
                                        CGPathRef path = [self.indoorMapView renderWayfinding2];
                                        if (path != NULL) {
                                            CGPathRetain(path);
                                            [Default performBlockOnMainThread:^{
                                                [self.indoorMapView drawWayUsingPath:path enable:true];
                                                CGPathRelease(path);
                                            }];
                                        }
                                    });
                                }
                                
                                // Begin navigation
                                //                            if (self.indoorMapView.isNavigationEnabled) {
                                //                                [self.indoorMapView setOriginNodeUsingPoint:startingFVPoint];
                                //                                [self.indoorMapView navigateToPoint:startingFVPoint];
                                //                                [self.indoorMapView renderWayfinding];
                                //                            }
                            }
                        }
                    } else {
                        self.currentMap = map;
                        [self addIndoorMap:self.currentMap];
                        if (self.currentMap.wayfindingPath && [self.currentMap.wayfindingPath isKindOfClass:[NSDictionary class]]) {
                            [self loadWayfindingData:self.currentMap.wayfindingPath];
                        }
                    }
                    break;
                }
                default:
                    break;
            }
            
//            [self bringHUDToFront];
            
        }];
        

}

-(void)mistManager:(MSTCentralManager *)manager didUpdateHeading:(CLHeading *)headingInfo{
    self.headingInformation = headingInfo;
    [Default performBlockOnMainThread:^{
        
        // draw the heading flashlight
        [self.indoorMapView drawHeading:self.headingInformation forIndex:0];
        
        if (self.indoorMapView.isOrientMapBasedOnHeading) {
            // draw the map orientation
            if (self.indoorMapView.map.orientation != -1) { // if the orientation is set in the API, use it
                [self.indoorMapView orientFloormapBasedOnHeading:-headingInfo.trueHeading];
            } else {
                NSString *orientation = [self.appSettings objectForKey:@"orientation"];
                if (orientation) { // if the user has set the orientation locally, use it
                    CGFloat offset = [orientation floatValue];
                    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                        self.indoorMapView.layer.transform = CATransform3DMakeRotation((-headingInfo.trueHeading+offset)*M_PI/180, 0, 0, 1);
                    } completion:^(BOOL finished) {
                        
                    }];
                } else { // if no orientation is set then do nothing
                    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                        self.indoorMapView.layer.transform = CATransform3DMakeRotation((-headingInfo.trueHeading)*M_PI/180, 0, 0, 1);
                    } completion:nil];
                }
            }
        } else {
            //            self.indoorMapView.layer.transform = CATransform3DIdentity;
        }
        
        // draw heading for snaptopath dot
        if (snapToPathSwitch.isOn) {
            [self.indoorMapView drawHeading:self.headingInformation forKey:@"snap"];
        };
        
        if (snapToPathSwitch.isOn) {
            [self.indoorMapView drawHeading:self.headingInformation forKey:@"snap2"];
        };
    }];
}

#pragma mark - MSTFloorViewDelegate

-(MSTLocationView *)bluedotViewForFloorView:(MSTFloorView *)indoorMapView{
    MSTLocationView *locationView = [[MSTLocationView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    [locationView start];
    locationView.isMainDot = true;
    return locationView;
}

-(bool)canShowFloorViewDots:(MSTFloorView *)indoorMapView forIndex:(NSUInteger)index{
    return true;
}

-(NSUInteger)numOfDotsInFloorview:(MSTFloorView *)indoorMapView{
    NSUInteger num;
    @synchronized (self.dots) {
        num = self.dots.count;
    }
    return num;
}

-(NSArray *)dotsInFloorView:(MSTFloorView *)indoorMapView{
    NSArray *dots;
    @synchronized (self.dots) {
        dots = [NSArray arrayWithArray:self.dots];
    }
    return dots;
}

#pragma mark - MSTWayfinderDelegate

- (NSMutableDictionary *)nodesForWayfinder{
    return self.nodes;
}

- (MSTGraph *)graphForWayfinder{
    return self.graph;
}

- (void)receivedPoint:(CGPoint)point{
    NSLog(@"receivedPoint = %@",NSStringFromCGPoint(point));
}

- (void)receivedOutsidePoint:(CGPoint)point{
    NSLog(@"receivedOutsidePoint = %@",NSStringFromCGPoint(point));
}

- (void)wayfinding:(MSTWayfinder *)hasTurnedOffNavigation{
    //    _actionsView
}


#pragma mark -- Methods

-(void)performMapDidUpdate:(MSTMap *)map{
    if (map) {
        // You are Indoor
        [self.view makeToast:[NSString stringWithFormat:@"You are in %@",map.mapName]];
  
    } else {
       // You are out of tracking Zone  or Outdoor
        [self.view makeToast:@"You are OutDoor"];
    }

}


-(void)addIndoorMap:(MSTMap *)map{
    if (map.mapImage) {
        NSLog(@"    adding map and image = %@",map.mapImage);
        
        // If other subviews are there, remove the subviews and start over
//        if (self.view.subviews.count > 0) {
//            for (UIView *subview in self.view.subviews) {
//                [subview removeFromSuperview];
//            }
//        }
        
        self.indoorMapView = [[MSTWayfinder alloc] initWithFrame:self.mainFlrView.bounds];
        [self.indoorMapView setBackgroundColor:[UIColor whiteColor]];
        self.indoorMapView.map = map;
        self.indoorMapView.showNodeLabel = false;
        self.indoorMapView.showNodeVertices = true;
        self.indoorMapView.wayFinderDelegate = self;
        self.indoorMapView.delegate = self;
        
        if (map.wayfindingPath && [[map.wayfindingPath objectForKey:@"coordinate"] isEqualToString:@"actual"]) {
            self.indoorMapView.usePPM = false; // use px
        } else {
            self.indoorMapView.usePPM = true; // use meter
        }
        
            self.indoorMapView.maxBreadcrumb = 0;

        self.indoorMapView.alpha = 0;
        [self.mainFlrView addSubview:self.indoorMapView];
        [self.indoorMapView start];
        [self.indoorMapView setTranslatesAutoresizingMaskIntoConstraints:false];
        [self.mainFlrView addConstraint:[NSLayoutConstraint constraintWithItem:self.indoorMapView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.mainFlrView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [self.mainFlrView addConstraint:[NSLayoutConstraint constraintWithItem:self.indoorMapView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.mainFlrView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        CGFloat floorViewRatio = self.indoorMapView.bounds.size.width/self.indoorMapView.bounds.size.height;
        CGFloat imageRatio = map.mapImage.size.width/map.mapImage.size.height;
        if (imageRatio >= floorViewRatio) {
            widthConstraint = [NSLayoutConstraint constraintWithItem:self.indoorMapView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.mainFlrView.bounds.size.width-10];
            heightConstraint = [NSLayoutConstraint constraintWithItem:self.indoorMapView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.indoorMapView attribute:NSLayoutAttributeWidth multiplier:self.currentMap.mapImage.size.height/self.currentMap.mapImage.size.width constant:0];
        } else {
            widthConstraint = [NSLayoutConstraint constraintWithItem:self.indoorMapView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.mainFlrView.bounds.size.height-10];
            heightConstraint = [NSLayoutConstraint constraintWithItem:self.indoorMapView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.indoorMapView attribute:NSLayoutAttributeHeight multiplier:self.currentMap.mapImage.size.width/self.currentMap.mapImage.size.height constant:0];
        }
        
        [self.mainFlrView addConstraint:widthConstraint];
        [self.mainFlrView addConstraint:heightConstraint];
        

        
        [UIView animateWithDuration:0.5 animations:^{
            self.indoorMapView.alpha = 1;
        } completion:^(BOOL finished) {
            // Draw the skeleton
            [self.indoorMapView drawBackgroundGraph:self.nodes];
             if (showPathSwitch.isOn) {
                self.indoorMapView.showSkeletonView = true;
            } else {
                self.indoorMapView.showSkeletonView = false;
            }
            [self.indoorMapView reloadUI];
//            if (!self.renderedVirtualBeacons) {
//                [self renderVirtualBeacons];
//                if (!self.showAllVirtualBeacons) {
//                    [self showVirtualBeacon:self.showVirtualBeaconID];
//                }
//                self.renderedVirtualBeacons = true;
//            }
        }];
        

        [self updateIndoorMapView];
    }
}


-(void)updateIndoorMapView{
    // Show paths
    if (showPathSwitch.isOn) {
        self.indoorMapView.showSkeletonView = true;
    } else {
        self.indoorMapView.showSkeletonView = false;
    }
    
    if (wayFindingSwitch.isOn) {
        [self.indoorMapView turnOnWayfinding];
    } else {
        [self.indoorMapView turnOffWayfinding];
    }
    
        //[self.indoorMapView turnOnMapOrientationBasedOnHeading];

    
    if (snapToPathSwitch.isOn) {
        if (![self.indoorMapView hasSnaptoPathDot]) {
            MSTLocationView *locationView = [[MSTLocationView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
            [locationView start];
            [self.indoorMapView setSnaptoPathDot:locationView];
        }
    }
    
    if (snapToPathSwitch.isOn) {
        if (![self.indoorMapView hasSnaptoPathDot2]) {
            MSTLocationView *locationView = [[MSTLocationView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
            [locationView start];
            [self.indoorMapView setSnaptoPathDot2:locationView];
        }
    }
    [self.indoorMapView resetFloorplan];
    [self.indoorMapView reloadUI];
}


-(void)removeIndoorMapView{
    [self.indoorMapView removeFromSuperview];
    self.indoorMapView = nil;
}

-(void)loadWayfindingData:(NSDictionary *)mapJSON{
    if ([mapJSON isKindOfClass:[NSDictionary class]] && [mapJSON objectForKey:@"nodes"] && [mapJSON objectForKey:@"coordinate"] && [mapJSON objectForKey:@"name"]) {
        NSArray *nodesFromFile = [mapJSON objectForKey:@"nodes"];
        NSLog(@"nodes = %@",nodesFromFile);
        
        self.currentWaypathArray = [[NSMutableArray alloc] init];
        
        self.graph = [[MSTGraph alloc] init];
        self.nodes = [[NSMutableDictionary alloc] init];
        
        for (NSDictionary *aNode in nodesFromFile) {
            CGFloat x = [aNode[@"position"][@"x"] doubleValue];
            CGFloat y = [aNode[@"position"][@"y"] doubleValue];
            [self.nodes setObject:[[MSTNode alloc] initWithName:aNode[@"name"] andPoint:CGPointMake(x,y) andEdges:aNode[@"edges"]] forKey:aNode[@"name"]];
        }
        for (NSString *key in self.nodes) {
            MSTNode *node = self.nodes[key];
            [self calculateEdgeDistanceForNode:node];
            [self.graph addVertex:node.nodeName withEdges:node.edges];
        }
        self.addedWayfinding = true;
    }
}
-(void)calculateEdgeDistanceForNode:(MSTNode *)node{
    NSMutableDictionary *tempEdge = [[NSMutableDictionary alloc] init];
    for (NSString *nodeName in node.edges) {
        MSTNode *otherNode = [self.nodes objectForKey:nodeName];
        double x = pow(node.nodePoint.x-otherNode.nodePoint.x, 2)+pow(node.nodePoint.y-otherNode.nodePoint.y, 2);
        double d = sqrt(x);
        [tempEdge setObject:[NSString stringWithFormat:@"%lf",d] forKey:nodeName];
    }
    node.edges = [tempEdge mutableCopy];
}



#pragma UIGestureDelegate
-(void)didDoubleTap:(UITapGestureRecognizer *)sender{
    if (self.indoorMapView != nil) {
        [self.indoorMapView resetFloorplan];
    }
}

-(void)didPan:(UIPanGestureRecognizer *)sender{
    if (_allowPan) {
        if (self.indoorMapView != nil) {
            [self.indoorMapView performPan:sender];
        }
    }
}

-(void)didRotate:(UIRotationGestureRecognizer *)sender{
    if (self.indoorMapView != nil) {
        [self.indoorMapView performRotate:sender];
    }
}

-(void)didPinch:(UIPinchGestureRecognizer *)sender{
    if (sender.state == UIGestureRecognizerStateBegan) {
        _allowPan = false;
        if (self.indoorMapView != nil) {
            [self.indoorMapView performPinch:sender];
        }
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        if (self.indoorMapView != nil) {
            [self.indoorMapView performPinch:sender];
        }
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        _allowPan = true;
    } else if (sender.state == UIGestureRecognizerStateCancelled) {
        NSLog(@"canceled");
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return true;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touchesBegan");
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touchesEnded");
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touchesMoved");
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touchesCancelled");
}


- (IBAction)snapToPathToggle:(id)sender {

    [self updateIndoorMapView];
}

- (IBAction)allPathToggle:(id)sender {
  [self updateIndoorMapView];
}

- (IBAction)wayfindingToggle:(id)sender {
  [self updateIndoorMapView];
}
@end
