//
//  TreeScanOperation.m
//  File Catalyst
//
//  Created by Nuno Brum on 15/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "TreeScanOperation.h"
#import "TreeRoot.h"
#import "MyDirectoryEnumerator.h"
#import "Definitions.h"

// key for obtaining the associated TreeRoot
NSString *kTreeRootKey = @"treeRoot";

NSString *notificationTreeConstructionFinished = @"TreeFinished";


@implementation TreeScanOperation

-(void) main {
    if (![self isCancelled])
	{
        NSString *rootPath = [_taskInfo objectForKey: kRootPathKey];
        NSNumber *mode = [_taskInfo objectForKey: kModeKey];

        /* Abort if problem detected */
        if (rootPath==nil || mode==nil) {
            /* Should it be decided to inform */
        }
        else {
            NSURL *rootURL = [NSURL fileURLWithPath:rootPath isDirectory:YES];

            //NSLog(@"From thread ! Scanning directory %@", rootPath);
            MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:rootURL WithMode:[mode integerValue]];
            TreeRoot *rootDir = [TreeRoot treeFromEnumerator:dirEnumerator
                                                         URL:rootURL
                                                      parent:nil
                                                 cancelBlock:^(){
                                                     statusCount++;
                                                     return [self isCancelled];
                                                 }];

            if (![self isCancelled])
            {
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                      rootDir, kTreeRootKey,
                                      _operationID, kOperationCountKey,  // pass back to check if user cancelled/started a new scan
                                      nil];
                // for the purposes of this sample, we're just going to post the information
                // out there and let whoever might be interested receive it (in our case its MyWindowController).
                //
                [_taskInfo addEntriesFromDictionary:info];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationTreeConstructionFinished object:self userInfo:_taskInfo];
            }
        }
    }
}

@end
