//
//  MSTFloorView.h
//  MistSDK
//
//  Created by Cuong Ta on 7/7/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MistSDK/MistSDK.h>
#import "MSTLocationView.h"

@protocol MSTFloorViewDelegate;

@interface MSTFloorView : UIView

@property (nonatomic) bool showLabel;
@property (nonatomic) unsigned int maxBreadcrumb;
@property (nonatomic) double ppm;
@property (nonatomic) double scaleX;
@property (nonatomic) double scaleY;
@property (nonatomic, strong) UIImageView *floorImageView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *otherSDKClientsContainerView;
@property (nonatomic) id <MSTFloorViewDelegate> delegate;
@property (nonatomic, strong) MSTMap *map;
//@property (nonatomic, strong) NSMutableArray *multiDots;
@property (nonatomic, strong) NSMutableArray *breadcrumbsArray;
@property (nonatomic, assign) bool initialized;
@property (nonatomic, assign) CGRect scaledFrame;
@property (nonatomic, strong) MSTLocationView *bluedot;

-(id)initWithFrame:(CGRect)frame;

-(void)initialize;

-(void)start;

-(void)drawHeading:(CLHeading *)headingInfo forIndex:(NSUInteger)index;
//
-(void)drawDotViewAtPoint:(MSTPoint *)point forIndex:(NSUInteger)index __deprecated_msg("please migrate to drawDotViewAtCGPoint:(:forIndex:shouldMove:withColor)");
//
-(void)drawDotViewAtPoint:(MSTPoint *)point forIndex:(NSUInteger)index shouldMove:(BOOL)move __deprecated_msg("please migrate to drawDotViewAtCGPoint:(:forIndex:shouldMove:withColor)");
//
-(void)drawDotViewAtPoint:(MSTPoint *)cloudPoint forIndex:(NSUInteger)index shouldMove:(BOOL)move shouldShowMotion:(bool)showMotion __deprecated_msg("please migrate to drawDotViewAtCGPoint:(:forIndex:shouldMove:withColor)");
//
-(void)drawDotViewAtCGPoint:(CGPoint)point forIndex:(NSUInteger)index shouldMove:(BOOL)move shouldShowMotion:(bool)showMotion __deprecated_msg("please migrate to drawDotViewAtCGPoint:(:forIndex:shouldMove:withColor)");

-(void)drawDotViewAtCGPoint:(CGPoint)point forIndex:(NSUInteger)index shouldMove:(BOOL)move withColor:(UIColor *)color;

-(CGPoint)scaleUpPoint:(CGPoint)point;

-(CGPoint)scaleDownPoint:(CGPoint)point;

-(CGPoint)convertPixelsToMeters:(CGPoint)point;

-(CGPoint)convertMetersToPixels:(CGPoint)point;

+(double)scalePointFromOriginToMetersWithPoint:(double)point andScale:(double)scale andOrigin:(double)origin andFlipped:(bool)flipped;

/**
 *  Convert the cloud point (in meters) to device UI floorview point (in pt) by converting the cloud point to px and to pt
 */

-(CGPoint)getFloorviewPointFromCloudPoint:(CGPoint)point;

/**
 *  Convert the device UI floorview point (in pt) to cloud point (in meters) by converting the cloud point to px and to pt
 */

-(CGPoint)getCloudPointFromFloorviewPoint:(CGPoint)fvPoint;

-(void)drawOtherSDKClients;

-(void)drawBreadcrumbAtPosition:(CGPoint)point shouldShowMotion:(bool)showMotion;

-(void)drawBreadcrumbAtPosition:(CGPoint)point withColor:(UIColor *)color;

@end

@protocol MSTFloorViewDelegate <NSObject>

@required

-(MSTLocationView *)bluedotViewForFloorView:(MSTFloorView *)floorView;

-(bool)canShowFloorViewDots:(MSTFloorView *)floorView forIndex:(NSUInteger)index;

-(NSUInteger)numOfDotsInFloorview:(MSTFloorView *)indoorMapView;

-(NSArray *)dotsInFloorView:(MSTFloorView *)indoorMapView;

@end