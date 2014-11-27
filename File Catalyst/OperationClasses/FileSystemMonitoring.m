//
//  FileSystemMonitoring.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 19/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileSystemMonitoring.h"

NSString *notificationDirectoryChange = @"FileSystemNotification";
NSString *pathsKey = @"changedPath";
NSString *flagsKey = @"flags";

void  myCallbackFunction ( ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    //void  myCallbackFunction ( ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, CFArrayRef eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {

    int i;
    CFArrayRef paths = eventPaths;

    // printf("Callback called\n");
    for (i=0; i<numEvents; i++) {
        CFStringRef path = CFArrayGetValueAtIndex(paths, i);
        NSString *tollfreestring = (__bridge NSString *)(path);
        NSString *nspath = [NSString stringWithString:tollfreestring]; // This is to resolve a BAD_EXEC problem
                                                                        // A copy needs to be done to avoid conflicts between ARC and CoreFoundation
        /* flags are unsigned long, IDs are uint64_t */
        NSLog(@"Change %llu in %@, flags %X\n", eventIds[i], path, (unsigned int)eventFlags[i]);


    /* Checks :
     kFSEventStreamEventFlagMustScanSubDirs // Whether the directory structure suffered radical changes
     kFSEventStreamEventFlagRootChanged  // When the root was copied, moved or deleted
     kFSEventStreamEventFlagEventIdsWrapped // Whether the ID rolled over (not likely)
     FSEventStreamCopyPathsBeingWatched // Don't really understand why. It seems that we will receive just information about the directories being watched.
     kFSEventStreamEventFlagMount // Whether a mount was done under the path being monitored
     */
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              nspath ,pathsKey,
                              [NSNumber numberWithInt:eventFlags[i]],flagsKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDirectoryChange object:nil userInfo:info];
    }

}



//@implementation FileSystemMonitoring
//
//-(FSEventStreamRef) initFSEventStream:(NSArray*) pathsToMonitor {
//    if (stream==nil) { // Creates a new one
//        /* Define variables and create a CFArray object containing
//         CFString objects containing paths to watch.
//         */
//        //CFStringRef mypath = (__bridge CFStringRef)(path);
//        CFStringRef mypath = CFSTR("/Users/vika/Downloads");
//
//        CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&mypath, 1, NULL);
//        //CFArrayRef pathsToWatch = CFBridgingRetain(pathsToMonitor);
//        void *callbackInfo = NULL; // could put stream-specific data here.
//
//        CFAbsoluteTime latency = 3.0; /* Latency in seconds */
//
//        /* Create the stream, passing in a callback */
//        stream = FSEventStreamCreate(NULL,
//                                     &myCallbackFunction,
//                                     callbackInfo,
//                                     pathsToWatch,
//                                     kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
//                                     latency,
//                                     //kFSEventStreamCreateFlagNone /* Flags explained in reference */
//                                     kFSEventStreamCreateFlagWatchRoot /* Monitors if the Root disappears*/
//                                     // | kFSEventStreamCreateFlagUseCFTypes
//                                     );
//    }
//    else {
//        // Changes the existing one
//    }
//    return stream;
//
//}
//
//-(void) main {
//    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
//    BOOL OK = FSEventStreamStart(stream);
//    while(1) {
//        //NSLog(@"This is the mon thread");
//        sleep(1);
//        // Keeping the thread alive just for debug
//    }
//}
//
//-(void) stop {
//    FSEventStreamStop(stream);
//    FSEventStreamInvalidate(stream);
//}
//
//
//
//@end

