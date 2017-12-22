//
//  MSTNode.h
//  Wayfinding
//
//  Created by Mist on 7/23/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MSTCoordinateType){
    MSTCoordinateTypeDestination = 0,
    MSTCoordinateTypeGeneric
};

@interface MSTNode : NSObject

@property (nonatomic) CGPoint nodePoint;
@property (nonatomic) MSTCoordinateType coordinateType;
@property (nonatomic, strong) NSMutableDictionary *edges;
@property (nonatomic, strong) NSString *nodeName;

-(instancetype)initWithName:(NSString *)nodeName andPoint:(CGPoint)nodePoint andEdges:(NSDictionary *)edges;

@end
