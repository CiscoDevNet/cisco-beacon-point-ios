//
//  MSTWayfinder.m
//  Mist
//
//  Created by Cuong Ta on 7/23/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import "MSTWayfinder.h"
#import "MSTFloorView_Private.h"
#import "DistanceCommon.h"

typedef NS_ENUM(NSUInteger, UIViewOrientation){
    UIViewOrientationSquare,
    UIViewOrientationHorizontal,
    UIViewOrientationVertical
};

@interface MSTWayfinderPoint : NSObject

@property (nonatomic, assign) CGFloat X;
@property (nonatomic, assign) CGFloat Y;
@property (nonatomic, assign) bool isMain;
@property (nonatomic, assign) CGFloat gravity;
@property (nonatomic, assign) bool isIntersect;

@end

@implementation MSTWayfinderPoint

-(void)tooMSTPoint{
    
}

@end

@interface MSTWayfinder () {
    CAShapeLayer *dotOnPathShape;
    NSMutableDictionary *pathsAssociatedToNode;
    NSMutableDictionary *pointsOfPathsAssociatedToNode;
    NSMutableArray *allPoints;
    
    CALayer *_startingLocation;
    CALayer *_endingLocation;
    
    NSMutableDictionary *_nodes;
    
    MSTGraph *_graph;
    
    MSTNode *_sourceNode;
    MSTNode *_destinationNode;
    
    UIView *_centerIndicatorView;
    CGPoint _begin;
    
    bool _hasMoved;
    NSMutableArray *_tempViews;
    NSArray *_previousPathArr;
    
    bool _allowPan;
    
    CGSize _initialFrameSize;
}

@property (nonatomic, strong) NSMutableDictionary *subLayersDict;
@property (nonatomic        ) double scaleXFactor;
@property (nonatomic        ) double scaleYFactor;
@property (nonatomic) CGPoint _startingPoint;
@property (nonatomic) CGPoint _endingPoint;
@property (nonatomic) double scaledRatio;

-(void)rasterizePaths;
-(CGPoint)findClosestPointOnPath:(CGPathRef)path usingPoint:(CGPoint)point;

-(CGPathRef)calculatePathUsingPathData:(NSArray *)pathData usingNodes:(NSDictionary *)nodes;
-(CGPathRef)calculatePathUsingPoints:(NSArray *)points;
-(double)distanceBetweenInsidePoint:(CGPoint)a andPoint:(CGPoint)b;

@end

@implementation MSTWayfinder

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

-(instancetype)init{
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

-(void)initialize{
    [super initialize];
    _subLayersDict = [[NSMutableDictionary alloc] init];
    pathsAssociatedToNode = [[NSMutableDictionary alloc] init];
    pointsOfPathsAssociatedToNode = [[NSMutableDictionary alloc] init];
    allPoints = [[NSMutableArray alloc] init];
    
    _nodes = [[NSMutableDictionary alloc] init];
    
    self.usePPM = true;
    self.isWayfindingEnabled = false;
    
    _tempViews = [[NSMutableArray alloc] init];
}

-(void)start{
    [super start];
    
    [self.contentView addSubview:self.beaconViews];
    self.beaconViews.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.beaconViews attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.beaconViews attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.beaconViews attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.beaconViews attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    [self.contentView addSubview:self.pathView];
    self.pathView.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.pathView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.pathView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.pathView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.pathView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    [self.contentView addSubview:self.wayfindingPathView];
    self.wayfindingPathView.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.wayfindingPathView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.wayfindingPathView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.wayfindingPathView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.wayfindingPathView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    [self.contentView addSubview:self.dotsView];
    self.dotsView.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dotsView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dotsView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dotsView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dotsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    _initialFrameSize = self.frame.size;
    _scaledRatio = 1;
}

-(UIView *)beaconViews{
    if (!_beaconViews) {
        _beaconViews = [[UIView alloc] initWithFrame:self.bounds];
    }
    return _beaconViews;
}

-(UIView *)dotsView{
    if (!_dotsView) {
        _dotsView = [[UIView alloc] initWithFrame:self.bounds];
    }
    return _dotsView;
}

-(UIView *)wayfindingPathView{
    if (!_wayfindingPathView) {
        _wayfindingPathView = [[UIView alloc] initWithFrame:self.bounds];
    }
    return _wayfindingPathView;
}

-(UIView *)pathView{
    if (!_pathView) {
        _pathView = [[UIView alloc] initWithFrame:self.bounds];
    }
    return _pathView;
}

-(UIView *)wayfindingPaths{
    if (!_wayfindingPaths) {
        _wayfindingPaths = [[UIView alloc] initWithFrame:self.bounds];
        _wayfindingPaths.userInteractionEnabled = false;
        //        _wayfindingPaths.backgroundColor = [UIColor purpleColor];
        //        _wayfindingPaths.alpha = 0.1;
    }
    return _wayfindingPaths;
}

-(double)scaleXFactor{
    if (self.usePPM) {
        return self.ppm*self.scaleX;
    }
    return self.scaleX;
}

-(double)scaleYFactor{
    if (self.usePPM) {
        return self.ppm*self.scaleY;
    }
    return self.scaleY;
}

/*
 drawWayUsingPath
 path: The path to draw.
 enable: Must set the enable flag in order to draw it.
 */
-(void)drawWayUsingPath:(CGPathRef)path enable:(bool)enable{
    CGPathRetain(path);
    
    if(self.wayPath.superlayer){
        [self.wayPath removeFromSuperlayer];
    }
    if (enable) {
        self.wayPath = [CAShapeLayer layer];
        self.wayPath.path = path;
        self.wayPath.strokeColor = [[UIColor colorWithRed:60.0f/255.0f green:120.0f/255.0f blue:216.0f/255.0f alpha:1.0] CGColor];
        self.wayPath.lineWidth = 5.0;
        self.wayPath.lineCap = kCALineCapRound;
        self.wayPath.fillColor = [[UIColor clearColor] CGColor];
        self.wayPath.shouldRasterize = true;
        self.wayPath.rasterizationScale = [[UIScreen mainScreen] scale];
        //        [self.contentView.layer addSublayer:self.wayPath];
        [self.wayfindingPathView.layer addSublayer:self.wayPath];
    }
    
    CGPathRelease(path);
}

-(CGPathRef)getWaypath:(NSArray *)pathData fromGraph:(NSDictionary *)graph{ // deprecate
    return [self calculatePathUsingPathData:pathData usingNodes:graph];
}

-(CGPathRef)calculatePathUsingPathData:(NSArray *)pathData usingNodes:(NSDictionary *)nodes{
    if (self.wayPath.superlayer == self.layer) {
        [self.wayPath removeFromSuperlayer];
    }
    NSMutableArray *pointsToSample = [[NSMutableArray alloc] init];
    if (pathData.count > 1) {
        UIBezierPath *p = [UIBezierPath bezierPath];
        MSTNode *startNode = [nodes objectForKey:[pathData firstObject]];
        [pointsToSample addObject:NSStringFromCGPoint(CGPointMake(startNode.nodePoint.x*self.scaleXFactor, startNode.nodePoint.y*self.scaleYFactor))];
        [p moveToPoint:CGPointMake(startNode.nodePoint.x*self.scaleXFactor, startNode.nodePoint.y*self.scaleYFactor)];
        for (int i = 0; i < pathData.count; i++) {
            MSTNode *nextNode = [nodes objectForKey:pathData[i]];
            [p addLineToPoint:CGPointMake(nextNode.nodePoint.x*self.scaleXFactor, nextNode.nodePoint.y*self.scaleYFactor)];
            [pointsToSample addObject:NSStringFromCGPoint(CGPointMake(nextNode.nodePoint.x*self.scaleXFactor, nextNode.nodePoint.y*self.scaleYFactor))];
        }
        return [p CGPath];
    }
    return NULL;
}

-(CGPathRef)calculatePathUsingPoints:(NSArray *)points{
    if (points.count > 1) {
        UIBezierPath *p = [UIBezierPath bezierPath];
        NSValue *point = [points firstObject];
        CGPoint firstPoint = [point CGPointValue];
        [p moveToPoint:CGPointMake(firstPoint.x*self.scaleXFactor, firstPoint.y*self.scaleYFactor)];
        for (int i = 1; i < points.count; i++) {
            point = [points objectAtIndex:i];
            CGPoint nextPoint = [point CGPointValue];
            [p addLineToPoint:CGPointMake(nextPoint.x*self.scaleXFactor, nextPoint.y*self.scaleYFactor)];
        }
        return [p CGPath];
    }
    return NULL;
}

-(void)undrawBackgroundGraph{
    if (self.wayfindingPaths.superview) {
        [self.wayfindingPaths removeFromSuperview];
        self.wayfindingPaths = nil;
    }
}

-(void)drawBackgroundGraph:(NSDictionary *)graph{
    [self.pathView addSubview:self.wayfindingPaths];
    self.wayfindingPaths.translatesAutoresizingMaskIntoConstraints = false;
    [self.pathView addConstraint:[NSLayoutConstraint constraintWithItem:self.wayfindingPaths attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.pathView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.pathView addConstraint:[NSLayoutConstraint constraintWithItem:self.wayfindingPaths attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.pathView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self.pathView addConstraint:[NSLayoutConstraint constraintWithItem:self.wayfindingPaths attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.pathView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self.pathView addConstraint:[NSLayoutConstraint constraintWithItem:self.wayfindingPaths attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.pathView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    //    self.wayfindingPaths.hidden = false;
    
    for (NSString *key in graph) {
        MSTNode *node = graph[key];
        if (self.showNodeVertices) {
            UIView *vertexView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
            vertexView.backgroundColor = [UIColor colorWithRed:86.0f/255.0f green:153.0f/255.0f blue:246.0f/255.0f alpha:1.0];
            vertexView.center = CGPointMake(node.nodePoint.x*self.scaleXFactor, node.nodePoint.y*self.scaleYFactor);
            if (self.showNodeLabel) {
                UILabel *label = [[UILabel alloc] init];
                label.font = [UIFont fontWithName:@"Arial" size:10];
                label.text = [NSString stringWithFormat:@"%@",node.nodeName];
                [vertexView addSubview:label];
                label.translatesAutoresizingMaskIntoConstraints = false;
                [vertexView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:vertexView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
                [vertexView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:vertexView attribute:NSLayoutAttributeCenterX multiplier:1 constant:10]];
                [vertexView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:100]];
                [vertexView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:10]];
            }
            [self.wayfindingPaths addSubview:vertexView];
            
        }
        NSMutableArray *paths = [[NSMutableArray alloc] init];
        for (NSString *nodeName in node.edges.allKeys) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(node.nodePoint.x*self.scaleXFactor, node.nodePoint.y*self.scaleYFactor)];
            MSTNode *nextNode = [graph objectForKey:nodeName];
            [path addLineToPoint:CGPointMake(nextNode.nodePoint.x*self.scaleXFactor, nextNode.nodePoint.y*self.scaleYFactor)];
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.path = [path CGPath];
            shapeLayer.strokeColor = [[UIColor colorWithRed:211.0f/255.0f green:230.0f/255.0f blue:255.0f/255.0f alpha:1.0] CGColor];
            shapeLayer.lineWidth = 3.0;
            shapeLayer.lineCap = kCALineCapRound;
            shapeLayer.fillColor = [[UIColor clearColor] CGColor];
            [self.wayfindingPaths.layer addSublayer:shapeLayer];
            [paths addObject:path];
        }
        [pathsAssociatedToNode setObject:paths forKey:node.nodeName];
    }
    [self rasterizePaths];
}

void PathApplierOnSet (void *info, const CGPathElement *element) {
    [(__bridge NSMutableSet *)info addObject:NSStringFromCGPoint(*element->points)];
}

-(void)rasterizePaths{
    NSMutableArray *tempPoints = [[NSMutableArray alloc] init];
    [pathsAssociatedToNode enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSArray*  _Nonnull paths, BOOL * _Nonnull stop) {
        [paths enumerateObjectsUsingBlock:^(UIBezierPath * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableArray *pathPoints = [[NSMutableArray alloc] init];
            CGPathRef dashedPath = CGPathCreateCopyByDashingPath([path CGPath], NULL, 0, (CGFloat[]){1.0f,1.0f}, 2);
            CGPathApply(dashedPath, (__bridge void * _Nullable)(pathPoints), PathApplierOnSet);
            CGPathRelease(dashedPath);
            
            for (int i = 0; i < pathPoints.count; i++) {
                NSString *pointStr = pathPoints[i];
                CGPoint point = CGPointFromString(pointStr);
                MSTWayfinderPoint *rasterizedPoint = [[MSTWayfinderPoint alloc] init];
                rasterizedPoint.X = point.x;
                rasterizedPoint.Y = point.y;
                
                if (i == 0) {
                    rasterizedPoint.isMain = true;
                    rasterizedPoint.isIntersect = true;
                    rasterizedPoint.gravity = 1;
                } else {
                    rasterizedPoint.gravity = 1;
                }
                
                [tempPoints addObject:rasterizedPoint];
            }
        }];
    }];
    allPoints = tempPoints;
}

void MyCGPathApplierFunc (void *info, const CGPathElement *element) {
    [(__bridge NSMutableArray *)info addObject:NSStringFromCGPoint(*element->points)];
}

// Find the closest point on this path
-(CGPoint)findClosestPointOnPath:(CGPathRef)wayPath usingPoint:(CGPoint)point{
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    CGPathRef dashedPath = CGPathCreateCopyByDashingPath(wayPath, NULL, 0, (CGFloat[]){1.0f,1.0f}, 2);
    CGPathApply(dashedPath, (__bridge void * _Nullable)(paths), MyCGPathApplierFunc);
    CGPathRelease(dashedPath);
    
    CGPoint minPoint = CGPointMake(-1, -1);
    double minDist = INFINITY;
    for (NSString *pointStr in paths) {
        CGPoint aPoint = CGPointFromString(pointStr);
        double dist = [self distanceBetweenInsidePoint:aPoint andPoint:point];
        if (dist < minDist) {
            minDist = dist;
            minPoint = aPoint;
        }
    }
    return minPoint;
}

-(double)distanceBetweenInsidePoint:(CGPoint)a andPoint:(CGPoint)b{
    return sqrt(pow(a.x-b.x, 2)+pow(a.y-b.y, 2));
}

-(double)weightedDistanceBetweenInsidePoint:(CGPoint)a andPoint:(CGPoint)b andGravity:(CGFloat)gravity{
    double dist = [self distanceBetweenInsidePoint:a andPoint:b];
    double weightedDist = dist/gravity;
    return weightedDist;
}

//-(CGPoint)closestPointOnPathToAPoint:(CGPoint)point nearestNode:(MSTNode *)node{
//    NSArray *paths = [pathsAssociatedToNode objectForKey:node.nodeName];
//    NSMutableArray *pointsOnPaths = [[NSMutableArray alloc] init];
//    [paths enumerateObjectsUsingBlock:^(UIBezierPath *path, NSUInteger idx, BOOL * _Nonnull stop) {
//        CGPathRef dashedPath = CGPathCreateCopyByDashingPath([path CGPath], NULL, 0, (CGFloat[]){1.0f,1.0f}, 2);
//        CGPathApply(dashedPath, CFBridgingRetain(pointsOnPaths), MyCGPathApplierFunc);
//    }];
//    NSLog(@"ppp = %@",pointsOnPaths);
//    __block double shortestDistance = INT32_MAX;
//    __block CGPoint shortestPoint;
//    [pointsOnPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        CGPoint aPoint = CGPointFromString(obj);
//        if (shortestDistance > [self distanceBetweenInsidePoint:aPoint andPoint:point]) {
//            shortestDistance = [self distanceBetweenInsidePoint:aPoint andPoint:point];
//            shortestPoint = aPoint;
//        }
//    }];
//    return shortestPoint;
//}

// Find the point closest to the path
-(CGPoint)closestPointOnAllPaths:(CGPoint)point{
    __block double shortestDistance = INT32_MAX;
    __block CGPoint shortestPoint;
    
    [allPoints enumerateObjectsUsingBlock:^(MSTWayfinderPoint *rasterizedPoint, NSUInteger idx, BOOL * _Nonnull stop) {
        //        if (self.usePPM) {
        //            if (shortestDistance > [self distanceBetweenInsidePoint:CGPointMake(rasterizedPoint.X, rasterizedPoint.Y) andPoint:point]) {
        //                shortestDistance = [self distanceBetweenInsidePoint:CGPointMake(rasterizedPoint.X, rasterizedPoint.Y) andPoint:point];
        //                shortestPoint = CGPointMake(rasterizedPoint.X, rasterizedPoint.Y);
        //            }
        //        } else {
        //            if (shortestDistance > [self distanceBetweenInsidePoint:CGPointMake(rasterizedPoint.X, rasterizedPoint.Y) andPoint:point]) {
        //                shortestDistance = [self distanceBetweenInsidePoint:CGPointMake(rasterizedPoint.X, rasterizedPoint.Y) andPoint:point];
        //                shortestPoint = CGPointMake(rasterizedPoint.X, rasterizedPoint.Y);
        //            }
        //        }
        
        if (shortestDistance > [self weightedDistanceBetweenInsidePoint:CGPointMake(rasterizedPoint.X, rasterizedPoint.Y) andPoint:point andGravity:rasterizedPoint.gravity]) {
            shortestDistance = [self weightedDistanceBetweenInsidePoint:CGPointMake(rasterizedPoint.X, rasterizedPoint.Y) andPoint:point andGravity:rasterizedPoint.gravity];
            shortestPoint = CGPointMake(rasterizedPoint.X, rasterizedPoint.Y);
        }
    }];
    return shortestPoint;
}

-(NSMutableArray *)pointsBetweenPoint:(CGPoint)p1 andPoint:(CGPoint)p2{
    __block double shortestDistance = [self distanceBetweenInsidePoint:p1 andPoint:p2];
    __block NSMutableArray *points = [[NSMutableArray alloc] init];
    __block CGPoint lastPoint;
    
    [allPoints enumerateObjectsUsingBlock:^(MSTWayfinderPoint *rasterizedPoint, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx % 2 == 0) {
            if (shortestDistance > [self weightedDistanceBetweenInsidePoint:CGPointMake(rasterizedPoint.X, rasterizedPoint.Y) andPoint:p1 andGravity:rasterizedPoint.gravity] &&
                shortestDistance > [self weightedDistanceBetweenInsidePoint:CGPointMake(rasterizedPoint.X, rasterizedPoint.Y) andPoint:p2 andGravity:rasterizedPoint.gravity] &&
                rasterizedPoint.isIntersect) {
                lastPoint = CGPointMake(rasterizedPoint.X, rasterizedPoint.Y);
                [points addObject:NSStringFromCGPoint(lastPoint)];
            }
        }
    }];
    
    return points;
}

#pragma mark -

-(bool)addDot:(MSTLocationView *)view forKey:(NSString *)key{
    [self.subLayersDict setObject:view forKey:key];
    [self.dotsView addSubview:view];
    return true;
}

-(void)removeDotForKey:(NSString *)key{
    UIView *obj = [self.subLayersDict objectForKey:key];
    if (obj) {
        [obj removeFromSuperview];
        [self.subLayersDict removeObjectForKey:key];
    }
}

-(void)drawHeading:(CLHeading *)headingInfo forKey:(NSString *)key{
    MSTLocationView *view = [self.subLayersDict objectForKey:key];
    if (view.headingView.hidden) {
        view.headingView.hidden = false;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        view.headingView.layer.transform = CATransform3DMakeRotation(headingInfo.trueHeading*M_PI/180, 0, 0, 1);
    } completion:nil];
}

-(void)reloadUI{
    if (self.showSkeletonView) {
        self.wayfindingPaths.hidden = false;
    } else {
        self.wayfindingPaths.hidden = true;
    }
}

#pragma mark - Map Orientation

-(void)turnOnMapOrientationBasedOnHeading{
    self.isOrientMapBasedOnHeading = true;
}

-(void)turnOffMapOrientationBasedOnHeading{
    [UIView animateWithDuration:0.5 animations:^{
        self.layer.transform = CATransform3DIdentity;
    }];
    self.isOrientMapBasedOnHeading = false;
}

-(void)orientFloormapBasedOnHeading:(CGFloat)headingInfo{
    if (self.isOrientMapBasedOnHeading) {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            if (self.map.orientation != -1) {
                self.layer.transform = CATransform3DMakeRotation((-headingInfo+self.map.orientation)*M_PI/180, 0, 0, 1);
            } else {
                self.layer.transform = CATransform3DMakeRotation(-headingInfo*M_PI/180, 0, 0, 1);
            }
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.layer.transform = CATransform3DIdentity;
        } completion:nil];
    }
}

#pragma mark -

#pragma mark - Wayfinding

-(MSTNode*)findNearestNodeToPoint:(CGPoint)point{
    MSTNode *nearestNode;
    double minDist = INFINITY;
    for (NSString *nodeName in _nodes) {
        MSTNode *aNode = _nodes[nodeName];
        CGPoint aPoint = aNode.nodePoint;
        CGPoint aInsidePoint = [self convertToInsidePointFromPoint:aPoint];
        double d = [self distanceBetweenInsidePoint:point andPoint:aInsidePoint];
        if (d < minDist) {
            minDist = d;
            nearestNode = aNode;
        }
    }
    return nearestNode;
}

-(void)turnOnWayfinding{
    self.isWayfindingEnabled = true;
}

-(void)turnOffWayfinding{
    self.isWayfindingEnabled = false;
    [self stopWayfinding];
}

-(void)startWayfinding{
    CGPathRef path = [self renderWayfinding2];
    if (path != NULL) {
        CGPathRetain(path);
        [self drawWayUsingPath:path enable:true];
        CGPathRelease(path);
    }
}

-(void)renderWayfinding{
    _nodes = [self.wayFinderDelegate nodesForWayfinder];
    _graph = [self.wayFinderDelegate graphForWayfinder];
    
    MSTNode *startingNode = [self findNearestNodeToPoint:self._startingPoint];
    
    if (_destinationNode) {
        NSArray *path = [_graph findPathFrom:startingNode.nodeName to:_destinationNode.nodeName];
        NSArray *reversedPath = [[path reverseObjectEnumerator] allObjects];
        NSLog(@"revPath1 = %@",reversedPath);
        
        // Inform the delegate the path has changed.
        id <MSTWayfinderDelegate> strongDel = self.wayFinderDelegate;
        if ([strongDel respondsToSelector:@selector(pathHasChanged)]) {
            [strongDel pathHasChanged];
        }
        
        NSMutableArray *pathPoints = [[NSMutableArray alloc] init];
        [reversedPath enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            MSTNode *node = [_nodes objectForKey:obj];
            [pathPoints addObject:[NSValue valueWithCGPoint:node.nodePoint]];
        }];
        
        CGPathRef initialPath = [self calculatePathUsingPoints:pathPoints];
        
        /*
         Find point closest to the path
         P1----A----|M|----B----P2
         A and B are location scenarios
         Scenario #1) If a point between P1 to M. Since the point is closer to P1, hence the 'closestPoint' will be A, and 'firstPointOnInitialPath' will be P1
         Scenario #2) If a point between M to P2. Since the point is closer to P2, hence the 'closestPoint' will be P2, and 'firstPointOnInitialPath' will be P2
         */
        CGPoint closestPoint = [self findClosestPointOnPath:initialPath usingPoint:self._startingPoint];
        
        CGPathRelease(initialPath); // free it
        
        // The first point on the path
        CGPoint firstPointOnInitialPath = [(NSValue *)[pathPoints firstObject] CGPointValue]; // the first point on the initial path
        firstPointOnInitialPath = [self convertToInsidePointFromPoint:firstPointOnInitialPath];
        
        /*
         distanceBetweenFirstPointAndClosestPoint
         if distance == 0
         scenario 2
         else
         otherwise scenario 1.
         */
        int distanceBetweenFirstPointAndClosestPoint = [self distanceBetweenInsidePoint:closestPoint andPoint:firstPointOnInitialPath];
        
        CGPoint startingPoint;
        if (distanceBetweenFirstPointAndClosestPoint == 0) { // Scenario #2. Has not reached the first point yet
            startingPoint = [self convertToOutsidePointFromPoint:self._startingPoint];
            NSMutableArray *tempArray = [[NSMutableArray alloc] init];
            [tempArray addObject:[NSValue valueWithCGPoint:startingPoint]];
            [tempArray addObjectsFromArray:pathPoints];
            pathPoints = tempArray;
        } else { // Scenario #1. Has reached the point already
            // Need to override the first point with the closest point
            startingPoint = [self convertToOutsidePointFromPoint:self._startingPoint];
            [pathPoints setObject:[NSValue valueWithCGPoint:startingPoint] atIndexedSubscript:0];
        }
        
        CGPathRef finalPath = [self calculatePathUsingPoints:pathPoints];
        CGPathRetain(finalPath);
        NSLog(@"wayPath1 = %@",finalPath);
        
        [self drawWayUsingPath:finalPath enable:true];
        CGPathRelease(finalPath);
    }
}

-(CGPathRef)renderWayfinding2{
    _nodes = [self.wayFinderDelegate nodesForWayfinder];
    _graph = [self.wayFinderDelegate graphForWayfinder];
    
    MSTNode *startingNode = [self findNearestNodeToPoint:self._startingPoint];
    
    if (_destinationNode) {
        
        if (_graph.isRunning) {
            _graph.canStop = true;
        }
        
        NSArray *path = [_graph findPathFrom:startingNode.nodeName to:_destinationNode.nodeName];
        
        // If the path returns nil, do nothing
        // If the path count has no items, do nothing
        // If the path hasn't change, do nothing
        if ((path != nil || path.count > 0) && [self hasPathChanged:path]) {
            _previousPathArr = path;
            
            NSArray *reversedPath = [[path reverseObjectEnumerator] allObjects];
            NSLog(@"revPath2 = %@",reversedPath);
            
            // Inform the delegate the path has changed.
            id <MSTWayfinderDelegate> strongDel = self.wayFinderDelegate;
            if ([strongDel respondsToSelector:@selector(pathHasChanged)]) {
                [strongDel pathHasChanged];
            }
            
            NSMutableArray *pathPoints = [[NSMutableArray alloc] init];
            [reversedPath enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                MSTNode *node = [_nodes objectForKey:obj];
                [pathPoints addObject:[NSValue valueWithCGPoint:node.nodePoint]];
            }];
            
            CGPathRef initialPath = [self calculatePathUsingPoints:pathPoints];
            
            /*
             Find point closest to the path
             P1----A----|M|----B----P2
             A and B are location scenarios
             Scenario #1) If a point between P1 to M. Since the point is closer to P1, hence the 'closestPoint' will be A, and 'firstPointOnInitialPath' will be P1
             Scenario #2) If a point between M to P2. Since the point is closer to P2, hence the 'closestPoint' will be P2, and 'firstPointOnInitialPath' will be P2
             */
            CGPoint closestPoint = [self findClosestPointOnPath:initialPath usingPoint:self._startingPoint];
            
            // The first point on the path
            CGPoint firstPointOnInitialPath = [(NSValue *)[pathPoints firstObject] CGPointValue]; // the first point on the initial path
            firstPointOnInitialPath = [self convertToInsidePointFromPoint:firstPointOnInitialPath];
            
            /*
             distanceBetweenFirstPointAndClosestPoint
             if distance == 0
             scenario 2
             else
             otherwise scenario 1.
             */
            int distanceBetweenFirstPointAndClosestPoint = [self distanceBetweenInsidePoint:closestPoint andPoint:firstPointOnInitialPath];
            
            CGPoint startingPoint;
            if (distanceBetweenFirstPointAndClosestPoint == 0) { // Scenario #2. Has not reached the first point yet
                startingPoint = [self convertToOutsidePointFromPoint:self._startingPoint];
                NSMutableArray *tempArray = [[NSMutableArray alloc] init];
                [tempArray addObject:[NSValue valueWithCGPoint:startingPoint]];
                [tempArray addObjectsFromArray:pathPoints];
                pathPoints = tempArray;
            } else { // Scenario #1. Has reached the point already
                // Need to override the first point with the closest point
                startingPoint = [self convertToOutsidePointFromPoint:self._startingPoint];
                [pathPoints setObject:[NSValue valueWithCGPoint:startingPoint] atIndexedSubscript:0];
            }
            
            CGPathRef finalPath = [self calculatePathUsingPoints:pathPoints];
            NSLog(@"wayPath2 = %@",finalPath);
            return finalPath;
        }
    }
    return NULL;
}


-(CGPathRef)renderWayfindingFromPoint:(CGPoint)p1 toPoint:(CGPoint)p2{
    _nodes = [self.wayFinderDelegate nodesForWayfinder];
    _graph = [self.wayFinderDelegate graphForWayfinder];
    
    MSTNode *startingNode = [self findNearestNodeToPoint:p1];
    MSTNode *destinationNode = [self findNearestNodeToPoint:p2];
    
    if (destinationNode) {
        
        if (_graph.isRunning) {
            _graph.canStop = true;
        }
        
        NSArray *path = [_graph findPathFrom:startingNode.nodeName to:destinationNode.nodeName];
        
        // If the path returns nil, do nothing
        // If the path count has no items, do nothing
        // If the path hasn't change, do nothing
        if ((path != nil || path.count > 0) && [self hasPathChanged:path]) {
            _previousPathArr = path;
            
            NSArray *reversedPath = [[path reverseObjectEnumerator] allObjects];
            NSLog(@"renderWayfindingFromPoint = %@",reversedPath);
            
            // Inform the delegate the path has changed.
            id <MSTWayfinderDelegate> strongDel = self.wayFinderDelegate;
            if ([strongDel respondsToSelector:@selector(pathHasChanged)]) {
                [strongDel pathHasChanged];
            }
            
            NSMutableArray *pathPoints = [[NSMutableArray alloc] init];
            [reversedPath enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                MSTNode *node = [_nodes objectForKey:obj];
                [pathPoints addObject:[NSValue valueWithCGPoint:node.nodePoint]];
            }];
            
            CGPathRef initialPath = [self calculatePathUsingPoints:pathPoints];
            
            /*
             Find point closest to the path
             P1----A----|M|----B----P2
             A and B are location scenarios
             Scenario #1) If a point between P1 to M. Since the point is closer to P1, hence the 'closestPoint' will be A, and 'firstPointOnInitialPath' will be P1
             Scenario #2) If a point between M to P2. Since the point is closer to P2, hence the 'closestPoint' will be P2, and 'firstPointOnInitialPath' will be P2
             */
            CGPoint closestPoint = [self findClosestPointOnPath:initialPath usingPoint:self._startingPoint];
            
            // The first point on the path
            CGPoint firstPointOnInitialPath = [(NSValue *)[pathPoints firstObject] CGPointValue]; // the first point on the initial path
            firstPointOnInitialPath = [self convertToInsidePointFromPoint:firstPointOnInitialPath];
            
            /*
             distanceBetweenFirstPointAndClosestPoint
             if distance == 0
             scenario 2
             else
             otherwise scenario 1.
             */
            int distanceBetweenFirstPointAndClosestPoint = [self distanceBetweenInsidePoint:closestPoint andPoint:firstPointOnInitialPath];
            
            CGPoint startingPoint;
            if (distanceBetweenFirstPointAndClosestPoint == 0) { // Scenario #2. Has not reached the first point yet
                startingPoint = [self convertToOutsidePointFromPoint:self._startingPoint];
                NSMutableArray *tempArray = [[NSMutableArray alloc] init];
                [tempArray addObject:[NSValue valueWithCGPoint:startingPoint]];
                [tempArray addObjectsFromArray:pathPoints];
                pathPoints = tempArray;
            } else { // Scenario #1. Has reached the point already
                // Need to override the first point with the closest point
                startingPoint = [self convertToOutsidePointFromPoint:self._startingPoint];
                [pathPoints setObject:[NSValue valueWithCGPoint:startingPoint] atIndexedSubscript:0];
            }
            
            CGPathRef finalPath = [self calculatePathUsingPoints:pathPoints];
            NSLog(@"renderWayfindingFromPoint %@ toPoint = %@ withPath = %@",NSStringFromCGPoint(p1),NSStringFromCGPoint(p2),finalPath);
            return finalPath;
        }
    }
    return NULL;
}


/**
 *  Check to see if they the wayfinding path has changed
 *
 *  @param newPathArr the new wayfinding path
 *
 *  @return true if it has changed, false otherwise
 */
-(bool)hasPathChanged:(NSArray *)newPathArr{
    if (_previousPathArr.count != newPathArr.count) {
        return true;
    }
    
    // Compare each of the value from path array to make sure they're identical.
    // If any of the values match return false.
    for (int i = 0; i < _previousPathArr.count; i++) {
        NSString *currentNodeNameAtIndex = _previousPathArr[i];
        NSString *newNodeNameAtIndex = newPathArr[i];
        if (![currentNodeNameAtIndex isEqualToString:newNodeNameAtIndex]) {
            return true;
        }
    }
    
    return false;
}

-(void)stopWayfinding{
    UIView *startingLocation = [self.subLayersDict objectForKey:@"sp"];
    [startingLocation removeFromSuperview];
    [self drawWayUsingPath:NULL enable:false];
    UIView *endingLocation = [self.subLayersDict objectForKey:@"ep"];
    [endingLocation removeFromSuperview];
    self.isWayfindingEnabled = false;
}

-(void)addSnaptoPathDot:(MSTLocationView *)view{
    if (![self.subLayersDict objectForKey:@"snap"]) {
        [self addDot:view forKey:@"snap"];
    }
}

-(void)addSnaptoPathDot2:(MSTLocationView *)view{
    if (![self.subLayersDict objectForKey:@"snap2"]) {
        [self addDot:view forKey:@"snap2"];
    }
}

-(bool)hasSnaptoPathDot{
    return ([self.subLayersDict objectForKey:@"snap"] != nil);
}

-(void)setSnaptoPathDot:(MSTLocationView *)view{
    view.hidden = true;
    [self addDot:view forKey:@"snap"];
}

-(bool)hasSnaptoPathDot2{
    return ([self.subLayersDict objectForKey:@"snap2"] != nil);
}

-(void)setSnaptoPathDot2:(MSTLocationView *)view{
    view.hidden = true;
    [self addDot:view forKey:@"snap2"];
}

-(void)drawSnapToPath:(CGPoint)point shouldMove:(bool)canMove shouldShowMotion:(bool)showMotion{
    MSTLocationView *view = [self.subLayersDict objectForKey:@"snap"];
    if (view.hasMoved) {
        view.hidden = false;
        
        [view showMotion:showMotion];
        
        if (canMove) {
            [UIView animateWithDuration:0.5 animations:^{
                view.layer.position = point;
            } completion:^(BOOL finished) {
                [self drawBreadcrumbAtPosition:point withColor:[UIColor redColor]];
            }];
        }
    } else {
        view.hasMoved = true;
        [self drawBreadcrumbAtPosition:point withColor:[UIColor greenColor]];
        view.layer.position = point;
    }
}

-(void)drawSnapToPathUsingCGPoint:(CGPoint )point shouldMove:(bool)canMove withDuration:(NSTimeInterval)duration{
    MSTLocationView *view = [self.subLayersDict objectForKey:@"snap2"];
    if (view.hasMoved) {
        view.hidden = false;
        
        [view renderColor:[UIColor greenColor]];
        
        if (canMove) {
            [UIView animateWithDuration:duration animations:^{
                view.layer.position = point;
            } completion:^(BOOL finished) {
                [self drawBreadcrumbAtPosition:point withColor:[UIColor greenColor]];
            }];
        }
    } else {
        view.hasMoved = true;
        [self drawBreadcrumbAtPosition:point withColor:[UIColor greenColor]];
        view.layer.position = point;
    }
}


-(void)removeSnapToPath{
    UIView *snapView = [self.subLayersDict objectForKey:@"snap"];
    if (snapView) {
        [snapView removeFromSuperview];
        [self.subLayersDict removeObjectForKey:@"snap"];
    }
}

-(void)removeSnapToPath2{
    UIView *snapView = [self.subLayersDict objectForKey:@"snap2"];
    if (snapView) {
        [snapView removeFromSuperview];
        [self.subLayersDict removeObjectForKey:@"snap2"];
    }
}

-(void)setOriginNodeUsingPoint:(CGPoint)point{
    self._startingPoint = point;
}

-(void)setDestinationNodeUsingPoint:(CGPoint)point{
    self._endingPoint = point;
    _destinationNode = [self findNearestNodeToPoint:self._endingPoint];
    
    NSLog(@"_destinationNode.nodePoint = %@",NSStringFromCGPoint(_destinationNode.nodePoint));
    
    UIView *endDot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    endDot.layer.position = _destinationNode.nodePoint;
    endDot.layer.cornerRadius = 10;
    endDot.backgroundColor = [UIColor purpleColor];
    NSString *key = @"ep"; // Keep track of only one destination view in the vie hierarchy
    id p = [self.subLayersDict objectForKey:key];
    if (p && [p isKindOfClass:[UIView class]]) {
        [p removeFromSuperview];
        [self.subLayersDict removeObjectForKey:key];
    }
    endDot.center = [self convertToInsidePointFromPoint:_destinationNode.nodePoint];
    [self.subLayersDict setObject:endDot forKey:key];
    [self.dotsView addSubview:endDot];
    
    // When the user specify the destination point, render the wayfinding.
    [self startWayfinding];
}

#pragma mark -

#pragma mark - Touch Events

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [[touches allObjects] firstObject];
    CGPoint point = [touch locationInView:self.floorImageView];
    if ([self.wayFinderDelegate respondsToSelector:@selector(receivedPoint:)]) {
        [self.wayFinderDelegate receivedPoint:point];
    }
    if ([self.wayFinderDelegate respondsToSelector:@selector(receivedOutsidePoint:)]) {
        [self.wayFinderDelegate receivedOutsidePoint:[self convertToOutsidePointFromPoint:point]];
    }
    if (self.isWayfindingEnabled) {
        [self setDestinationNodeUsingPoint:point];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [[touches allObjects] firstObject];
    CGPoint point = [touch locationInView:self.floorImageView];
    if ([self.wayFinderDelegate respondsToSelector:@selector(receivedPoint:)]) {
        [self.wayFinderDelegate receivedPoint:point];
    }
    if ([self.wayFinderDelegate respondsToSelector:@selector(receivedOutsidePoint:)]) {
        [self.wayFinderDelegate receivedOutsidePoint:[self convertToOutsidePointFromPoint:point]];
    }
    if (self.isWayfindingEnabled) {
        [self setDestinationNodeUsingPoint:point];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [[touches allObjects] firstObject];
    CGPoint point = [touch locationInView:self];
    if ([self.wayFinderDelegate respondsToSelector:@selector(receivedPoint:)]) {
        [self.wayFinderDelegate receivedPoint:point];
    }
    if ([self.wayFinderDelegate respondsToSelector:@selector(receivedOutsidePoint:)]) {
        [self.wayFinderDelegate receivedOutsidePoint:[self convertToOutsidePointFromPoint:point]];
    }
    if (self.isWayfindingEnabled) {
        [self setDestinationNodeUsingPoint:point];
    }
}

#pragma mark -

/**
 *  Convert the floorview point to cloud point
 *
 *  @param point accepts a point from the floorview
 *
 *  @return returns the the point inside the floorview without the scalefactor
 */
-(CGPoint)convertToOutsidePointFromPoint:(CGPoint)point{
    return CGPointMake(point.x/(self.scaleXFactor), point.y/(self.scaleYFactor));
}

/**
 *  Convert the cloud point to floorview point
 *
 *  @param point accepts a point from the cloud
 *
 *  @return returns the the point inside the floorview with the scalefactor
 */
-(CGPoint)convertToInsidePointFromPoint:(CGPoint)point{
    return CGPointMake(point.x*(self.scaleXFactor), point.y*(self.scaleYFactor));
}

-(NSUInteger)viewOrientation:(UIView *)view{
    if (view.bounds.size.width == view.bounds.size.height) {
        return UIViewOrientationSquare;
    } else if (view.bounds.size.width > view.bounds.size.height) {
        return UIViewOrientationHorizontal;
    } else if (view.bounds.size.width < view.bounds.size.height) {
        return UIViewOrientationVertical;
    } else {
        return UIViewOrientationSquare;
    }
}

-(CGFloat)getAngleBetweenPoint:(CGPoint)origin andPoint:(CGPoint)target{
    //    NSLog(@"",atan(p1.x-p0.x));
    
    CGFloat xd = target.x-origin.x;
    CGFloat yd = target.y-origin.y;
    
    CGFloat degree = 0;
    
    NSLog(@"%f %f %f %f %f %f %f",target.x,origin.x,target.y,origin.y,xd,yd,fabs(xd/yd));
    
    if(floor(yd) == 0){
        if (xd < 0) {
            return 90;
        } else {
            return -90;
        }
    } else if (floor(xd) == 0) {
        if (yd < 0) {
            return 180;
        } else {
            return 0;
        }
    } else if (xd < 0 && yd < 0) {
        degree = atan(fabs(xd/yd))*180/M_PI;
    } else if (xd > 0 && yd < 0) {
        degree = -(atan(fabs(xd/yd))*180/M_PI);
    } else if (xd < 0 && yd > 0) {
        degree = (90-(atan(fabs(xd/yd))*180/M_PI))+90;
    } else { // xd > 0 && yd > 0
        degree = (-90+(atan(fabs(xd/yd))*180/M_PI))-90;
    }
    
    return degree;
}

-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view{
    CGPoint newPoint = CGPointMake(view.bounds.size.width*anchorPoint.x, view.bounds.size.height*anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width*view.layer.anchorPoint.x, view.bounds.size.height*view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.y -= oldPoint.y;
    
    position.x += newPoint.x;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

-(void)centerView{
    self.layer.position = [self viewCenter];
}

-(CGPoint)viewCenter{
    return CGPointMake(self.superview.bounds.size.width/2, self.superview.bounds.size.height/2);
}

-(void)resetWayfinding{
    _hasMoved = true;
}

#pragma mark - UIGestureRecognizerDelegate

-(void)performPan:(UIPanGestureRecognizer *)sender{
    _hasMoved = true;
    CGPoint location = [sender locationInView:self];
    if (sender.state == UIGestureRecognizerStateBegan) {
        _begin = location;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        self.transform = CGAffineTransformTranslate(self.transform, location.x-_begin.x, location.y-_begin.y);
    } else if (sender.state == UIGestureRecognizerStateCancelled) {
    }
}

-(void)performRotate:(UIRotationGestureRecognizer *)sender{
    _hasMoved = true;
    if (sender.state == UIGestureRecognizerStateBegan) {
        
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        
        self.transform = CGAffineTransformRotate(self.transform, sender.rotation);
        sender.rotation = 0;
    } else {
        
    }
}

-(void)resetFloorplan{
    
    self.isAnimating = true;
    
    @synchronized (self) {
        
        [UIView animateWithDuration:1.0 animations:^{
            
            // scale the view back to normal
            UIViewOrientation o = [self viewOrientation:self];
            switch (o) {
                case UIViewOrientationSquare:
                    self.transform = CGAffineTransformMakeScale(self.bounds.size.width/self.bounds.size.width,self.bounds.size.height/self.bounds.size.height);
                    break;
                case UIViewOrientationHorizontal:
                    self.transform = CGAffineTransformMakeScale(self.bounds.size.width/self.bounds.size.width,self.bounds.size.width/self.bounds.size.width);
                    break;
                case UIViewOrientationVertical:
                    self.transform = CGAffineTransformMakeScale(self.bounds.size.height/self.bounds.size.height,self.bounds.size.height/self.bounds.size.height);
                    break;
                default:
                    break;
            }
            
            // reset bluedot
            [self.bluedot.layer setTransform:CATransform3DMakeScale(1, 1, 1)];
            [self.bluedot.layer setTransform:CATransform3DIdentity];
            
            // reset snaptopath
            [self.subLayersDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, UIView *obj, BOOL * _Nonnull stop) {
                [obj.layer setTransform:CATransform3DMakeScale(1, 1, 1)];
                [obj.layer setTransform:CATransform3DIdentity];
            }];
            
            // reset breadcrumbs
            [[self.breadcrumbsArray firstObject] enumerateObjectsUsingBlock:^(CALayer *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj setTransform:CATransform3DMakeScale(1, 1, 1)];
                [obj setTransform:CATransform3DIdentity];
                CGPoint prevPos = obj.position;
                [obj setFrame:CGRectMake(obj.position.x, obj.position.y, kMSTLocationViewSize.width, kMSTLocationViewSize.height)];
                obj.position = prevPos;
                obj.cornerRadius = kMSTLocationViewSize.width/2;
            }];
            
        } completion:^(BOOL finished) {
            self.isAnimating = false;
        }];
        
        [self setAnchorPoint:CGPointMake(0.5, 0.5) forView:self];
        self.layer.position = [self viewCenter];
        
        // update the scaleRatio so all assets can be scaled correctly
        _scaledRatio = _initialFrameSize.width/self.frame.size.width;
    }
}

-(void)performPinch:(UIPinchGestureRecognizer *)sender{
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        
        _hasMoved = true;
        
        // scale the view itself
        self.transform = CGAffineTransformScale(self.transform, sender.scale, sender.scale);
        
        @synchronized (self) {
            
            // scale bluedot
            self.bluedot.layer.transform = CATransform3DScale(self.bluedot.layer.transform, 1/sender.scale, 1/sender.scale, 1/sender.scale);
            
            // scale other sdk client dots
            [[self.breadcrumbsArray firstObject] enumerateObjectsUsingBlock:^(CALayer *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.transform = CATransform3DScale(obj.transform, 1/sender.scale, 1/sender.scale, 1/sender.scale);
            }];
            
            // scale other sdk client dots
            [self.otherSDKClientsContainerView.subviews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.layer.transform = CATransform3DScale(obj.layer.transform, 1/sender.scale, 1/sender.scale, 1/sender.scale);
            }];
            
            // scale STP dots
            [self.subLayersDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, UIView *obj, BOOL * _Nonnull stop) {
                obj.transform = CGAffineTransformScale(obj.transform, 1/sender.scale, 1/sender.scale);
            }];
        }
        
        sender.scale = 1;
        
        // update the scaleRatio so all assets can be scaled correctly
        _scaledRatio = _initialFrameSize.width/self.frame.size.width;
    }
}

#pragma mark -

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
            bc.shouldRasterize = true;
            bc.rasterizationScale = [UIScreen mainScreen].scale;
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
            bc.frame = CGRectMake(0, 0, kMSTLocationViewSize.width*_scaledRatio, kMSTLocationViewSize.height*_scaledRatio);
            bc.cornerRadius = (kMSTLocationViewSize.width*_scaledRatio/2);
            bc.position = point;
            bc.backgroundColor = [color CGColor];
            bc.shouldRasterize = true;
            bc.rasterizationScale = [UIScreen mainScreen].scale;
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
