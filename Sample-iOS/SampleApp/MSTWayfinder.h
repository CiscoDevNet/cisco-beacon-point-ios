//
//  MSTWayfinder.h
//  Mist
//
//  Created by Cuong Ta on 7/23/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import <MistSDK/MistSDK.h>
#import "MSTFloorView.h"
#import "MSTNode.h"
#import "MSTGraph.h"

@protocol MSTWayfinderDelegate;

@interface MSTWayfinder : MSTFloorView

@property (nonatomic, strong) UIView *wayfindingPathView;
@property (nonatomic, strong) UIView *pathView;
@property (nonatomic, strong) UIView *dotsView;
@property (nonatomic, strong) UIView *wayfindingPaths;
@property (nonatomic, strong) UIView *beaconViews;
@property (nonatomic) id <MSTWayfinderDelegate> wayFinderDelegate;
@property (nonatomic, strong) CAShapeLayer *wayPath;
@property (nonatomic) bool showNodeVertices;
@property (nonatomic) bool showNodeLabel;
@property (nonatomic) bool showSkeletonView;
@property (nonatomic) bool usePPM; // if the x,y position of the nodes are actual image (ie in pixels), no need to convert to use ppm to convert to meters
@property (nonatomic) bool isWayfindingEnabled;
@property (nonatomic) bool isSnapToPathEnabled;
@property (nonatomic) bool isOrientMapBasedOnHeading;

-(instancetype)init;

-(double)scaleXFactor;
-(double)scaleYFactor;

// Drawing the view
-(void)drawWayUsingPath:(CGPathRef)path enable:(bool)enable;
-(void)undrawBackgroundGraph;
-(void)drawBackgroundGraph:(NSDictionary *)graph;

-(bool)addDot:(UIView *)view forKey:(NSString *)key;
-(void)removeDotForKey:(NSString *)key;

-(void)drawHeading:(CLHeading *)headingInfo forKey:(NSString *)key;

-(void)turnOnMapOrientationBasedOnHeading;
-(void)turnOffMapOrientationBasedOnHeading;
-(void)orientFloormapBasedOnHeading:(CGFloat)headingInfo;

-(void)centerView;

/**
 *  Deprecated. Please use hasSnaptoPathDot and setSnaptoPathDot
 */
-(void)addSnaptoPathDot:(MSTLocationView *)view;

/**
 *  Checks to see if the STP exists
 *
 *  @return True if exist, false otherwise
 */
-(bool)hasSnaptoPathDot;

/**
 *  Override the existing STP view
 *
 *  @param view 
 */
-(void)setSnaptoPathDot:(MSTLocationView *)view;



/**
 *  New STP algorithm
 */
-(bool)hasSnaptoPathDot2;

-(void)setSnaptoPathDot2:(MSTLocationView *)view;




-(void)drawSnapToPath:(CGPoint)point shouldMove:(bool)move shouldShowMotion:(bool)showMotion;

-(void)drawSnapToPathUsingCGPoint:(CGPoint)point shouldMove:(bool)canMove withDuration:(NSTimeInterval)duration;

-(void)removeSnapToPath;

// Calculations
-(CGPathRef)getWaypath:(NSArray *)path fromGraph:(NSDictionary *)graph; // deprecate

-(CGPoint)closestPointOnAllPaths:(CGPoint)point;

-(NSMutableArray *)pointsBetweenPoint:(CGPoint)p1 andPoint:(CGPoint)p2;

-(void)reloadUI;

/*
 Calls this method to turn on wayfinding
 */
-(void)turnOnWayfinding;

/*
 Calls this method to turn off wayfinding
 */
-(void)turnOffWayfinding;

/*
 Calls this method to render the wayfinding path without turning on manual wayfinding
 */
-(void)renderWayfinding;

/**
 *  Call this method to render the wayfinding path without turning on manual wayfinding
 *
 *  @return returns the path. Not retained
 */
-(CGPathRef)renderWayfinding2;

/**
 *  Call this method to render the wayfinding path from point 1 to point 2 on demand 😎
 *
 *  @param p1 starting floorview point
 *  @param p2 ending floorview point
 *
 *  @return the path
 */
-(CGPathRef)renderWayfindingFromPoint:(CGPoint)p1 toPoint:(CGPoint)p2;

/*
 Calls this method to stop wayfinding and remove all the paths
 */
-(void)stopWayfinding;

// Set the starting position for wayfinding
-(void)setOriginNodeUsingPoint:(CGPoint)point;
-(void)setDestinationNodeUsingPoint:(CGPoint)point;

// Utility
-(CGPoint)convertToOutsidePointFromPoint:(CGPoint)point;
-(CGPoint)convertToInsidePointFromPoint:(CGPoint)point;

-(void)resetFloorplan;
-(void)performPan:(UIPanGestureRecognizer *)sender;
-(void)performRotate:(UIRotationGestureRecognizer *)sender;
-(void)performPinch:(UIPinchGestureRecognizer *)sender;

@end

@protocol MSTWayfinderDelegate <NSObject>

@optional
-(void)receivedPoint:(CGPoint)point;
-(void)receivedOutsidePoint:(CGPoint)point;
-(void)pathHasChanged;
-(void)wayfinding:(MSTWayfinder *) hasTurnedOffNavigation;

@required
-(MSTGraph *)graphForWayfinder;
-(NSMutableDictionary *)nodesForWayfinder;

@end