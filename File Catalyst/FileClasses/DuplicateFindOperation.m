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
NSString *kFilenameFilter  = @"FilenameFilter";
NSString *kMinSizeFilter   = @"MinSizeFilter";
NSString *kStartDateFilter = @"StartDateFilter";
NSString *kEndDateFilter   = @"EndDateFilter";

@interface DuplicateFindOperation () {
    NSUInteger dupCounter;
    NSUInteger counter;
}

@end

@implementation DuplicateFindOperation

-(NSString*) statusText {
    if (statusCount==1)
        return [NSString stringWithFormat:@"Indexed %lu files ", counter];
    else if (statusCount==2)
        return [NSString stringWithFormat:@"%lu scanned, %lu duplicates", counter, dupCounter]; // One is subtracted since the counter is initialized as 1.
    else if (statusCount==3)
        return [NSString stringWithFormat:@"Finishing %lu", counter];
    else
        return @"Starting Duplicate Find"; // This should only appear if this is called is before the task starts
}

-(void) main {
    statusCount=1; // Indicates the first Phase
    NSArray *urls = [_taskInfo objectForKey: kRootPathKey];
    NSMutableArray *roots = [NSMutableArray arrayWithCapacity:[urls count]];
    NSMutableArray *duplicates = [[NSMutableArray new] init]; 
    
    if (![self isCancelled])
	{
        NSNumber *Options = [_taskInfo objectForKey: kOptionsKey];

        //    // This will eliminate any results from previous searches
        //    [filecollection resetDuplicateLists];
        //
        long long int minFileSize = [[_taskInfo objectForKey:kMinSizeFilter] longLongValue];
        NSDate *startDateFilter = [_taskInfo objectForKey:kStartDateFilter];
        NSDate *endDateFilter   = [_taskInfo objectForKey:kEndDateFilter];
        NSString *fileFilter    = [_taskInfo objectForKey:kFilenameFilter];
        
        NSPredicate *namePredicate;
        if ([fileFilter length]==0)
            namePredicate = nil;
        else {
            // Testing the presence of wildcards
            NSCharacterSet *wildcards = [NSCharacterSet characterSetWithCharactersInString:@"?*"];
            NSRange wildcardsPresent = [fileFilter rangeOfCharacterFromSet:wildcards];
            if (wildcardsPresent.location == NSNotFound)  // Wildcard not present
                namePredicate = [NSPredicate predicateWithFormat:@"name contains[cd] %@", fileFilter];
            else
                namePredicate = [NSPredicate predicateWithFormat:@"name like[cd] %@", fileFilter];
        }
        EnumDuplicateOptions options = [Options integerValue];
        NSMutableArray *fileArray = [[NSMutableArray new] init];
        counter = 0;
        for (NSURL *url in urls) {
            /* Abort if problem detected */
            if (url==nil) {
                /* Should it be informed, or just skip it */
            }
            else {
                NSLog(@"DuplicateFindOperation: Starting Duplicate Scan");
                MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:url WithMode:BViewDuplicateMode];
                for (NSURL *theURL in dirEnumerator) {
                    if ((!isFolder(theURL)) &&
                        (filesize(theURL) >= minFileSize)) {
                        NSDate *fileDate = dateModified(theURL);
                        if ([startDateFilter laterDate:fileDate] && [endDateFilter earlierDate:fileDate]) {
                            TreeLeaf *fi = [TreeLeaf treeItemForURL:theURL parent:nil];
                            if (namePredicate==nil || [namePredicate evaluateWithObject:fi]) {
                                [fileArray addObject:fi];
                                 //NSLog(@"accepted %@",theURL);
                            }
                            //else { NSLog(@"rejected %@",theURL); }
                        }
                        if ([self isCancelled])
                            break;
                        counter++;
                    } // for
                }
                if ([self isCancelled])
                    break;
            }
            if (![self isCancelled])
            {
                NSUInteger dupGroup = 1; // Starts at one since 0 is reserved for no Duplicates
                dupCounter = 0;
                statusCount = 2; // Second Phase
                counter=0;
                NSUInteger j;  // Scan index
                BOOL duplicate;
                NSLog(@"DuplicateFindOperation: Ordering Files");
                if (options & DupCompareSize) {
                    NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"fileSize" ascending:NO];
                    [fileArray sortUsingDescriptors:[NSArray arrayWithObject:desc]];
                }
                NSLog(@"DuplicateFindOperation: File Matching");
                TreeLeaf *FileA, *FileB;
                while ([fileArray count]>1) {
                    counter++;
                    if ([self isCancelled])
                        break;
                    FileA = [fileArray objectAtIndex:0];
                    NSUInteger max_files = [fileArray count];
                    //NSLog(@"%@",FileA.url);
                    for (j=1; j<max_files; j++) {
                        FileB = [fileArray objectAtIndex:j];
                        duplicate = TRUE;
                        if (options & DupCompareName && [FileA.name isEqualToString: FileB.name]==FALSE) {
                            duplicate= FALSE;
                        }
                        else if (options & DupCompareSize) {
                            NSComparisonResult comp = [FileA.fileSize compare:FileB.fileSize];
                            if (comp == NSOrderedDescending) { // FileA.fileSize > FileB.fileSize
                                j = max_files; // This will make the inner cycle to end
                                duplicate = FALSE;
                            }
                            else if (comp == NSOrderedAscending) { // (FileA.fileSize < FileB.fileSize)
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
                            if ([FileA addDuplicate:FileB group:dupGroup])
                                dupGroup++;
                            // The cycle will end once one duplicate is found
                            // This simplifies the algorithm, but makes the group IDs more complex
                            j = max_files;
                        }
                    }
                    if ([FileA hasDuplicates]==YES) {
                        [duplicates addObject:FileA];
                        dupCounter++;
                    }
                    else {
                        // Delete the Duplicate Information Key
                        [FileA resetDuplicates];
                        [FileA purgeURLCacheResources];
                    }
                    [fileArray removeObjectAtIndex:0];
                }
            }
        }
        if (![self isCancelled])
        {
            statusCount = 3;
            NSLog(@"DuplicateFindOperation: Creating Tree");
            for (NSURL *url in urls) {
                // Will distribute the duplicates on the tree received
                // 1. Will ask the Tree Manager for this URL,
                TreeBranch *workBranch = [appTreeManager addTreeItemWithURL:url];
                [workBranch prepareForDuplicates];
                [roots addObject:workBranch];
            }
            counter = 0;
            if ([duplicates count]==0) {
                duplicates = nil;
            }
            else {
                // Adding the duplicates to the new Tree
                for (TreeLeaf *item in duplicates) {
                    for (TreeBranch *root in roots) {
                        if ([root canContainURL:item.url]) {
                            [root addTreeItem:item];
                            break;
                        }
                    }
                    counter++;
                }
            }
        }
    }
    NSNumber *OK = [NSNumber numberWithBool:![self isCancelled]];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          OK, kDFOOkKey,
                          roots, kRootsList,
                          duplicates, kDuplicateList,  // pass back to check if user cancelled/started a new scan
                          nil];
    // for the purposes of this sample, we're just going to post the information
    // out there and let whoever might be interested receive it (in our case its MyWindowController).
    //
    [_taskInfo addEntriesFromDictionary:info];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationDuplicateFindFinish object:nil userInfo:_taskInfo];
    
    

}
@end
