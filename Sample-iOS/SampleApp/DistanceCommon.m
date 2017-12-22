//
//  DistanceCommon.m
//  Mist
//
//  Created by Cuong Ta on 8/8/16.
//  Copyright © 2016 mist. All rights reserved.
//

#import "DistanceCommon.h"

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (x * (180.0/M_PI))

@implementation DistanceCommon

+(double)distanceBetweenPoint:(CGPoint)a andPoint:(CGPoint)b{
    return sqrt(pow(a.x-b.x, 2)+pow(a.y-b.y, 2));
}

NSString* JRNSStringFromCATransform3D(CATransform3D transform) {
    // format: [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1]
    
    return CATransform3DIsIdentity(transform)
    ? @"CATransform3DIdentity"
    : [NSString stringWithFormat:@"[%@ %@ %@ %@; %@ %@ %@ %@; %@ %@ %@ %@; %@ %@ %@ %@]",
       prettyFloat(transform.m11),
       prettyFloat(transform.m12),
       prettyFloat(transform.m13),
       prettyFloat(transform.m14),
       prettyFloat(transform.m21),
       prettyFloat(transform.m22),
       prettyFloat(transform.m23),
       prettyFloat(transform.m24),
       prettyFloat(transform.m31),
       prettyFloat(transform.m32),
       prettyFloat(transform.m33),
       prettyFloat(transform.m34),
       prettyFloat(transform.m41),
       prettyFloat(transform.m42),
       prettyFloat(transform.m43),
       prettyFloat(transform.m44)
       ];
}

+(CLLocationCoordinate2D) getLatitudeLongitudeUsingMapOrigin:(CLLocationCoordinate2D)mapOrigin forPoint:(CGPoint)point{
    CLLocationCoordinate2D newCoord = CLLocationCoordinate2DMake(0, 0);
    MKCoordinateRegion tempRegion = MKCoordinateRegionMakeWithDistance(mapOrigin, point.y, point.x);
    MKCoordinateSpan tempSpan = tempRegion.span;
    newCoord.latitude = mapOrigin.latitude - tempSpan.latitudeDelta;
    newCoord.longitude = mapOrigin.longitude + tempSpan.longitudeDelta;
    return newCoord;
}

+(CLLocationCoordinate2D)transformToLatLongFromPoint:(CGPoint)point offsetFromNorthByDeg:(CGFloat)offsetDegree withMapOrigin:(CLLocationCoordinate2D)mapOrigin{
    CGPoint xyCoord = point;
    CGPoint offsetFromNorthCoord = CGPointApplyAffineTransform(xyCoord, CGAffineTransformMakeRotation(degreesToRadians(offsetDegree)));
    CLLocationCoordinate2D latlong = [DistanceCommon getLatitudeLongitudeUsingMapOrigin:mapOrigin forPoint:offsetFromNorthCoord];
    return latlong;
}

static NSString* prettyFloat(CGFloat f) {
    if (f == 0) {
        return @"0";
    } else if (f == 1) {
        return @"1";
    } else {
        return [NSString stringWithFormat:@"%.3f", f];
    }
}


@end
