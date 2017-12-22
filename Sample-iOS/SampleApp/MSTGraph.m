//
//  MSTGraph.m
//  Mist
//
//  Created by Mist on 7/21/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import "MSTGraph.h"
//#import "MSTVertex.h"

@interface Queue : NSObject

@property (nonatomic, strong) NSMutableArray *queue;

@end

@implementation Queue

-(instancetype)init{
    if (self = [super init]) {
        @synchronized (self.queue) {
            self.queue = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

-(void)purgeQueue{
    @synchronized (self.queue) {
        [self.queue removeAllObjects];
    }
}

-(void)enqueue:(NSString *)key andValue:(NSNumber *)priority{
    @synchronized (self.queue) {
        [self.queue addObject:@{@"key":key,@"priority":priority}];
        
        [self.queue sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            return [obj1[@"priority"] compare:obj2[@"priority"]];
        }];
    }
}

-(NSDictionary *)dequeue{
    @synchronized (self.queue) {
        NSDictionary *smallest = [self.queue firstObject];
        [self.queue removeObjectAtIndex:0];
        return smallest;
    }
}

-(bool)isEmpty{
    @synchronized (self.queue) {
        return (self.queue.count == 0);
    }
}

@end

@interface MSTGraph ()

@property (nonatomic, strong) Queue *queue;
@property (nonatomic, strong) NSMutableDictionary *vertices;
@property (nonatomic, strong) NSMutableDictionary *dist;
@property (nonatomic, strong) NSMutableDictionary *prev;

@end

@implementation MSTGraph

-(instancetype)init{
    if (self = [super init]) {
        self.vertices = [[NSMutableDictionary alloc] init];
        self.queue = [[Queue alloc] init];
        self.dist = [[NSMutableDictionary alloc] init];
        self.prev = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)addVertex:(NSString *)vertex withEdges:(NSDictionary *)dict{
    [self.vertices setObject:dict forKey:vertex];
}

-(NSArray *)findPathFrom:(NSString *)start to:(NSString*)end{
    [self.queue purgeQueue];
    NSMutableArray *path;
    for (NSString *vertex in self.vertices) {
        if ([vertex isEqualToString:start]) {
            self.dist[vertex] = [NSNumber numberWithInt:0];
            self.prev[vertex] = [NSNull null];
            [self.queue enqueue:vertex andValue:[NSNumber numberWithInt:0]];
        } else {
            self.dist[vertex] = [NSNumber numberWithInt:9999999];
            self.prev[vertex] = [NSNull null];
            [self.queue enqueue:vertex andValue:[NSNumber numberWithInt:9999999]];
        }
        if (self.canStop) {
            break;
        }
    }
    if (self.canStop) {
        return path;
    }
    while (![self.queue isEmpty]) {
        NSDictionary *node = [self.queue dequeue];
        NSString *smallest = [node objectForKey:@"key"];
        if ([smallest isEqualToString:end]) {
            path = [[NSMutableArray alloc] init];
            [path addObject:smallest];
            while (self.prev[smallest] != [NSNull null]) {
                smallest = self.prev[smallest];
                [path addObject:smallest];
            }
            return path;
        }
        
        for (NSString *neighbor in self.vertices[smallest]) {
            NSNumber *alt = [NSNumber numberWithInteger:([self.dist[smallest] integerValue]+[self.vertices[smallest][neighbor] integerValue])];
            if (alt < self.dist[neighbor]) {
                self.dist[neighbor] = alt;
                self.prev[neighbor] = smallest;
                [self.queue enqueue:neighbor andValue:alt];
            }
            if (self.canStop) {
                break;
            }
        }
        if (self.canStop) {
            break;
        }
    }
    
    return path;
}

/*
 * Returns the object with the path from fromV to toV
 * [A,B,C,D,E]
 */
//-(NSDictionary *)findPath:(MSTGraph *)graph fromVertex:(MSTVertex*)fromV toVertex:(MSTVertex*)toV{
//    return nil;
//}

@end
