//
//  FileSystemMonitoring.h
//  File Catalyst
//
//  Created by Nuno Brum on 19/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

extern NSString *notificationDirectoryChange;
extern NSString *pathsKey;
extern NSString *flagsKey;

extern void LogFlags(unsigned int flags); // Debug Function

extern void  myCallbackFunction ( ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@interface FileSystemMonitoring : NSThread {
    FSEventStreamRef stream;
    CFMutableArrayRef monitoredPaths;
}

-(FileSystemMonitoring*) configureFSEventStream:(NSArray*) pathsToMonitor;

@end
