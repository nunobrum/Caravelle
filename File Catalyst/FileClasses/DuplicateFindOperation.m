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
#import "TreeManager.h"

NSString *notificationDuplicateFindFinish = @"DuplicateFindFinish";
NSString *kDuplicateList = @"DuplicateList";
NSString *kRootsList = @"RootsList";

NSString *kOptionsKey = @"Options";

@interface DuplicateFindOperation () {
    NSUInteger dupGroup;
    NSUInteger i;
}

@end

@implementation DuplicateFindOperation

-(NSString*) statusText {
    if (statusCount==1)
        return [NSString stringWithFormat:@"Indexed %lu files ", i];
    else if (statusCount==2)
        return [NSString stringWithFormat:@"%lu scanned, %lu duplicates", i, dupGroup];
    else
        return @"Starting..."; // This should only appear if this is called is before the task starts
}

-(void) main {
    statusCount=1; // Indicates the first Phase
    if (![self isCancelled])
	{
        NSArray *urls = [_taskInfo objectForKey: kRootPathKey];
        NSMutableArray *roots = [NSMutableArray arrayWithCapacity:[urls count]];
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
                    /* Should it be informed, or just skip it */
                }
                else {
                    //TODO:!!!! This needs to be changed so that it is integrated with the actual Tree Scheme.
                    // 1. Will ask the Tree Manager for this URL,
                    TreeBranch *workBranch = [appTreeManager addTreeItemWithURL:url];
                    [roots addObject:workBranch];
                    // 2.a If it doesn't exist create it
                    // 2.b If it exists, add from nodes in branch
                    
                    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:url WithMode:BViewDuplicateMode];
                    for (NSURL *theURL in dirEnumerator) {
                        TreeItem *item = [workBranch addURL:theURL];
                        [item resetDuplicates]; // in case this is a second run
                        // TODO:!!!!! Other Filters here
                        if (!isFolder(theURL)) {
                            [fileArray addObject:item];
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
                    EnumDuplicateOptions options = [Options integerValue];
                    FileCollection *duplicateList = [[FileCollection new] init];

                    if (options & DupCompareSize) {
                        [fileArray sortUsingComparator:^NSComparisonResult(TreeItem* obj1, TreeItem* obj2) {
                            if (obj1.filesize == obj2.filesize)
                                return NSOrderedSame;
                            else if (obj1.filesize > obj2.filesize)
                                return NSOrderedAscending;  // Order from biggest to smaller
                            else
                                return NSOrderedDescending;
                            
                        }];
                    }

                    TreeItem *FileA, *FileB;
                    for (i=0;i<max_files;i++) {
                        if ([self isCancelled])
                            break;
                        FileA = [fileArray objectAtIndex:i];
                        for (j=i+1; j<max_files; j++) {
                            FileB = [fileArray objectAtIndex:j];
                            duplicate = TRUE;
                            if (options & DupCompareName && [FileA.name isEqualToString: FileB.name]==FALSE) {
                                duplicate= FALSE;
                            }
                            else if (options & DupCompareSize) {
                                if (FileA.filesize > FileB.filesize) {
                                    j = max_files; // This will make the inner cycle to end
                                    duplicate = FALSE;
                                }
                                else if (FileA.filesize < FileB.filesize) {
                                    duplicate = FALSE; // This in principle will never happen if the files are sorted by size
                                }
                            }
                            if (duplicate==TRUE && (options & DupCompareDateModified) && [FileA.date_modified isEqualToDate:FileB.date_modified]==FALSE) {
                                duplicate = FALSE;
                            }
                            if (duplicate==TRUE && (options & (DupCompareContentsMD5|DupCompareContentsFull))) {
                                // First tries to make the difference using MD5 checksums
                                if ([FileA compareMD5checksum:FileB]==FALSE) {
                                    duplicate = FALSE;
                                }
                                else {
                                    // If the MD5 Matches, then it must compare the full contents
                                    if (options&DupCompareContentsFull) {
                                        duplicate = [[NSFileManager defaultManager] contentsEqualAtPath:FileA.path andPath:FileB.path];
                                        
                                    }
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
                            [duplicateList addFile:FileA];
                            dupGroup++;
                        }
                        else {
                            // Erase Duplicate information
                            [FileA resetDuplicates];
                        }
                    }
                    if (![self isCancelled])
                    {
                    if ([duplicateList FileCount]==0)
                        duplicateList = nil;
                    // TODO:!! - Consider creating the Tree here. It only justifies if the tree creation takes too long.
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                          duplicateList, kDuplicateList,  // pass back to check if user cancelled/started a new scan
                                          roots, kRootsList,
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
