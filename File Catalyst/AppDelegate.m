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
#import "FileOperation.h"
#import "DuplicateFindOperation.h"

#import "DuplicateFindSettingsViewController.h"

NSString *notificationStatusUpdate=@"StatusUpdateNotification";


NSString *notificationCatalystRootUpdate=@"RootUpdate";
NSString *catalystRootUpdateNotificationPath=@"RootUpdatePath";


NSString *notificationDoFileOperation = @"DoOperation";
NSString *kDropOperationKey =@"OperationKey";
NSString *kDropDestinationKey =@"DestinationKey";
NSString *kDroppedFilesKey=@"FilesSelected";

#ifdef USE_UTI
const CFStringRef kTreeItemDropUTI=CFSTR("com.cascode.treeitemdragndrop");
#endif

NSString *opCopyOperation=@"CopyOperation";
NSString *opMoveOperation =@"MoveOperation";
NSString *opEraseOperation =@"EraseOperation";
NSString *opSendRecycleBinOperation = @"SendRecycleBin";

NSFileManager *appFileManager;
NSOperationQueue *operationsQueue;         // queue of NSOperations (1 for parsing file system, 2+ for loading image files)

@implementation AppDelegate {
    ApplicationwMode applicationMode;
    id  selectedView;
	NSTimer	*_operationInfoTimer;                  // update timer for progress indicator
    NSNumber *operationCounter;
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
        operationsQueue = [[NSOperationQueue alloc] init];
        operationCounter= [NSNumber numberWithInteger:0];
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
    [center addObserver:self selector:@selector(handleOperationInformation:) name:notificationDoFileOperation object:nil];
    [center addObserver:self selector:@selector(startDuplicateFind:) name:notificationStartDuplicateFind object:nil];
    [center addObserver:self selector:@selector(anyThread_handleDuplicateFinish:) name:notificationDuplicateFindFinish object:nil];

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
        [(BrowserController*)myRightView setViewMode:BViewBrowserMode];
        [(BrowserController*)myRightView addTreeRoot: [TreeRoot treeWithURL:[NSURL URLWithString:homeDir]]];
        [(BrowserController*)myRightView selectFirstRoot];
        if (1) {
            [(BrowserController*)myLeftView setViewMode:BViewCatalystMode];
            NSDictionary *taskInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      homeDir,kRootPathKey,
                                      myLeftView, kSenderKey,
                                      operationCounter, kOperationCountKey,
                                      [NSNumber numberWithInteger:BViewCatalystMode], kModeKey,
                                      nil];
            TreeScanOperation *Op = [[TreeScanOperation new] initWithInfo: taskInfo];
            [operationsQueue addOperation:Op];
            [self _startOperationBusyIndication];
        }
        else {
            [myLeftView setViewMode:BViewBrowserMode];
            [(BrowserController*)myLeftView addTreeRoot: [TreeRoot treeWithURL:[NSURL URLWithString:homeDir]]];
        }
        [(BrowserController*)myLeftView selectFirstRoot];
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
    NSInteger aux = [operationCounter integerValue]+1;
    operationCounter = [NSNumber numberWithInteger:aux];
    [notifInfo addEntriesFromDictionary:[NSDictionary dictionaryWithObject:operationCounter forKey:kOperationCountKey]];
    /* Add the Job to the Queue */
	//[queue cancelAllOperations];

	// start the GetPathsOperation with the root path to start the search
	TreeScanOperation *treeScanOp = [[TreeScanOperation alloc] initWithInfo:notifInfo];

	[operationsQueue addOperation:treeScanOp];	// this will start the "GetPathsOperation"

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

    NSNumber *loadScanCountNum = [notifData valueForKey:kOperationCountKey];

    // make sure the current scan matches the scan of our loaded image
    if (operationCounter == loadScanCountNum)
    {
        TreeRoot *receivedTree = [notifData valueForKey:kTreeRootKey];
        BrowserController *BView =[notifData valueForKey: kSenderKey];
        [BView addTreeRoot:receivedTree];
        [BView stopBusyAnimations];
        [BView selectFolderByItem: receivedTree];
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


// -------------------------------------------------------------------------------
//	windowShouldClose:sender
// -------------------------------------------------------------------------------
- (BOOL)windowShouldClose:(id)sender
{
	// are you sure you want to close, (threads running)
	NSInteger numOperationsRunning = [[operationsQueue operations] count];

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

#pragma mark Action Outlets

- (IBAction)toolbarDelete:(id)sender {
    NSArray *selectedFiles = [selectedView getSelectedItems];
    sendItemsToRecycleBin(selectedFiles);
    NSLog(@"Menu Delete clicked");
}

- (IBAction)toolbarCatalystSwitch:(id)sender {
}

- (IBAction)toolbarCopyRightAction:(id)sender {
    if (selectedView == myLeftView) {
        NSArray *selectedFiles = [selectedView getSelectedItems];
        copyItemsToBranch(selectedFiles, [myRightView treeNodeSelected]);
    }
    NSLog(@"Menu Copy Right clicked");
}

- (IBAction)toolbarCopyLeftAction:(id)sender {
    if (selectedView == myRightView) {
        NSArray *selectedFiles = [selectedView getSelectedItems];
        copyItemsToBranch(selectedFiles, [myLeftView treeNodeSelected]);
    }
    NSLog(@"Menu Copy Left clicked");
}


- (IBAction)RemoveSelected:(id)sender {
    [_toolbarDeleteButton setEnabled:NO];
}


#pragma mark Operations Handling
-(void) handleOperationInformation: (NSNotification*) note
{
    //    NSDictionary *notifData = [note userInfo];
    //    NSString *operation = [notifData objectForKey:kDropOperationKey];
    //    NSArray *files = [notifData objectForKey:kSelectedFilesKey];
    //
    //    if ([operation isEqualToString:opCopyOperation]) {
    //        NSURL *toDirectory = [notifData objectForKey:kDropDestinationKey];
    //
    //    }
    [self _startOperationBusyIndication];
}

-(void) _startOperationBusyIndication {
    _operationInfoTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_operationsInfoFired:) userInfo:nil repeats:YES];
    [self.statusProgressIndicator setHidden:NO];
    [self.statusProgressIndicator startAnimation:self];
    [self.statusProgressLabel setHidden:NO];
    [self.statusProgressLabel setStringValue:@"..."];
}

- (void)_operationsInfoFired:(NSTimer *)timer {
    if ([operationsQueue operationCount]==0) {
    //[operationInfoTimer release];
        [timer invalidate];
        [self _stopOperationBusyIndication];
        NSLog(@"operation Status Updating after a stop");
    }
    else {
        // Get from Operation the status Text
        NSArray *operations = [operationsQueue operations];
        AppOperation *currOperation = operations[0];
        NSString *status = [currOperation statusText];
        [self.statusProgressLabel setStringValue:status];
    }

}

- (void)_stopOperationBusyIndication {
    // We want to stop any previous animations
    if (_operationInfoTimer != nil) {
        [_operationInfoTimer invalidate];
        //[operationInfoTimer release];
        _operationInfoTimer = nil;
    }
    [self.statusProgressIndicator stopAnimation:self];
    [self.statusProgressIndicator setHidden:YES];
    [self.statusProgressLabel setHidden:YES];
}

- (void) statusUpdate:(NSNotification*)theNotification {
    static NSUInteger dupShow = 0;
    NSString *statusText;
    selectedView = [theNotification object];
    if ([selectedView isKindOfClass:[BrowserController class]]) {

        NSArray *selectedFiles = [selectedView getSelectedItems];

        if (selectedFiles != nil) {
            NSInteger num_files=0;
            NSInteger total_size=0;
            NSInteger num_directories=0;
            if (applicationMode==ApplicationwModeDuplicate && selectedView==myLeftView) {
                dupShow++;
                FileCollection *selectedDuplicates = [[FileCollection alloc] init];
                for (TreeItem *item in selectedFiles ) {
                    FileCollection *itemDups = [duplicates duplicatesInPath:[item path] dCounter:dupShow];
                    [selectedDuplicates concatenateFileCollection: itemDups];
                }
                /* will now populate the Right View with Duplicates*/
                [myRightView removeAll];
                TreeRoot *rootDir = [TreeRoot treeWithFileCollection:selectedDuplicates];
                [myRightView addTreeRoot:rootDir];
                [myRightView selectFirstRoot];
            }
            if ([selectedFiles count]==0) {
                [self.toolbarDeleteButton setEnabled:NO];
                if (selectedView==myLeftView) {
                    [self.toolbarCopyRightButton setEnabled:NO];
                }
                else if (selectedView==myRightView) {
                    [self.toolbarCopyLeftButton setEnabled:NO];
                }
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
                [self.toolbarDeleteButton setEnabled:YES];
                if (selectedView==myLeftView) {
                    [self.toolbarCopyRightButton setEnabled:YES];
                    [self.toolbarCopyLeftButton setEnabled:NO];
                }
                else if (selectedView==myRightView) {
                    [self.toolbarCopyRightButton setEnabled:NO];
                    [self.toolbarCopyLeftButton setEnabled:YES];
                }

                NSString *sizeText = [NSByteCountFormatter stringFromByteCount:total_size countStyle:NSByteCountFormatterCountStyleFile];
                statusText = [NSString stringWithFormat:@"%lu Files, %lu Directories, Total Size %@",
                              num_files, num_directories, sizeText];

            }
            [_StatusBar setTitle: statusText];
        }
        else {
            [_StatusBar setTitle: @"Ooops! Received Notification without User Info"];
        }
    }
}


#pragma mark Find Duplicates

- (IBAction)FindDuplicates:(id)sender {
    if (duplicateSettingsWindow==nil)
        duplicateSettingsWindow =[[DuplicateFindSettingsViewController alloc] initWithWindowNibName:nil];
    //NSWindow *wnd = [duplicateSettingsWindow window];
    [duplicateSettingsWindow showWindow:self];

}

/* invoked by Find Duplicates Dialog on OK Button */
- (void) startDuplicateFind:(NSNotification*)theNotification {
    NSLog(@"Starting Duplicate Find");
    [myLeftView setViewMode:BViewDuplicateMode];
    [myRightView setViewMode:BViewDuplicateMode];
    [self _startOperationBusyIndication];
    NSDictionary *notifInfo = [theNotification userInfo];
	// start the GetPathsOperation with the root path to start the search
	DuplicateFindOperation *dupFindOp = [[DuplicateFindOperation alloc] initWithInfo:notifInfo];
	[operationsQueue addOperation:dupFindOp];	// this will start the "GetPathsOperation"
    [self _startOperationBusyIndication];


}

- (void) mainThread_duplicateFindFinish:(NSNotification*)theNotification {
    NSDictionary *info = [theNotification userInfo];
    duplicates = [info objectForKey:kDuplicateList];
    self->applicationMode = ApplicationwModeDuplicate;
    TreeRoot *rootDir = [TreeRoot treeWithFileCollection:duplicates];
    [myLeftView addTreeRoot:rootDir];
    [myLeftView stopBusyAnimations];
    [myLeftView selectFolderByItem: rootDir];

    [myRightView addTreeRoot:rootDir];
    [myRightView stopBusyAnimations];
    [myRightView selectFolderByItem:rootDir];

    NSLog(@"Duplicate Find Finish");
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
- (void)anyThread_handleDuplicateFinish:(NSNotification *)note
{
	// update our table view on the main thread
	[self performSelectorOnMainThread:@selector(mainThread_duplicateFindFinish:) withObject:note waitUntilDone:NO];
}

#pragma mark File Manager Delegate


- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    NSLog(@"FileManagerDelegate -----------");
    NSLog(@"Not proceeding after copy error");
    NSLog(@"-------------------------------");
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    NSLog(@"FileManagerDelegate -----------");
    NSLog(@"Not proceeding after copy error");
    NSLog(@"-------------------------------");    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    NSLog(@"FileManagerDelegate -----------");
    NSLog(@"Not proceeding after move error");
    NSLog(@"-------------------------------");    return NO;
}
- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    NSLog(@"FileManagerDelegate -----------");
    NSLog(@"Not proceeding after move error");
    NSLog(@"-------------------------------");
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error removingItemAtPath:(NSString *)path {
    NSLog(@"FileManagerDelegate -----------");
    NSLog(@"Not proceeding after remove error");
    NSLog(@"-------------------------------");
    return NO;
}
- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error removingItemAtURL:(NSURL *)URL {
    NSLog(@"FileManagerDelegate -----------");
    NSLog(@"Not proceeding after remove error");
    NSLog(@"-------------------------------");
    return NO;
}


@end
