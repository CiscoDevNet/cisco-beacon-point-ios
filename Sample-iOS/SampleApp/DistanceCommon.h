//
//  DistanceCommon.h
//  Mist
//
//  Created by Cuong Ta on 8/8/16.
//  Copyright © 2016 mist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface DistanceCommon : NSObject

+(double)distanceBetweenPoint:(CGPoint)a andPoint:(CGPoint)b;// reset bluedot

+(CLLocationCoordinate2D) getLatitudeLongitudeUsingMapOrigin:(CLLocationCoordinate2D)mapOrigin forPoint:(CGPoint)point;

+(CLLocationCoordinate2D)transformToLatLongFromPoint:(CGPoint)point offsetFromNorthByDeg:(CGFloat)offsetDegree withMapOrigin:(CLLocationCoordinate2D)mapOrigin;

NSString* JRNSStringFromCATransform3D(CATransform3D transform);

@end
