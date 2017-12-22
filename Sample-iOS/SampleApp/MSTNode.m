//
//  MSTNode.m
//  Wayfinding
//
//  Created by Mist on 7/23/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import "MSTNode.h"

@implementation MSTNode

-(instancetype)initWithName:(NSString *)nodeName andPoint:(CGPoint)nodePoint andEdges:(NSDictionary *)edges{
    if (self = [super init]) {
        self.nodeName = nodeName;
        self.nodePoint = nodePoint;
        self.edges = [edges mutableCopy];
    }
    return self;
}

-(NSString *)showEdges{
    __block NSMutableString *json = [[NSMutableString alloc] init];
    [self.edges enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *kv = [NSString stringWithFormat:@"\"%@\":\"%@\",",key,obj];
        [json appendString:kv];
    }];
    json = [[json stringByReplacingCharactersInRange:(NSRange){json.length-1,1} withString:@""] mutableCopy];
    return json;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"\"name\":\"%@\",\n\"position\":{\"x\":%f,\"y\":%f},\"edges\":{%@}", self.nodeName,self.nodePoint.x,self.nodePoint.y,[self showEdges]];
    
}

@end
