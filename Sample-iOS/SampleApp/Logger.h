//
//  Logger.h
//  MistSDK
//
//  Created by Mist on 7/1/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Logger : NSObject

@property (nonatomic, strong) NSString *filePrefix;

+(instancetype)sharedInstance;

// log to for reason
-(void)log:(NSString *)message forReason:(NSString *)reason;

-(void)trace:(NSString *)message;
-(void)info:(NSString *)message;
-(void)debug:(NSString *)message;
-(void)warn:(NSString *)message;
-(void)error:(NSString *)message;
-(void)fatal:(NSString *)message;
-(void)infoPacket:(NSString *)message;
-(void)debugDancingDot:(NSString *)message;

// Flushes all cached logs to files
-(void)flushToFile;

// Get all the logs from files
-(NSMutableDictionary *)getAllLogFiles;

// Clear the current logs, when switching between orgs
-(void)clearCurrentLogs;

// WARNING:
// Remove all logs files not modified more than 7 days.
// Only should use if your logs are filling up too much spage.
-(unsigned int)clearAllLogFilesAfter:(unsigned int)days;

@end
