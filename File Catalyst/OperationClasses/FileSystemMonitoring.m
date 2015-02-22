//
//  FileSystemMonitoring.m
//  File Catalyst
//
//  Created by Nuno Brum on 19/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileSystemMonitoring.h"

NSString *notificationDirectoryChange = @"FileSystemNotification";
NSString *pathsKey = @"changedPath";
NSString *flagsKey = @"flags";


void LogFlags(unsigned int flags) {

            /*
             * Your application must rescan not just the directory given in the
             * event, but all its children, recursively. This can happen if there
             * was a problem whereby events were coalesced hierarchically. For
             * example, an event in /Users/jsmith/Music and an event in
             * /Users/jsmith/Pictures might be coalesced into an event with this
             * flag set and path=/Users/jsmith. If this flag is set you may be
             * able to get an idea of whether the bottleneck happened in the
             * kernel (less likely) or in your client (more likely) by checking
             * for the presence of the informational flags
             * kFSEventStreamEventFlagUserDropped or
             * kFSEventStreamEventFlagKernelDropped.
             */

    if (flags & kFSEventStreamEventFlagMustScanSubDirs) {
        NSLog(@"kFSEventStreamEventFlagMustScanSubDirs");

    }

    /*
     * The kFSEventStreamEventFlagUserDropped or
     * kFSEventStreamEventFlagKernelDropped flags may be set in addition
     * to the kFSEventStreamEventFlagMustScanSubDirs flag to indicate
     * that a problem occurred in buffering the events (the particular
     * flag set indicates where the problem occurred) and that the client
     * must do a full scan of any directories (and their subdirectories,
     * recursively) being monitored by this stream. If you asked to
     * monitor multiple paths with this stream then you will be notified
     * about all of them. Your code need only check for the
     * kFSEventStreamEventFlagMustScanSubDirs flag; these flags (if
     * present) only provide information to help you diagnose the problem.
     */
    if (flags & kFSEventStreamEventFlagUserDropped)
        NSLog(@"kFSEventStreamEventFlagUserDropped");

    if (flags & kFSEventStreamEventFlagKernelDropped)
        NSLog(@"kFSEventStreamEventFlagKernelDropped");


    /*
     * If kFSEventStreamEventFlagEventIdsWrapped is set, it means the
     * 64-bit event ID counter wrapped around. As a result,
     * previously-issued event ID's are no longer valid arguments for the
     * sinceWhen parameter of the FSEventStreamCreate...() functions.
     */
    if (flags & kFSEventStreamEventFlagEventIdsWrapped)
        NSLog(@"kFSEventStreamEventFlagEventIdsWrapped");

    /*
     * Denotes a sentinel event sent to mark the end of the "historical"
     * events sent as a result of specifying a sinceWhen value in the
     * FSEventStreamCreate...() call that created this event stream. (It
     * will not be sent if kFSEventStreamEventIdSinceNow was passed for
     * sinceWhen.) After invoking the client's callback with all the
     * "historical" events that occurred before now, the client's
     * callback will be invoked with an event where the
     * kFSEventStreamEventFlagHistoryDone flag is set. The client should
     * ignore the path supplied in this callback.
     */
    if (flags & kFSEventStreamEventFlagHistoryDone)
        NSLog(@"kFSEventStreamEventFlagHistoryDone");

    /*
     * Denotes a special event sent when there is a change to one of the
     * directories along the path to one of the directories you asked to
     * watch. When this flag is set, the event ID is zero and the path
     * corresponds to one of the paths you asked to watch (specifically,
     * the one that changed). The path may no longer exist because it or
     * one of its parents was deleted or renamed. Events with this flag
     * set will only be sent if you passed the flag
     * kFSEventStreamCreateFlagWatchRoot to FSEventStreamCreate...() when
     * you created the stream.
     */
    if (flags & kFSEventStreamEventFlagRootChanged)
        NSLog(@"kFSEventStreamEventFlagRootChanged");

    /*
     * Denotes a special event sent when a volume is mounted underneath
     * one of the paths being monitored. The path in the event is the
     * path to the newly-mounted volume. You will receive one of these
     * notifications for every volume mount event inside the kernel
     * (independent of DiskArbitration). Beware that a newly-mounted
     * volume could contain an arbitrarily large directory hierarchy.
     * Avoid pitfalls like triggering a recursive scan of a non-local
     * filesystem, which you can detect by checking for the absence of
     * the MNT_LOCAL flag in the f_flags returned by statfs(). Also be
     * aware of the MNT_DONTBROWSE flag that is set for volumes which
     * should not be displayed by user interface elements.
     */
    if (flags & kFSEventStreamEventFlagMount)
        NSLog(@"kFSEventStreamEventFlagMount");

    /*
     * Denotes a special event sent when a volume is unmounted underneath
     * one of the paths being monitored. The path in the event is the
     * path to the directory from which the volume was unmounted. You
     * will receive one of these notifications for every volume unmount
     * event inside the kernel. This is not a substitute for the
     * notifications provided by the DiskArbitration framework; you only
     * get notified after the unmount has occurred. Beware that
     * unmounting a volume could uncover an arbitrarily large directory
     * hierarchy, although Mac OS X never does that.
     */
    if (flags & kFSEventStreamEventFlagUnmount)
        NSLog(@"kFSEventStreamEventFlagUnmount");

    /* These flags are only set if you specified the FileEvents*/
    /* flags when creating the stream.*/
    if (flags & kFSEventStreamEventFlagItemCreated)
        NSLog(@"kFSEventStreamEventFlagItemCreated");

    if (flags & kFSEventStreamEventFlagItemRemoved)
        NSLog(@"kFSEventStreamEventFlagItemRemoved");

    if (flags & kFSEventStreamEventFlagItemInodeMetaMod)
        NSLog(@"kFSEventStreamEventFlagItemInodeMetaMod");

    if (flags & kFSEventStreamEventFlagItemRenamed)
        NSLog(@"kFSEventStreamEventFlagItemRenamed");

    if (flags & kFSEventStreamEventFlagItemModified)
        NSLog(@"kFSEventStreamEventFlagItemModified");

    if (flags & kFSEventStreamEventFlagItemFinderInfoMod)
        NSLog(@"kFSEventStreamEventFlagItemFinderInfoMod");

    if (flags & kFSEventStreamEventFlagItemChangeOwner)
        NSLog(@"kFSEventStreamEventFlagItemChangeOwner");

    if (flags & kFSEventStreamEventFlagItemXattrMod)
        NSLog(@"kFSEventStreamEventFlagItemXattrMod");

    if (flags & kFSEventStreamEventFlagItemIsFile)
        NSLog(@"kFSEventStreamEventFlagItemIsFile");

    if (flags & kFSEventStreamEventFlagItemIsDir)
        NSLog(@"kFSEventStreamEventFlagItemIsDir");

    if (flags & kFSEventStreamEventFlagItemIsSymlink)
        NSLog(@"kFSEventStreamEventFlagItemIsSymlink");

    if (flags & kFSEventStreamEventFlagOwnEvent)
        NSLog(@"kFSEventStreamEventFlagOwnEvent");
    if (flags & 0xFFF00000) {
        NSLog(@"Unknown %X",flags & 0xFFF00000);
    }
}

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
        //NSLog(@"Change %llu in %@\n", eventIds[i], path);
        //LogFlags((unsigned int)eventFlags[i]);


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




@implementation FileSystemMonitoring

-(FileSystemMonitoring*) configureFSEventStream:(NSArray*) pathsToMonitor {
    /* Define variables and create a CFArray object containing
     CFString objects containing paths to watch.
     */
    NSUInteger numberOfPaths = [pathsToMonitor count];
    monitoredPaths = CFArrayCreateMutable(kCFAllocatorDefault, numberOfPaths, NULL);

    for (int i=0; i < numberOfPaths ; i++) {

        CFStringRef mypath = CFBridgingRetain([[pathsToMonitor objectAtIndex:i] path]);
        CFArraySetValueAtIndex(monitoredPaths, i, mypath);
    }

    //CFStringRef mypath = CFSTR("/Users/vika/Downloads");

    void *callbackInfo = NULL; // could put stream-specific data here.

    CFAbsoluteTime latency = 0.5; /* Latency in seconds */

    /* Create the stream, passing in a callback */
    stream = FSEventStreamCreate(NULL,
                                 &myCallbackFunction,
                                 callbackInfo,
                                 monitoredPaths,
                                 kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
                                 latency,
                                 kFSEventStreamCreateFlagNone // No FLags : Base
                                 | kFSEventStreamCreateFlagUseCFTypes // Uses CoreFoundation instead of plain C/C++ variables
                                 | kFSEventStreamCreateFlagNoDefer // Immediate delivery when the last event is aged more than latency time
                                 | kFSEventStreamCreateFlagWatchRoot // Monitors if the Root disappears
                                 // | kFSEventStreamCreateFlagIgnoreSelf
                                 // | kFSEventStreamCreateFlagFileEvents
                                 // | kFSEventStreamCreateFlagMarkSelf
                                 
                                                                  );
    return self;

}




-(void) main {
    CFRunLoopRef cfRunLoop  = CFRunLoopGetCurrent();
    FSEventStreamScheduleWithRunLoop(stream, cfRunLoop, kCFRunLoopDefaultMode);
    BOOL OK = FSEventStreamStart(stream);
    //NSLog(@"The task was created %d", OK);
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode]; // adding some input source, that is required for runLoop to runing
    while (![self isCancelled] && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]); // starting infinite loop which can be stopped by changing the shouldKeepRunning's value
    
}

-(void) cancel {
    FSEventStreamStop(stream);
    FSEventStreamInvalidate(stream);
    CFRelease(monitoredPaths);
    [super cancel];
    while (![self isCancelled]) {
        NSLog(@".");
    }
}

-(void) dealloc {
    [self cancel];
}

@end

