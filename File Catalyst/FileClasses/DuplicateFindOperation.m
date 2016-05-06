//
//  DuplicateFindOperation.m
//  File Catalyst
//
//  Created by Nuno Brum on 26/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "Definitions.h"
#import "DuplicateFindOperation.h"
#import "TreeManager.h"
#import "MyDirectoryEnumerator.h"
#import "FileUtils.h"
#import "TreeCollection.h"
#import "filterBranch.h"

NSString *notificationDuplicateFindFinish = @"DuplicateFindFinish";
NSString *kDuplicateList = @"DuplicateList";
NSString *kRootsList = @"RootsList";
NSString *kRootUnified = @"UnifiedRoot";
NSString *kOptionsKey = @"Options";
NSString *kFilenameFilter  = @"FilenameFilter";
NSString *kMinSizeFilter   = @"MinSizeFilter";
NSString *kStartDateFilter = @"StartDateFilter";
NSString *kEndDateFilter   = @"EndDateFilter";

typedef NS_ENUM(NSInteger, EnumDuplicateFindPhase) {
    EnumDuplicateOp_Starting = 0,
    EnumDuplicateOp_Indexing,
    EnumDuplicateOp_Comparing,
    EnumDuplicateOp_CreatingView
};

@interface DuplicateFindOperation () {
    EnumDuplicateFindPhase opPhase;
    NSUInteger dupCounter;
    NSUInteger counter, totalCounter;
    unsigned long long sizeCounter, totalSize, duplicateSize;
}

@end

@implementation DuplicateFindOperation

-(NSString*) statusText {
    if (opPhase == EnumDuplicateOp_Indexing) {
        NSString *sizeFormatted = [NSByteCountFormatter stringFromByteCount:sizeCounter countStyle:NSByteCountFormatterCountStyleFile];
        return [NSString stringWithFormat:@"Indexed %lu files, total size %@ ", counter, sizeFormatted];
    }
    else if (opPhase == EnumDuplicateOp_Comparing) {
        // The math below : it makes a half of the size percentage and a half of the file count percentage
        // just one or the other doesn't look very real on the progress
        float percent = 50.0 * sizeCounter / totalSize + 50.0 * counter/totalCounter;
        NSString *sizeFormatted = [NSByteCountFormatter stringFromByteCount:duplicateSize countStyle:NSByteCountFormatterCountStyleFile];
        return [NSString stringWithFormat:@"Comparing...%3.1f%%, %lu duplicates found, total size %@", percent, dupCounter, sizeFormatted]; // One is subtracted since the counter is initialized as 1.
    }
    else if (opPhase == EnumDuplicateOp_CreatingView) {
        float percent = 100.0 * counter / totalCounter;
        return [NSString stringWithFormat:@"Creating Tree %3.1f%%", percent];
    }
    else
        return @"Starting Duplicate Find"; // This should only appear if this is called is before the task starts
}

-(void) main {
    sizeCounter = 0;
    totalSize = 0;
    duplicateSize = 0;
    opPhase = EnumDuplicateOp_Indexing; // Indicates the first Phase
    
    NSArray *paths = [_taskInfo objectForKey: kRootPathKey];
    TreeCollection *roots = nil;
    filterBranch *filterRoot = nil;
    NSMutableArray *duplicates = [[NSMutableArray new] init];
    
    if (![self isCancelled])
	{
        NSNumber *Options = [_taskInfo objectForKey: kOptionsKey];

        //    // This will eliminate any results from previous searches
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
        roots = [[TreeCollection alloc] initWithURL:nil parent:nil];
        // Preparing single View
        filterRoot = [[filterBranch alloc] initWithFilter:nil name:@"Duplicates" parent:nil];

        //NSLog(@"DuplicateFindOperation: Starting Duplicate Scan");
        counter = 0;
        for (NSString *path in paths) {
            /* Abort if problem detected */
            NSURL *url = [NSURL fileURLWithPath:path isDirectory:YES];
            if (url==nil) {
                /* Should it be informed, or just skip it */
            }
            else {
                MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:url WithMode:BViewDuplicateMode];
                for (NSURL *theURL in dirEnumerator) {
                    long long fsize = exact_size(theURL);
                    if ((!isFolder(theURL)) && (fsize >= minFileSize)) {
                        NSDate *fileDate = dateModified(theURL);
                        if ([startDateFilter laterDate:fileDate] && [endDateFilter earlierDate:fileDate]) {
                            TreeLeaf *fi = [TreeLeaf treeItemForURL:theURL parent:nil];
                            if (fi) {
                                if (namePredicate==nil || [namePredicate evaluateWithObject:fi]) {
                                    [fileArray addObject:fi];
                                    sizeCounter += fsize;
                                    //NSLog(@"accepted %@",theURL);
                                }
                                //else { NSLog(@"rejected %@",theURL); }
                            }
                            else
                                NSLog(@"DuplicateFindOperation.main: Problem adding URL %@", theURL);
                        }
                        if ([self isCancelled])
                            break;
                        counter++;
                    } // for
                }
                if ([self isCancelled])
                    break;
            }
        }
        if (![self isCancelled])
        {
            NSUInteger dupGroup = 1; // Starts at one since 0 is reserved for no Duplicates
            dupCounter = 0;
            totalSize = sizeCounter;
            sizeCounter = 0;
            totalCounter = counter;
            counter=0;
            opPhase = EnumDuplicateOp_Comparing; // Second Phase
            
            NSUInteger j;  // Scan index
            BOOL duplicate;
            //NSLog(@"DuplicateFindOperation: Ordering Files");
            if (options & DupCompareSize) {
                NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"exactSize" ascending:NO];
                [fileArray sortUsingDescriptors:[NSArray arrayWithObject:desc]];
            }
            //NSLog(@"DuplicateFindOperation: Matching %li files", [fileArray count]);
            TreeLeaf *FileA, *FileB;
            while ([fileArray count]>1) {
                counter++;
                if ([self isCancelled])
                    break;
                FileA = [fileArray objectAtIndex:0];
                sizeCounter += [[FileA exactSize] longLongValue];
                NSUInteger max_files = [fileArray count];
                //NSLog(@"%@",FileA.url);
                for (j=1; j<max_files; j++) {
                    FileB = [fileArray objectAtIndex:j];
                    duplicate = TRUE;
                    if (options & DupCompareName && [FileA.name isEqualToString: FileB.name]==FALSE) {
                        duplicate= FALSE;
                    }
                    else if (options & DupCompareSize) {
                        NSComparisonResult comp = [FileA.exactSize compare:FileB.exactSize];
                        if (comp == NSOrderedDescending) { // FileA.exactSize > FileB.exactSize
                            j = max_files; // This will make the inner cycle to end
                            duplicate = FALSE;
                        }
                        else if (comp == NSOrderedAscending) { // (FileA.exactSize < FileB.exactSize)
                            duplicate = FALSE; // This in principle will never happen if the files are sorted by size
                        }
                    }
                    if (duplicate==TRUE && (options & DupCompareDateAccessed) && [FileA.date_accessed isEqualToDate:FileB.date_accessed]==FALSE) {
                        duplicate = FALSE;
                    }
                    if (duplicate==TRUE && (options & DupCompareDateModified) && [FileA.date_modified isEqualToDate:FileB.date_modified]==FALSE) {
                        duplicate = FALSE;
                    }
                    if (duplicate==TRUE && (options & DupCompareDateCreated) && [FileA.date_created isEqualToDate:FileB.date_created]==FALSE) {
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
                        if ([FileA addDuplicate:FileB group:dupGroup]) {
                            // group is only incremented if FileB is the first duplicate of FileA
                            dupGroup++;
                        }
                        // adds the total size that is duplicate and not the size of all the duplicates
                        duplicateSize += [[FileB exactSize] longLongValue];
                        
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
        
        if (![self isCancelled])
        {
            totalCounter = dupCounter;
            opPhase = EnumDuplicateOp_CreatingView;
            //NSLog(@"DuplicateFindOperation: Creating Tree");
            counter = 0;
            if ([duplicates count]!=0) {
                for (NSString *path in paths) {
                    /* Abort if problem detected */
                    NSURL *url = [NSURL fileURLWithPath:path isDirectory:YES];
                    if (url!=nil) {
                        TreeBranchCatalyst *r = [TreeBranchCatalyst treeItemForURL:url parent:roots];
                        [roots addTreeItem:r]; // Adding the root elements
                    }
                }
                // Firstly adding the flat view that will monitor all the files
                [filterRoot addItemArray:duplicates];
                // Then the tree view, that will re-register the parents
                // Adding the duplicates to the new Tree
                for (TreeLeaf *item in duplicates) {
                    [item setTag:tagTreeAuthorized]; // Needed because the parent is not known
                    [roots addTreeItem:item];
                    counter++;
                }
                
            }
        }
    }
    
    NSNumber *OK = [NSNumber numberWithBool:![self isCancelled]];
    NSString *statusText;
    if ([self isCancelled]) {
        statusText = @"Duplicate Find Aborted";
    }
    else {
        if (dupCounter==0)
            statusText = @"No Duplicates Found";
        else
            statusText = [NSString stringWithFormat:@"%ld Duplicates Found", dupCounter];
    }
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          OK, kDFOOkKey,
                          duplicates, kDuplicateList,  // pass back to check if user cancelled/started a new scan
                          roots, kRootsList,
                          filterRoot, kRootUnified,
                          statusText, kDFOStatusKey,
                          nil];
    // for the purposes of this sample, we're just going to post the information
    // out there and let whoever might be interested receive it (in our case its MyWindowController).
    //
    [_taskInfo addEntriesFromDictionary:info];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationDuplicateFindFinish object:nil userInfo:_taskInfo];
    
    

}
@end
