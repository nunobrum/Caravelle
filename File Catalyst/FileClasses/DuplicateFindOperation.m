//
//  DuplicateFindOperation.m
//  File Catalyst
//
//  Created by Nuno Brum on 26/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "Definitions.h"
#import "DuplicateFindOperation.h"
#import "MyDirectoryEnumerator.h"
#import "FileCollection.h"
#import "FileUtils.h"

NSString *notificationDuplicateFindFinish = @"DuplicateFindFinish";
NSString *kDuplicateList = @"DuplicateList";

NSString *kOptionsKey = @"Options";

@interface DuplicateFindOperation () {
    NSUInteger dupGroup;
    NSUInteger i;
}

@end

@implementation DuplicateFindOperation

-(NSString*) statusText {
    if (statusCount==1)
        return [NSString stringWithFormat:@"Indexing %lu", i];
    else if (statusCount==2)
        return [NSString stringWithFormat:@"%lu : %lu", i, dupGroup];
    else
        return @"..."; // This should only appear if this is called is before the task starts
}

-(void) main {
    statusCount=1; // Indicates the first Phase
    if (![self isCancelled])
	{
        NSArray *urls = [_taskInfo objectForKey: kRootPathKey];
        NSNumber *Options = [_taskInfo objectForKey: kOptionsKey];

        //    // This will eliminate any results from previous searches
        //    [filecollection resetDuplicateLists];
        //
        if (![self isCancelled])
        {
            NSMutableArray *fileArray = [[NSMutableArray alloc] init];
            i = 0;
            for (NSURL *url in urls) {
                /* Abort if problem detected */
                if (url==nil) {
                    /* Should it be decided to inform */
                }
                else {
                    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:url WithMode:BViewDuplicateMode];
                    for (NSURL *theURL in dirEnumerator) {
                        if (!isFolder(theURL)) {
                            FileInformation *fi = [FileInformation createWithURL:theURL];
                            [fileArray addObject:fi];

                            if ([self isCancelled])
                                break;
                            i++;
                        } // for
                    }
                    if ([self isCancelled])
                        break;
                }
                if (![self isCancelled])
                {
                    statusCount = 2; // Second Phase
                    NSUInteger j;
                    NSUInteger max_files = [fileArray count];
                    BOOL duplicate;
                    DuplicateOptions options = [Options integerValue];
                    FileCollection *duplicateList = [[FileCollection new] init];

                    if (options & DupCompareSize) {
                        [fileArray sortUsingSelector:@selector(compareSize:)];
                    }

                    FileInformation *FileA, *FileB;
                    for (i=0;i<max_files;i++) {
                        if ([self isCancelled])
                            break;
                        FileA = [fileArray objectAtIndex:i];
                        for (j=i+1; j<max_files; j++) {
                            FileB = [fileArray objectAtIndex:j];
                            duplicate = TRUE;
                            if (options & DupCompareName && [FileA equalName: FileB]==FALSE) {
                                duplicate= FALSE;
                            }
                            else if (options & DupCompareSize) {
                                NSComparisonResult result = [FileA compareSize:FileB];
                                if (result ==NSOrderedAscending) {
                                    j = max_files; // This will make the inner cycle to end
                                    duplicate = FALSE;
                                }
                                else if (result == NSOrderedDescending) {
                                    duplicate = FALSE; // This in principle will never happen if the files are sorted by size
                                }
                            }
                            if (duplicate==TRUE && (options & DupCompareDateModified) && [FileA equalDate:FileB]==FALSE) {
                                duplicate = FALSE;
                            }
                            if (duplicate==TRUE && (options & (DupCompareContentsMD5|DupCompareContentsFull))) {
                                // First tries to make the difference using MD5 checksums
                                if ([FileA compareMD5checksum:FileB]==FALSE) {
                                    duplicate = FALSE;
                                }
                                // If the MD5 Matches, then it must compare the full contents
                                else if ((options&DupCompareContentsMD5) || [FileA compareContents:FileB]==FALSE) {
                                    duplicate = FALSE;
                                }
                            }
                            if (duplicate) {
                                //NSLog(@"=======================File Duplicated =====================\n%@\n%@", [FileA getPath], [FileB getPath]);
                                [FileA addDuplicate:FileB];
                                // The cycle will end once one duplicate is found
                                // This must be like this in order for the
                                // Duplicate ring to work, and it makes the algorithm much faster
                                j = max_files;
                            }
                        }
                        if ([FileA hasDuplicates]==YES) {
                            [duplicateList AddFileInformation:FileA];
                            dupGroup++;
                        }
                    }
                    if (![self isCancelled])
                    {
                    if ([duplicateList FileCount]==0)
                        duplicateList = nil;
                    // TODO:?? - Consider creating the Tree here.
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                          duplicateList, kDuplicateList,  // pass back to check if user cancelled/started a new scan
                                          nil];
                    // for the purposes of this sample, we're just going to post the information
                    // out there and let whoever might be interested receive it (in our case its MyWindowController).
                    //
                    [_taskInfo addEntriesFromDictionary:info];
                    [[NSNotificationCenter defaultCenter] postNotificationName:notificationDuplicateFindFinish object:nil userInfo:_taskInfo];
                    }
                }
            }
        }
    }
}
@end
