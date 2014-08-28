//
//  AppDelegate.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#include "Definitions.h"

#import "AppDelegate.h"
#import "FileCollection.h"
#import "TreeLeaf.h"
#import "TreeScanOperation.h"
#import "FileUtils.h"
#import "DuplicateFindOperation.h"

#import "DuplicateFindSettingsViewController.h"

NSString *notificationStatusUpdate=@"StatusUpdateNotification";
NSString *kSelectedFilesKey=@"FilesSelected";

NSString *notificationStartDuplicateFind = @"StartDuplicateFind";
NSString *notificationDuplicateFindFinish = @"DuplicateFindFinish";

NSString *notificationCatalystRootUpdate=@"RootUpdate";
NSString *catalystRootUpdateNotificationPath=@"RootUpdatePath";


NSString *notificationDoFileOperation = @"DoOperation";
NSString *kOperationKey =@"OperationKey";
NSString *kDestinationKey =@"DestinationKey";

NSString *opCopyOperation=@"CopyOperation";
NSString *opMoveOperation =@"MoveOperation";

NSFileManager *appFileManager;

@implementation AppDelegate {
    ApplicationwMode applicationMode;
    NSArray *selectedFiles;
    id  selectedView;

    NSOperationQueue *queue;         // queue of NSOperations (1 for parsing file system, 2+ for loading image files)
	NSTimer	*timer;                  // update timer for progress indicator
    NSNumber *scanCount;
    DuplicateFindSettingsViewController *duplicateSettingsWindow;
    FileCollection *duplicates;

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
    [center addObserver:self selector:@selector(startDuplicateFind:) name:notificationStartDuplicateFind object:nil];
    [center addObserver:self selector:@selector(duplicateFindFinish:) name:notificationDuplicateFindFinish object:nil];

    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:myLeftView];
    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:myRightView];
    [center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:myLeftView];
    [center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:myRightView];

    if ([myLeftView isKindOfClass:[BrowserController class]]) {
        [myLeftView setViewMode:BViewBrowserMode];
        [myLeftView setFoldersDisplayed:YES];
        //[myLeftView setParent:self];
    }
    if ([myRightView isKindOfClass:[BrowserController class]]) {
        [myRightView setViewMode:BViewBrowserMode];
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
        [(BrowserController*)myRightView refreshTrees];
        if (0) {
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
            [myLeftView setViewMode:BViewBrowserMode];
            [(BrowserController*)myLeftView addTreeRoot: [TreeRoot treeWithURL:[NSURL URLWithString:homeDir]]];
        }
        [(BrowserController*)myLeftView refreshTrees];
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
        [BView refreshTrees];
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
    if (duplicateSettingsWindow==nil)
        duplicateSettingsWindow =[[DuplicateFindSettingsViewController alloc] initWithWindowNibName:nil];
    //NSWindow *wnd = [duplicateSettingsWindow window];
    [duplicateSettingsWindow showWindow:self];

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
        if (applicationMode==ApplicationwModeDuplicate && selectedView==myLeftView) {
            FileCollection *selectedDuplicates = [[FileCollection alloc] init];
            for (TreeItem *item in selectedFiles ) {
                [selectedDuplicates concatenateFileCollection: [duplicates duplicatesInPath:[item path]]];
            }
            /* will now populate the Right View with Duplicates*/
            [myRightView removeAll];
            TreeRoot *rootDir = [TreeRoot treeWithFileCollection:selectedDuplicates callback:^(NSInteger fileno){}];
            [myRightView addTreeRoot:rootDir];
            [myRightView refreshTrees];
        }
        if ([selectedFiles count]==0) {
            statusText = [NSString stringWithFormat:@"No Files Selected"];
        }
        else {
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
            NSString *sizeText = [NSByteCountFormatter stringFromByteCount:total_size countStyle:NSByteCountFormatterCountStyleFile];
            statusText = [NSString stringWithFormat:@"%lu Files, %lu Directories, Total Size %@",
                          num_files, num_directories, sizeText];
            [_StatusBar setTitle: statusText];
        }
    }
    else {
        [_StatusBar setTitle: @"Ooops! Received Notification without User Info"];
    }
}

- (void) startDuplicateFind:(NSNotification*)theNotification {
    NSLog(@"Starting Duplicate Find");

    NSDictionary *notifInfo = [theNotification userInfo];
	// start the GetPathsOperation with the root path to start the search
	DuplicateFindOperation *dupFindOp = [[DuplicateFindOperation alloc] initWithInfo:notifInfo];
	[queue addOperation:dupFindOp];	// this will start the "GetPathsOperation"


}

- (void) duplicateFindFinish:(NSNotification*)theNotification {
    NSDictionary *info = [theNotification userInfo];
    duplicates = [info objectForKey:kDuplicateList];
    self->applicationMode = ApplicationwModeDuplicate;
    [myLeftView setViewMode:BViewDuplicateMode];
    [myRightView setViewMode:BViewDuplicateMode];
    [myLeftView removeAll];
    [myRightView removeAll];
    TreeRoot *rootDir = [TreeRoot treeWithFileCollection:duplicates callback:^(NSInteger fileno){}];
    [myLeftView addTreeRoot:rootDir];
    [myRightView addTreeRoot:rootDir];
    [myLeftView refreshTrees];
    [myRightView refreshTrees];
    NSLog(@"Duplicate Find Finish");
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
