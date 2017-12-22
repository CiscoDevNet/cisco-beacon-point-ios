//
//  MSTFloorView.m
//  MistSDK
//
//  Created by Cuong Ta on 7/7/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import "MSTFloorView.h"
#import "MSTFloorView_Private.h"

@interface MSTFloorView ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UILabel *currentLocationLabel;
@property (nonatomic) bool isFromOrigin;

@property (nonatomic) double originX;
@property (nonatomic) double originY;

@end

@implementation MSTFloorView

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

-(void)initialize{
    NSLog(@"MSTFloorView init");
    self.isFromOrigin = true;
    
//    self.multiDots = [[NSMutableArray alloc] initWithCapacity:1];
    self.breadcrumbsArray = [[NSMutableArray alloc] initWithCapacity:1];
    [self.breadcrumbsArray addObject:[[NSMutableArray alloc] init]];
    
    self.scaledFrame = CGRectMake(0, 0, 10, 10);
}

-(void)setMap:(MSTMap *)map{
    self.image = map.mapImage;
    self.floorImageView.image = self.image;
    
    if (map.ppm == 0) {
        self.ppm = 1;
    } else {
        self.ppm = map.ppm;
    }
    
    self.originX = map.originX;
    self.originY = map.originY;
    _map = map;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.floorImageView.frame = self.bounds;
    self.scaleX = self.bounds.size.width/self.image.size.width;
    self.scaleY = self.bounds.size.height/self.image.size.height;
}

-(void)start{
    self.floorImageView = [[UIImageView alloc] initWithImage:self.image];
    self.floorImageView.contentScaleFactor = [[UIScreen mainScreen] scale];
    [self addSubview:self.floorImageView];
    
    self.contentView = [[UIView alloc] initWithFrame:self.frame];
    [self addSubview:self.contentView];
    
    self.otherSDKClientsContainerView = [[UIView alloc] initWithFrame:self.frame];
    [self addSubview:self.otherSDKClientsContainerView];
    
    self.bluedot = [self.delegate bluedotViewForFloorView:self];
    self.bluedot.hasMoved = false;
    self.bluedot.layer.shouldRasterize = true;
    self.bluedot.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    self.bluedot.layer.opacity = 0;
//    @synchronized (self) {
//        [self.multiDots addObject:bluedot];
//    }
    [self addSubview:self.bluedot];
    _initialized = true;
}

+(double)scalePointFromOriginToMetersWithPoint:(double)point andScale:(double)scale andOrigin:(double)origin andFlipped:(bool)flipped{
    if (flipped) {
        return (origin/scale)-point;
    } else {
        return point-(origin/scale);
    }
}

#pragma mark - multidots

-(void)drawHeading:(CLHeading *)headingInfo forIndex:(NSUInteger)index{
    if (!_initialized) {
        return;
    }
    if (self.isAnimating) {
        return;
    }
    
    if (self.bluedot.headingView.hidden) {
        self.bluedot.headingView.hidden = false;
    }
    id <MSTFloorViewDelegate> strongDel = self.delegate;
    if ([strongDel respondsToSelector:@selector(canShowFloorViewDots:forIndex:)]) {
        if ([strongDel canShowFloorViewDots:self forIndex:index]) {
            self.bluedot.alpha = 1;
            [UIView animateWithDuration:0.5f animations:^{
                self.bluedot.headingView.layer.transform = CATransform3DMakeRotation(headingInfo.trueHeading*M_PI/180, 0, 0, 1);
            } completion:nil];
        } else {
            self.bluedot.alpha = 0;
        }
    } else {
        self.bluedot.alpha = 0;
    }
}

-(void)drawDotViewAtPoint:(MSTPoint *)cloudPoint forIndex:(NSUInteger)index __deprecated_msg("please migrate to drawDotViewAtCGPoint:(:forIndex:shouldMove:withColor)") {
    if (!_initialized) {
        return;
    }
    if (self.isAnimating) {
        return;
    }
    
    id <MSTFloorViewDelegate> strongDel = self.delegate;
    if ([strongDel respondsToSelector:@selector(canShowFloorViewDots:forIndex:)]) {
        if (self.bluedot.hasMoved) {
            if ([strongDel canShowFloorViewDots:self forIndex:index]) {
                UILabel *label = [self.bluedot locationLabel];
                //    label.text = [NSString stringWithFormat:@"%.2f,%.2f",point.x,point.y];
                label.text = [NSString stringWithFormat:@"%.2f,%.2f",[MSTFloorView scalePointFromOriginToMetersWithPoint:cloudPoint.x andScale:self.ppm andOrigin:self.originX andFlipped:false],[MSTFloorView scalePointFromOriginToMetersWithPoint:cloudPoint.y andScale:self.ppm andOrigin:self.originY andFlipped:true]];
                if (self.showLabel) {
                    label.alpha = 1;
                } else {
                    label.alpha = 0;
                }
                
                [self.bluedot showMotion:cloudPoint.hasMotion];
                
                [UIView animateWithDuration:0.5f animations:^{
                    self.bluedot.alpha = 1;
                    self.bluedot.center = [self scaleUpPoint:[self convertMetersToPixels:[cloudPoint convertToCGPoint]]];
                } completion:^(BOOL finished) {
                    [self drawBreadcrumbAtPosition:cloudPoint];
                }];
            } else {
                self.bluedot.alpha = 0;
            }
        } else {
            self.bluedot.center = [self scaleUpPoint:[self convertMetersToPixels:[cloudPoint convertToCGPoint]]];
            [self drawBreadcrumbAtPosition:cloudPoint];
            self.bluedot.hasMoved = true;
        }
    } else {
        self.bluedot.alpha = 0;
    }
}

-(void)drawDotViewAtPoint:(MSTPoint *)cloudPoint forIndex:(NSUInteger)index shouldMove:(BOOL)move __deprecated_msg("please migrate to drawDotViewAtCGPoint:(:forIndex:shouldMove:withColor)") {
    if (!_initialized) {
        return;
    }
    if (self.isAnimating) {
        return;
    }
    
    id <MSTFloorViewDelegate> strongDel = self.delegate;
    if ([strongDel respondsToSelector:@selector(canShowFloorViewDots:forIndex:)]) {
        if (self.bluedot.hasMoved){
            if ([strongDel canShowFloorViewDots:self forIndex:index]) {
                UILabel *label = [self.bluedot locationLabel];
                //    label.text = [NSString stringWithFormat:@"%.2f,%.2f",point.x,point.y];
                label.text = [NSString stringWithFormat:@"%.2f,%.2f",[MSTFloorView scalePointFromOriginToMetersWithPoint:cloudPoint.x andScale:self.ppm andOrigin:self.originX andFlipped:false],[MSTFloorView scalePointFromOriginToMetersWithPoint:cloudPoint.y andScale:self.ppm andOrigin:self.originY andFlipped:true]];
                if (self.showLabel) {
                    label.alpha = 1;
                } else {
                    label.alpha = 0;
                }
                
                [self.bluedot showMotion:move];
                
                if (move) {
                    [UIView animateWithDuration:0.5f animations:^{
                        self.bluedot.alpha = 1;
                        self.bluedot.center = [self scaleUpPoint:[self convertMetersToPixels:[cloudPoint convertToCGPoint]]];
                    } completion:^(BOOL finished) {
                        [self drawBreadcrumbAtPosition:cloudPoint];
                    }];
                }
            } else {
                self.bluedot.alpha = 0;
            }
        } else {
            self.bluedot.center = [self scaleUpPoint:[self convertMetersToPixels:[cloudPoint convertToCGPoint]]];
            [self drawBreadcrumbAtPosition:cloudPoint];
            self.bluedot.hasMoved = true;
        }
    } else {
        self.bluedot.alpha = 0;
    }
}

-(void)drawDotViewAtPoint:(MSTPoint *)cloudPoint forIndex:(NSUInteger)index shouldMove:(BOOL)move shouldShowMotion:(bool)showMotion __deprecated_msg("please migrate to drawDotViewAtCGPoint:(:forIndex:shouldMove:withColor)") {
    if (!_initialized) {
        return;
    }
    if (self.isAnimating) {
        return;
    }
    
    id <MSTFloorViewDelegate> strongDel = self.delegate;
    if ([strongDel respondsToSelector:@selector(canShowFloorViewDots:forIndex:)]) {
        if (self.bluedot.hasMoved){
            if ([strongDel canShowFloorViewDots:self forIndex:index]) {
                UILabel *label = [self.bluedot locationLabel];
                //    label.text = [NSString stringWithFormat:@"%.2f,%.2f",point.x,point.y];
                label.text = [NSString stringWithFormat:@"%.2f,%.2f",[MSTFloorView scalePointFromOriginToMetersWithPoint:cloudPoint.x andScale:self.ppm andOrigin:self.originX andFlipped:false],[MSTFloorView scalePointFromOriginToMetersWithPoint:cloudPoint.y andScale:self.ppm andOrigin:self.originY andFlipped:true]];
                if (self.showLabel) {
                    label.alpha = 1;
                } else {
                    label.alpha = 0;
                }
                
                [self.bluedot showMotion:showMotion];
                
                if (move) {
                    [UIView animateWithDuration:0.5f animations:^{
                        self.bluedot.alpha = 1;
                        self.bluedot.center = [self scaleUpPoint:[self convertMetersToPixels:[cloudPoint convertToCGPoint]]];
                    } completion:^(BOOL finished) {
                        [self drawBreadcrumbAtPosition:cloudPoint];
                    }];
                }
            } else {
                self.bluedot.alpha = 0;
            }
        } else {
            self.bluedot.center = [self scaleUpPoint:[self convertMetersToPixels:[cloudPoint convertToCGPoint]]];
            [self drawBreadcrumbAtPosition:cloudPoint];
            self.bluedot.hasMoved = true;
        }
    } else {
        self.bluedot.alpha = 0;
    }
}

-(void)drawDotViewAtCGPoint:(CGPoint)point forIndex:(NSUInteger)index shouldMove:(BOOL)shouldMove shouldShowMotion:(bool)showMotion __deprecated_msg("please migrate to drawDotViewAtCGPoint:(:forIndex:shouldMove:withColor)") {
    if (!_initialized) {
        return;
    }
    if (self.isAnimating) {
        return;
    }
    
    id <MSTFloorViewDelegate> strongDel = self.delegate;
    if ([strongDel respondsToSelector:@selector(canShowFloorViewDots:forIndex:)]) {
        if (self.bluedot.hasMoved){
            if ([strongDel canShowFloorViewDots:self forIndex:index]) {
                UILabel *label = [self.bluedot locationLabel];
                CGPoint pointInMeters = [self convertPixelsToMeters:[self scaleDownPoint:point]];
                label.text = [NSString stringWithFormat:@"%.2f,%.2f",pointInMeters.x, pointInMeters.y];
                if (self.showLabel) {
                    label.alpha = 1;
                } else {
                    label.alpha = 0;
                }
                
                [self.bluedot showMotion:showMotion];
                
                if (shouldMove) {
                    [UIView animateWithDuration:0.1f animations:^{
                        self.bluedot.layer.opacity = 1;
                        self.bluedot.layer.position = point;
                    } completion:^(BOOL finished) {
                        [self drawBreadcrumbAtPosition:point shouldShowMotion:showMotion];
                    }];
                }
            } else {
                self.bluedot.layer.opacity = 0;
            }
        } else {
            self.bluedot.layer.position = point;
            [self drawBreadcrumbAtPosition:point shouldShowMotion:showMotion];
            self.bluedot.hasMoved = true;
        }
    } else {
        self.bluedot.alpha = 0;
    }
}

-(void)drawDotViewAtCGPoint:(CGPoint)point forIndex:(NSUInteger)index shouldMove:(BOOL)shouldMove withColor:(UIColor *)color{
    if (!_initialized) {
        return;
    }
    if (self.isAnimating) {
        return;
    }
    
    id <MSTFloorViewDelegate> strongDel = self.delegate;
    if ([strongDel respondsToSelector:@selector(canShowFloorViewDots:forIndex:)]) {
        if (self.bluedot.hasMoved){
            if ([strongDel canShowFloorViewDots:self forIndex:index]) {
                UILabel *label = [self.bluedot locationLabel];
                CGPoint pointInMeters = [self convertPixelsToMeters:[self scaleDownPoint:point]];
                label.text = [NSString stringWithFormat:@"%.2f,%.2f",pointInMeters.x, pointInMeters.y];
                if (self.showLabel) {
                    label.alpha = 1;
                } else {
                    label.alpha = 0;
                }
                
                [self.bluedot renderColor:color];
                
                if (shouldMove) {
                    [UIView animateWithDuration:0.1f animations:^{
                        self.bluedot.alpha = 1;
                        self.bluedot.center = point;
                    } completion:^(BOOL finished) {
                        [self drawBreadcrumbAtPosition:point withColor:color];
                    }];
                }
            } else {
                self.bluedot.alpha = 0;
            }
        } else {
            self.bluedot.center = point;
            [self drawBreadcrumbAtPosition:point withColor:color];
            self.bluedot.hasMoved = true;
        }
    } else {
        self.bluedot.alpha = 0;
    }
}

-(void)drawOtherSDKClients{
    if (self.isAnimating) {
        return;
    }
    if (self.otherSDKClientsContainerView.subviews.count > 0) {
        [self.otherSDKClientsContainerView.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
    }
    
    if ([self.delegate respondsToSelector:@selector(dotsInFloorView:)]) {
        NSArray *dots = [self.delegate dotsInFloorView:self];
        if (dots.count > 0) {
            [dots enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat x = [obj[@"x"] doubleValue];
                CGFloat y = [obj[@"y"] doubleValue];
                CGPoint point = CGPointMake(x, y);
                CGPoint leEst = [self scaleUpPoint:point];
                
                UIView *view = [[UIView alloc] initWithFrame:CGRectMake(leEst.x, leEst.y, self.scaledFrame.size.width, self.scaledFrame.size.height)];
                
                CALayer *dot = [CALayer new];
                dot.frame = CGRectMake(0, 0, self.scaledFrame.size.width, self.scaledFrame.size.height);
                dot.shadowRadius = 3;
                dot.shadowOpacity = 1;
                dot.shadowColor = [UIColor colorWithRed:0.4773 green:0.4806 blue:0.4846 alpha:1.0].CGColor;
                dot.shadowOffset = CGSizeMake(0, 0);
                dot.borderWidth = 1.0;
                dot.borderColor = [UIColor whiteColor].CGColor;
                dot.cornerRadius = self.scaledFrame.size.width/2;
                dot.backgroundColor = [UIColor colorWithRed:0.0 green:0.7077 blue:0.3357 alpha:1.0].CGColor;
                [view.layer addSublayer:dot];
                
                UILabel *text = [[UILabel alloc] initWithFrame:CGRectZero];
                [text setFont:[UIFont fontWithName:@"Arial" size:10]];
                text.backgroundColor = [UIColor clearColor];
                text.text = obj[@"name"];
                text.textAlignment = NSTextAlignmentCenter;
                [text sizeToFit];
                [view addSubview:text];
                
                [self.otherSDKClientsContainerView addSubview:view];
                
                text.translatesAutoresizingMaskIntoConstraints = false;
                [self.otherSDKClientsContainerView addConstraint:[NSLayoutConstraint constraintWithItem:text attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100]];
                [self.otherSDKClientsContainerView addConstraint:[NSLayoutConstraint constraintWithItem:text attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:20]];
                [self.otherSDKClientsContainerView addConstraint:[NSLayoutConstraint constraintWithItem:text attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
                [self.otherSDKClientsContainerView addConstraint:[NSLayoutConstraint constraintWithItem:text attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
                
                text.translatesAutoresizingMaskIntoConstraints = false;
                [self.otherSDKClientsContainerView addConstraint:[NSLayoutConstraint constraintWithItem:text attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100]];
                [self.otherSDKClientsContainerView addConstraint:[NSLayoutConstraint constraintWithItem:text attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:20]];
                [self.otherSDKClientsContainerView addConstraint:[NSLayoutConstraint constraintWithItem:text attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
                [self.otherSDKClientsContainerView addConstraint:[NSLayoutConstraint constraintWithItem:text attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
                
                view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
                view.layer.shouldRasterize = true;
            }];
        }
    }
}

-(CGPoint)getFloorviewPointFromCloudPoint:(CGPoint)cloudPoint{
    return CGPointMake(cloudPoint.x*self.scaleX*self.ppm, cloudPoint.y*self.scaleY*self.ppm);
}

-(CGPoint)getCloudPointFromFloorviewPoint:(CGPoint)fvPoint{
    return CGPointMake(fvPoint.x/(self.scaleX*self.ppm), fvPoint.y/(self.scaleY*self.ppm));
}

-(CGPoint)scaleUpPoint:(CGPoint)point{
    return CGPointMake(point.x*self.scaleX, point.y*self.scaleY);
}

-(CGPoint)scaleDownPoint:(CGPoint)point{
    return CGPointMake(point.x/self.scaleX, point.y/self.scaleY);
}

-(CGPoint)convertPixelsToMeters:(CGPoint)point{
    return CGPointMake(point.x/self.ppm, point.y/self.ppm);
}

-(CGPoint)convertMetersToPixels:(CGPoint)point{
    return CGPointMake(point.x*self.ppm, point.y*self.ppm);
}

-(CGFloat)getScale{
    CGFloat scale = self.bluedot.frame.size.width/self.bluedot.bounds.size.width;
    return scale;
}

-(void)drawBreadcrumbAtPosition:(MSTPoint *)cloudPoint __deprecated_msg("please migrate to drawBreadcrumbAtPosition(:shouldShowMotion)") {
    if (self.isAnimating) {
        return;
    }
    @synchronized (self) {
        NSMutableArray *bcs = [self.breadcrumbsArray objectAtIndex:0];
    
        if (self.maxBreadcrumb != 0) {
            CALayer *bc = [CALayer new];
            NSInteger scale = [self getScale];
            bc.frame = CGRectMake(0, 0, kMSTLocationViewSize.width*scale, kMSTLocationViewSize.height*scale);
            bc.cornerRadius = bc.frame.size.width/2;
            bc.position = [self scaleUpPoint:[self convertMetersToPixels:[cloudPoint convertToCGPoint]]];
            if (cloudPoint.hasMotion) {
                bc.opacity = 0.40;
                bc.backgroundColor = [[UIColor colorWithRed:0.992 green:0.741 blue:0 alpha:1] CGColor];
            } else {
                bc.opacity = 0.25;
                bc.backgroundColor = [[UIColor colorWithRed:0.072 green:0.593 blue:0.997 alpha:1.000] CGColor];
            }
            [self.floorImageView.layer addSublayer:bc];
            [bcs addObject:bc];
        }
        
        if (self.maxBreadcrumb != -1) {
            if (bcs.count > self.maxBreadcrumb) {
                CALayer *oldestBreadcrumb = [bcs objectAtIndex:0];
                [oldestBreadcrumb removeFromSuperlayer];
                [bcs removeObjectAtIndex:0];
            }
        }
    }
}

-(void)drawBreadcrumbAtPosition:(CGPoint)point shouldShowMotion:(bool)showMotion{
    if (self.isAnimating) {
        return;
    }
    @synchronized (self) {
        NSMutableArray *bcs = [self.breadcrumbsArray objectAtIndex:0];
    
        if (self.maxBreadcrumb != 0) {
            CALayer *bc = [CALayer new];
            bc.frame = CGRectMake(0, 0, kMSTLocationViewSize.width, kMSTLocationViewSize.height);
            bc.cornerRadius = kMSTLocationViewSize.width/2;
            bc.position = point;
            if (showMotion) {
                bc.opacity = 0.40;
                bc.backgroundColor = [[UIColor colorWithRed:0.992 green:0.741 blue:0 alpha:1] CGColor];
            } else {
                bc.opacity = 0.25;
                bc.backgroundColor = [[UIColor colorWithRed:0.072 green:0.593 blue:0.997 alpha:1.000] CGColor];
            }
            [self.floorImageView.layer addSublayer:bc];
            [bcs addObject:bc];
        }
        
        if (self.maxBreadcrumb != -1) {
            if (bcs.count > self.maxBreadcrumb) {
                CALayer *oldestBreadcrumb = [bcs objectAtIndex:0];
                [oldestBreadcrumb removeFromSuperlayer];
                [bcs removeObjectAtIndex:0];
            }
        }
    }
}

-(void)drawBreadcrumbAtPosition:(CGPoint)point withColor:(UIColor *)color{
    if (self.isAnimating) {
        return;
    }
    @synchronized (self) {
        NSMutableArray *bcs = [self.breadcrumbsArray objectAtIndex:0];
    
        if (self.maxBreadcrumb != 0) {
            CALayer *bc = [CALayer new];
            bc.frame = CGRectMake(0, 0, kMSTLocationViewSize.width, kMSTLocationViewSize.height);
            bc.cornerRadius = kMSTLocationViewSize.width/2;
            bc.position = point;
            bc.backgroundColor = [color CGColor];
            [self.floorImageView.layer addSublayer:bc];
            [bcs addObject:bc];
        }
        
        if (self.maxBreadcrumb != -1) {
            if (bcs.count > self.maxBreadcrumb) {
                CALayer *oldestBreadcrumb = [bcs objectAtIndex:0];
                [oldestBreadcrumb removeFromSuperlayer];
                [bcs removeObjectAtIndex:0];
            }
        }
    }
}

@end