//
//  TreeScanOperation.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 15/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "TreeScanOperation.h"
#import "TreeRoot.h"
#import "MyDirectoryEnumerator.h"
#import "Definitions.h"

// key for obtaining the current scan count
NSString *kScanCountKey = @"scanCount";

// key for obtaining the associated TreeRoot
NSString *kTreeRootKey = @"treeRoot";

NSString *kRootPathKey = @"RootPath";

NSString *kOptionsKey = @"Options";

// key for obtaining the associated TreeRoot
NSString *kSenderKey = @"Sender";

NSString *kModeKey = @"CatalystMode";

NSString *notificationTreeConstructionFinished = @"TreeFinished";

@interface TreeScanOperation ()
{
    NSMutableDictionary *_taskInfo;
    NSNumber *ourScanCount;
}

@end


@implementation TreeScanOperation
- (id)initWithInfo:(NSDictionary*)info {

    self = [super init];
    if (self)
    {
        _taskInfo = [NSMutableDictionary dictionaryWithDictionary: info];
        ourScanCount = [info objectForKey:kScanCountKey];
    }
    return self;
}

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
            TreeRoot *rootDir = [[TreeRoot new] init];
            rootDir.children = [[NSMutableArray new] init];
            rootDir.url = [NSURL URLWithString:rootPath];
            NSLog(@"From thread ! Scanning directory %@", rootDir.path);
            MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:rootDir.url WithMode:[mode integerValue]];
            for (NSURL *theURL in dirEnumerator) {
                [rootDir addURL:theURL];
                if ([self isCancelled])
                    break;
            } // for
            if (![self isCancelled])
            {
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                      rootDir, kTreeRootKey,
                                      ourScanCount, kScanCountKey,  // pass back to check if user cancelled/started a new scan
                                      nil];
                // for the purposes of this sample, we're just going to post the information
                // out there and let whoever might be interested receive it (in our case its MyWindowController).
                //
                [_taskInfo addEntriesFromDictionary:info];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationTreeConstructionFinished object:nil userInfo:_taskInfo];
            }
        }
    }
}

@end
