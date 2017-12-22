//
//  Logger.m
//  MistSDK
//
//  Created by Mist on 7/1/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//


#import "Logger.h"
#import <UIKit/UIKit.h>

#define kMAXENTRIES 100

@interface Logger (){
    
}

@property (nonatomic) int numOfEntries;
@property (nonatomic) bool canWriteToFile;
@property (nonatomic, strong) NSMutableDictionary *currentLogs;

@end

@implementation Logger

+(instancetype)sharedInstance{
    static Logger *_logger = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _logger = [[self alloc] init];
    });
    return _logger;
}

-(id)init{
    self = [super init];
    if (self) {
        self.numOfEntries = 0;
        self.currentLogs = [[NSMutableDictionary alloc] init];
        self.canWriteToFile = false;
        if ([self _createLogsPathIfDoesNotExists]) {
            self.canWriteToFile = true;
        }
    }
    return self;
}

#pragma mark - basic logger

+(NSDateComponents *)getDateComponents{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *comp = [calendar components:(NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitYear|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitNanosecond) fromDate:now];
    return comp;
}

+(NSString *)getTimestamp{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"Y-m-d H:M:S z"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    return dateString;
}

-(void)log:(NSString *)message forReason:(NSString *)reason{
    bool verbose = true;
    if (verbose) {
        NSString *line = [NSString stringWithFormat:@"%@",message];
//        NSLog(@"ANY: = %@",line);
        [self _writeMessageToFile:[self _formatline:line] forType:reason];
    }
}

-(void)trace:(NSString *)message{
    bool verbose = true;
    if (verbose) {
        NSString *line = [NSString stringWithFormat:@"%@",message];
//        NSLog(@"TRACE: = %@",line);
        [self _writeMessageToFile:[self _formatline:line] forType:@"trace"];
    }
}

-(void)info:(NSString *)message{
    bool verbose = true;
    if (verbose) {
        NSString *line = [NSString stringWithFormat:@"%@",message];
//        NSLog(@"INFO: = %@",line);
        [self _writeMessageToFile:[self _formatline:line] forType:@"info"];
    }
}

-(void)debug:(NSString *)message{
    bool verbose = true;
    if (verbose) {
        NSString *line = [NSString stringWithFormat:@"%@",message];
//        NSLog(@"DEBUG: = %@",line);
        [self _writeMessageToFile:[self _formatline:line] forType:@"debug"];
    }
}

-(void)warn:(NSString *)message{
    bool verbose = true;
    if (verbose) {
        NSString *line = [NSString stringWithFormat:@"%@",message];
//        NSLog(@"WARN: = %@",line);
        [self _writeMessageToFile:[self _formatline:line] forType:@"warn"];
    }
}

-(void)error:(NSString *)message{
    bool verbose = true;
    if (verbose) {
        NSString *line = [NSString stringWithFormat:@"%@",message];
//        NSLog(@"ERROR: = %@",line);
        [self _writeMessageToFile:[self _formatline:line] forType:@"error"];
    }
}

-(void)fatal:(NSString *)message{
    bool verbose = true;
    if (verbose) {
        NSString *line = [NSString stringWithFormat:@"%@",message];
//        NSLog(@"FATAL: = %@",line);
        [self _writeMessageToFile:[self _formatline:line] forType:@"fatal"];
    }
}

-(void)infoPacket:(NSString *)message{
    bool verbose = true;
    if (verbose) {
        NSString *line = [NSString stringWithFormat:@"%@",message];
//        NSLog(@"infoPacket: = %@",line);
        [self _writeMessageToFile:[self _formatline:line] forType:@"infoPacket"];
    }
}

-(void)debugDancingDot:(NSString *)message{
    bool verbose = true;
    if (verbose) {
        NSString *line = [NSString stringWithFormat:@"%@",message];
//        NSLog(@"infoPacket: = %@",line);
        [self _writeMessageToFile:[self _formatline:line] forType:@"debugDancingDot"];
    }
}

-(NSString *)_formatline:(NSString *)msg{
    return [NSString stringWithFormat:@"%@---%@\n", [Logger getTimestamp], msg];
}

#pragma mark -

#pragma mark - file logger

-(void)_writeMessageToFile:(NSString *)message forType:(NSString *)type{
    if (self.canWriteToFile) {
        @synchronized (self) {
            
            if ([self.currentLogs objectForKey:type] == nil) {
                [self.currentLogs setObject:[[NSMutableArray alloc] init] forKey:type];
            }
            
            NSMutableArray *logsForType = [self.currentLogs objectForKey:type];
            
            [logsForType addObject:message];
            
            // if the log type fill up, flush to the file
            if ([[self.currentLogs objectForKey:type] count] > kMAXENTRIES) {
                [self flushToFile];
            }
        }
    } else {
        NSLog(@"Cannot write to log file :(");
    }
    
    // Write to Firebase for Remote Logging

}

-(NSString *)_createLogsPathIfDoesNotExists{
    NSString *documentDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0];
    NSString *logsPath = [documentDirectoryPath stringByAppendingString:@"/Logs"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:logsPath]) {
        
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:logsPath withIntermediateDirectories:false attributes:nil error:&error];
        if (error != nil) {
            NSLog(@"Cannot create logs folder for storing emergency logs. %@", error);
            return nil;
        }
    }
    return logsPath;
}

-(NSString *)_getLogFilepathForType:(NSString *)type{
    NSString *logsPath = [self _createLogsPathIfDoesNotExists];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *comp = [calendar components:(NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitYear) fromDate:now];
    
    // prefix the file with orgID in order organize it. Just need to set fileprefx prop
    
    NSString *prefix;
    if (self.filePrefix) {
        prefix = [NSString stringWithFormat:@"%@_%@",self.filePrefix, type];
    } else {
        prefix = @"none";
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@_logs_%ld-%ld-%ld.txt", prefix, [comp month], [comp day], (long)[comp year]];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", logsPath, fileName];
    
    return filePath;
}

-(void)flushToFile{
    @synchronized (self) {
        
        // for each log type (debug, warning, error, etc)
        [self.currentLogs enumerateKeysAndObjectsUsingBlock:^(NSString *type, NSMutableArray *logs, BOOL * _Nonnull stop) {
            
            // get the filepath for the log type (debug, warning, error, etc)
            NSString *filepath = [self _getLogFilepathForType:type];
            
            // check if file exists, if it doesn't exists, create one
            if (![[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
                [[NSFileManager defaultManager] createFileAtPath:filepath contents:nil attributes:nil];
            }
            
            // seek to the end of the file, per type
            NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:filepath];
            [fileHandler seekToEndOfFile];
            
            // write the logs for each type of log
            [logs enumerateObjectsUsingBlock:^(NSString *entry, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSData *data = [entry dataUsingEncoding:NSUTF8StringEncoding];
                
                [fileHandler writeData:data];
            }];
            
            // close file when it's done
            [fileHandler closeFile];
        }];
        
        // clear the cached logs
        [self.currentLogs removeAllObjects];
    }
}

-(NSMutableDictionary *)getAllLogFiles{
    NSString *logsPath = [self _createLogsPathIfDoesNotExists];
    
    NSError *error;
    NSArray *logFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsPath error:&error];
    if (error != nil) {
        NSLog(@"Cannot file logs file at %@", logsPath);
    }
    
    NSMutableDictionary *allLogFilesToBeSent = [[NSMutableDictionary alloc] initWithCapacity:logFiles.count];
    
    [logFiles enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSLog(@"LOG FILES: filename = %@", filename);
        
        NSData *contents = [[NSFileManager defaultManager] contentsAtPath:[logsPath stringByAppendingFormat:@"/%@", filename]];
        if (contents) {
            [allLogFilesToBeSent setObject:contents forKey:filename];
        }
        
    }];
    
    return allLogFilesToBeSent;
}

-(void)clearCurrentLogs{
    @synchronized (self) {
        // flushes all the remaining data
        [self flushToFile];
        
        // cleared
        self.currentLogs = [[NSMutableDictionary alloc] init];
    }
}

-(unsigned int)clearAllLogFilesAfter:(unsigned int)days{
    __block unsigned int filesRemoved = 0;
    
    // remove all log files and start over
    NSString *logsPath = [self _createLogsPathIfDoesNotExists];
    
    NSError *error;
    NSArray *logFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsPath error:&error];
    if (error != nil){
        NSLog(@"Encounter error while fetching all items from path = %@", logsPath);
    }
    
    [logFiles enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger idx, BOOL * _Nonnull stop) {
        NSError *error;
        NSString *filepath = [logsPath stringByAppendingFormat:@"/%@", filename];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filepath error:&error];
        if (error != nil){
            NSLog(@"Encounter error while getting attributes for path = %@", filepath);
        }
        
        if (fileAttributes != nil) {
            // if the files hasn't been modified for x days, remove them
            NSDate *creationDate = (NSDate *)[fileAttributes objectForKey:NSFileModificationDate];
            NSTimeInterval timeDelta = [creationDate timeIntervalSinceNow];
            if (timeDelta < -60*60*24*days) { // if the file is created more than 7 days ago
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:filepath error:&error];
                if (error != nil) {
                    NSLog(@"Encounter error while removing item from path = %@", logsPath);
                } else {
                    NSLog(@"Removed files older than %id at path = %@", days, filepath);
                    filesRemoved += 1;
                }
            }
        }
    }];
    
    return filesRemoved;
}

@end

