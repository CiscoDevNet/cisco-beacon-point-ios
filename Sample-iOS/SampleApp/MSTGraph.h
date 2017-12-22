//
//  MSTGraph.h
//  Mist
//
//  Created by Mist on 7/21/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSTGraph : NSObject

@property (nonatomic, assign) bool canStop;
@property (nonatomic, assign) bool isRunning;

/**
 *  Initialize the MSTGraph
 *
 *  @return returns the instance of MSTGraph
 */
-(id)init;

/**
 *  Add vertext to the graph
 *
 *  @param vertex the vertex name
 *  @param dict   the vertex edge definition
 */
-(void)addVertex:(NSString *)vertex withEdges:(NSDictionary *)dict;

/**
 *  Find the path from vertex name start to end
 *
 *  @param start vertex name
 *  @param end   vertex name
 *
 *  @return returns the array of the path
 */
-(NSArray *)findPathFrom:(NSString *)start to:(NSString*)end;

@end
