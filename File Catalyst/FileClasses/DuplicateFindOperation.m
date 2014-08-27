//
//  DuplicateFindOperation.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 26/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "Definitions.h"
#import "DuplicateFindOperation.h"
#import "MyDirectoryEnumerator.h"
#import "FileCollection.h"

NSString *kDuplicateList = @"DuplicateList";

@interface DuplicateFindOperation ()
{
    NSMutableDictionary *_taskInfo;
    NSNumber *ourScanCount;
}

@end



@implementation DuplicateFindOperation

- (id)initWithInfo:(NSDictionary*)info {

    self = [super init];
    if (self)
    {
        _taskInfo = [NSMutableDictionary dictionaryWithDictionary: info];
    }
    return self;
}

-(void) main {
    NSArray *urls = [_taskInfo objectForKey: kRootPathKey];
    NSNumber *Options = [_taskInfo objectForKey: kOptionsKey];

    FileCollection *duplicates;
    FileCollection *filecollection = [[FileCollection alloc] init];
    //    // This will eliminate any results from previous searches
    //    [filecollection resetDuplicateLists];
    //
    if (![self isCancelled])
	{
        for (NSURL *url in urls) {
            /* Abort if problem detected */
            if (url==nil) {
                /* Should it be decided to inform */
            }
            else {
                MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:url WithMode:BViewDuplicateMode];
                for (NSURL *theURL in dirEnumerator) {
                    [filecollection addFileByURL:theURL];
                    if ([self isCancelled])
                        break;
                } // for
            }
                if ([self isCancelled])
                    break;
        }
        if (![self isCancelled])
        {
            duplicates = [filecollection findDuplicates:[Options integerValue] operation:self];
            //    TreeRoot *root = [TreeRoot treeWithFileCollection:duplicates callback:^(NSInteger fileno) {
            //        // Put Code here
            //        //[[self StatusText] setIntegerValue:fileno];
            //    }];
            //    [(BrowserController*)myLeftView addTreeRoot:root];
            //
            //    [(BrowserController*)myLeftView refreshTrees];
            //    [_toolbarDeleteButton setEnabled:NO];
            //

            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                  duplicates, kDuplicateList,  // pass back to check if user cancelled/started a new scan
                                  nil];
            // for the purposes of this sample, we're just going to post the information
            // out there and let whoever might be interested receive it (in our case its MyWindowController).
            //
            [_taskInfo addEntriesFromDictionary:info];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationDuplicateFindFinish object:nil userInfo:_taskInfo];
        }
    }
}


@end
