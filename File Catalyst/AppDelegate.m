//
//  AppDelegate.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import "AppDelegate.h"
#import "FileCollection.h"
#import "TreeLeaf.h"
#import "TreeScanOperation.h"
#import "FileUtils.h"

#include "Definitions.h"

NSString *notificationStatusUpdate=@"StatusUpdateNotification";
NSString *kSelectedFilesKey=@"FilesSelected";

NSString *notificationCatalystRootUpdate=@"RootUpdate";
NSString *catalystRootUpdateNotificationPath=@"RootUpdatePath";


NSString *notificationDoFileOperation = @"DoOperation";
NSString *kOperationKey =@"OperationKey";
NSString *kDestinationKey =@"DestinationKey";

NSString *opCopyOperation=@"CopyOperation";
NSString *opMoveOperation =@"MoveOperation";

NSFileManager *appFileManager;

@implementation AppDelegate {
    NSArray *selectedFiles;
    id  selectedView;

    NSOperationQueue *queue;         // queue of NSOperations (1 for parsing file system, 2+ for loading image files)
	NSTimer	*timer;                  // update timer for progress indicator
    NSNumber *scanCount;
}

// -------------------------------------------------------------------------------
//	init
// -------------------------------------------------------------------------------
- (id)init
{
    NSLog(@"App Delegate: Init");
	self = [super init];
	if (self)
    {
        queue = [[NSOperationQueue alloc] init];
        scanCount= [NSNumber numberWithInteger:0];
        appFileManager = [[NSFileManager alloc] init];
        [appFileManager setDelegate:self];
	}
	return self;
}


// -------------------------------------------------------------------------------
//	applicationShouldTerminateAfterLastWindowClosed:sender
//
//	NSApplication delegate method placed here so the sample conveniently quits
//	after we close the window.
// -------------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}


// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    NSLog(@"App Delegate: awakeFromNib");
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    // Insert code here to initialize your application
    myLeftView  = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
    myRightView = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];

    // register for the notification when an image file has been loaded by the NSOperation: "LoadOperation"
	[center addObserver:self selector:@selector(anyThread_handleTreeConstructor:) name:notificationTreeConstructionFinished object:nil];
    [center addObserver:self selector:@selector(handleOperationRequest:) name:notificationDoFileOperation object:nil];

    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:myLeftView];
    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:myRightView];
    [center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:myLeftView];
    [center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:myRightView];

    if ([myLeftView isKindOfClass:[BrowserController class]]) {
        [myLeftView setCatalystMode:YES];
        [myLeftView setFoldersDisplayed:YES];
        //[myLeftView setParent:self];
    }
    if ([myRightView isKindOfClass:[BrowserController class]]) {
        [myRightView setCatalystMode:NO];
        [myRightView setFoldersDisplayed:YES];
        //[myRightView setParent:self];
    }

    [_ContentSplitView addSubview:myLeftView.view];
    [_ContentSplitView addSubview:myRightView.view];


    //[_chkMP3_ID setEnabled:NO];
    //[_chkPhotoEXIF setEnabled:NO];
    //[_pbRemove setEnabled:NO];
    firstAppActivation = YES;

}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    if (firstAppActivation == YES) {
        firstAppActivation = NO;
        NSString *homeDir = NSHomeDirectory();

        [(BrowserController*)myRightView addTreeRoot: [TreeRoot treeWithURL:[NSURL URLWithString:homeDir]]];
        if (1) {
        NSDictionary *taskInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                homeDir,kRootPathKey,
                                myLeftView, kSenderKey,
                                scanCount, kScanCountKey,
                                [NSNumber numberWithBool:YES], kModeKey,
                                nil];
        TreeScanOperation *Op = [[TreeScanOperation new] initWithInfo: taskInfo];
        [queue addOperation:Op];
        [(BrowserController*)myLeftView startBusyAnimations];
        }
        else {
            [(BrowserController*)myLeftView addTreeRoot: [TreeRoot treeWithURL:[NSURL URLWithString:homeDir]]];
            [myLeftView setCatalystMode:NO];
        }
    }
    /* Ajust the subView window Sizes */
    [_ContentSplitView adjustSubviews];
    [_ContentSplitView setNeedsDisplay:YES];
}

/* Receives the notification from the BrowserView to reload the Tree */
- (void) rootUpdate:(NSNotification*)theNotification {
    NSMutableDictionary *notifInfo = [NSMutableDictionary dictionaryWithDictionary:[theNotification userInfo]];
    BrowserController *BrowserView = [theNotification object];
    /* In a normal mode the Browser only has one Root */
    [BrowserView removeRootWithIndex:0];
    /* Increment the Scan Count */
    NSInteger aux = [scanCount integerValue]+1;
    scanCount = [NSNumber numberWithInteger:aux];
    [notifInfo addEntriesFromDictionary:[NSDictionary dictionaryWithObject:scanCount forKey:kScanCountKey]];
    /* Add the Job to the Queue */
	//[queue cancelAllOperations];

	// start the GetPathsOperation with the root path to start the search
	TreeScanOperation *treeScanOp = [[TreeScanOperation alloc] initWithInfo:notifInfo];

	[queue addOperation:treeScanOp];	// this will start the "GetPathsOperation"

}

- (void)mainThread_handleTreeConstructor:(NSNotification *)note
{
    // Pending NSNotifications can possibly back up while waiting to be executed,
	// and if the user stops the queue, we may have left-over pending
	// notifications to process.
	//
	// So make sure we have "active" running NSOperations in the queue
	// if we are to continuously add found image files to the table view.
	// Otherwise, we let any remaining notifications drain out.
	//
	NSDictionary *notifData = [note userInfo];

    NSNumber *loadScanCountNum = [notifData valueForKey:kScanCountKey];

    // make sure the current scan matches the scan of our loaded image
    if (scanCount == loadScanCountNum)
    {
        TreeRoot *receivedTree = [notifData valueForKey:kTreeRootKey];
        BrowserController *BView =[notifData valueForKey: kSenderKey];
        [BView addTreeRoot:receivedTree];
        [BView stopBusyAnimations];
        // set the number of images found indicator string
        [_StatusBar setTitle:@"Received data from Thread"];
    }
}

// -------------------------------------------------------------------------------
//	anyThread_handleLoadedImages:note
//
//	This method is called from any possible thread (any NSOperation) used to
//	update our table view and its data source.
//
//	The notification contains the NSDictionary containing the image file's info
//	to add to the table view.
// -------------------------------------------------------------------------------
- (void)anyThread_handleTreeConstructor:(NSNotification *)note
{
	// update our table view on the main thread
	[self performSelectorOnMainThread:@selector(mainThread_handleTreeConstructor:) withObject:note waitUntilDone:NO];
}

-(void) handleOperationRequest: (NSNotification*) note
{
    NSDictionary *notifData = [note userInfo];
    NSString *operation = [notifData objectForKey:kOperationKey];
    NSArray *files = [notifData objectForKey:kSelectedFilesKey];

    if ([operation isEqualToString:opCopyOperation]) {
        NSURL *toDirectory = [notifData objectForKey:kDestinationKey];
        copyFilesThreaded(files, [toDirectory path]);

    }
    // TODO !!! Update the Status during the operation
    // Hint : Use the Queue Manager count and a Timer to update the operation each second.
}

// -------------------------------------------------------------------------------
//	windowShouldClose:sender
// -------------------------------------------------------------------------------
- (BOOL)windowShouldClose:(id)sender
{
	// are you sure you want to close, (threads running)
	NSInteger numOperationsRunning = [[queue operations] count];

	if (numOperationsRunning > 0)
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"Image files are currently loading."
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Please click the \"Stop\" button before closing."];
		[alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}

	return (numOperationsRunning == 0);
}


- (IBAction)toolbarDelete:(id)sender {
    NSLog(@"Menu Delete clicked");
}

- (IBAction)toolbarCatalystSwitch:(id)sender {
}


- (IBAction)RemoveSelected:(id)sender {
    [_toolbarDeleteButton setEnabled:NO];
}


- (IBAction)FindDuplicates:(id)sender {
    comparison_options_t options;
    FileCollection *duplicates;
    FileCollection *collection = [(BrowserController*)myLeftView concatenateAllCollections];
    // This will eliminate any results from previous searches
    [collection resetDuplicateLists];
    
    //Sets all options to FALSE;
    memset(&options,0,sizeof(comparison_options_t));
    
//    options.names = [_chkFilename state];
//    options.contents = [_chkContents state];
//    options.sizes = [_chkSize state];
//    options.dates = [_chkModifiedDate state];
//    options.mp3_id3 = [_chkMP3_ID state];
//    options.photo_exif = [_chkPhotoEXIF state];
    
    duplicates = [collection findDuplicates:options];
    TreeRoot *root = [TreeRoot treeWithFileCollection:duplicates callback:^(NSInteger fileno) {
        // Put Code here
        //[[self StatusText] setIntegerValue:fileno];
    }];
    [(BrowserController*)myLeftView addTreeRoot:root];

    [(BrowserController*)myLeftView refreshTrees];
    [_toolbarDeleteButton setEnabled:NO];
    
    //[_LeftOutlineView setDataSource:_LeftDataSrc];
    //[_LeftOutlineView reloadItem:nil reloadChildren:YES];
}


- (void) statusUpdate:(NSNotification*)theNotification {
    NSString *statusText;
    NSDictionary *receivedData = [theNotification userInfo];
    selectedFiles = [receivedData objectForKey:kSelectedFilesKey];
    selectedView = [theNotification object];
    if (selectedFiles != nil) {
        NSInteger num_files=0;
        NSInteger total_size=0;
        NSInteger num_directories=0;
        for (TreeItem *item in selectedFiles ) {
            if ([item isKindOfClass:[TreeLeaf class]]) {
                num_files++;
                total_size += [(TreeLeaf*)item filesize];
            }
            else if ([item isKindOfClass:[TreeBranch class]]) {
                num_directories++;
                total_size += [(TreeBranch*)item filesize];
            }
        }
        if ([selectedFiles count]==0) {
            statusText = [NSString stringWithFormat:@"Ready"];
        }
        else {
            NSString *sizeText = [NSByteCountFormatter stringFromByteCount:total_size countStyle:NSByteCountFormatterCountStyleFile];
            statusText = [NSString stringWithFormat:@"%lu Files, %lu Directories, Total Size %@", num_files, num_directories, sizeText];
        }
        [_StatusBar setTitle: statusText];
    }
    else {
        [_StatusBar setTitle: @"Ooops! Received Notification without User Info"];
    }
}

#pragma mark File Manager Delegate - Copy

- (BOOL)fileManager:(NSFileManager *)fileManager shouldCopyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    NSLog(@"shouldCopyItemAtURL");
    return YES;
}
- (BOOL)fileManager:(NSFileManager *)fileManager shouldCopyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    NSLog(@"shouldCopyItemAtPath");
    return YES;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    return NO;
}


@end
