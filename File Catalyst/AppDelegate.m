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
#import "TreeManager.h"
#import "TreeScanOperation.h"
#import "searchTree.h"
#import "FileUtils.h"
#import "FileOperation.h"
#import "DuplicateFindOperation.h"
#import "FileExistsChoice.h"

#import "DuplicateFindSettingsViewController.h"


// Debug CODE !!! To delete
#import "filterBranch.h"
#import "CatalogBranch.h"
#import "myValueTransformers.h"

NSString *notificationStatusUpdate=@"StatusUpdateNotification";


NSString *notificationCatalystRootUpdate=@"RootUpdate";
NSString *catalystRootUpdateNotificationPath=@"RootUpdatePath";


NSString *notificationDoFileOperation = @"DoOperation";
NSString *kDropOperationKey =@"OperationKey";
NSString *kDropDestinationKey =@"DestinationKey";
NSString *kRenameFileKey = @"RenameKey";
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
id appTreeManager;


@interface AppDelegate (Privates)

- (void)     statusUpdate:(NSNotification*)theNotification;
- (void)       rootUpdate:(NSNotification*)theNotification;
- (void) processNextError:(NSNotification*)theNotification;

@end

@implementation AppDelegate {
    ApplicationwMode applicationMode;
    id  selectedView;
	NSTimer	*_operationInfoTimer;                  // update timer for progress indicator
    NSNumber *treeUpdateOperationID;
    DuplicateFindSettingsViewController *duplicateSettingsWindow;
    FileExistsChoice *fileExistsWindow;
    NSMutableArray *pendingOperationErrors;
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
        appFileManager = [[NSFileManager alloc] init];
        appTreeManager = [[TreeManager alloc] init];
        [appFileManager setDelegate:self];
        /* Registering Transformers */
        // !!! TODO: Put formats in the User Definitions
        NSValueTransformer *date_transformer = [[DateToStringTransformer alloc] init];
        [NSValueTransformer setValueTransformer:date_transformer forName:@"date"];
        NSValueTransformer *size_transformer = [[SizeToStringTransformer alloc] init];
        [NSValueTransformer setValueTransformer:size_transformer forName:@"size"];

	}
	return self;
}

#pragma mark auxiliary functions

-(void) goHome:(id) view {
    // Change the selected view to go Home in Browser Mode

    if ([view isKindOfClass:[BrowserController class]]) {
        NSString *homepath;
        if (view == myLeftView) {
            // Get from User Parameters
            homepath = [[[NSUserDefaults standardUserDefaults] objectForKey:@"prefsBrowserLeft"] objectForKey:@"prefHomeDir"];
        }
        else if (view == myRightView) {
            homepath = [[[NSUserDefaults standardUserDefaults] objectForKey:@"prefsBrowserRight"] objectForKey:@"prefHomeDir"];
        }
        if (homepath == nil || [homepath isEqualToString:@""])
            homepath = NSHomeDirectory();

        NSURL *url = [NSURL fileURLWithPath:homepath isDirectory:YES];
        id item = [(TreeManager*)appTreeManager addTreeItemWithURL:url];
        [(BrowserController*)view removeAll];
        [(BrowserController*)view setViewMode:BViewBrowserMode];
        [(BrowserController*)view addTreeRoot: item];
        [(BrowserController*)view selectFirstRoot];
    }
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
    /* Setting up user defaults */
    NSString *userDefaultsValuesPath=[[NSBundle mainBundle] pathForResource:@"UserDefault"
                                                           ofType:@"plist"];
    NSDictionary *userDefaultsValuesDict=[NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];


    /* Now setting notifications */

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    // Insert code here to initialize your application
    myLeftView  = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
    myRightView = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];

    // register for the notification when an image file has been loaded by the NSOperation: "LoadOperation"
	[center addObserver:self selector:@selector(anyThread_handleTreeConstructor:) name:notificationTreeConstructionFinished object:nil];
    [center addObserver:self selector:@selector(handleOperationInformation:) name:notificationDoFileOperation object:nil];
    [center addObserver:self selector:@selector(processNextError:) name:notificationClosedFileExistsWindow object:nil];
    [center addObserver:self selector:@selector(startDuplicateFind:) name:notificationStartDuplicateFind object:nil];
    [center addObserver:self selector:@selector(anyThread_handleDuplicateFinish:) name:notificationDuplicateFindFinish object:nil];

    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:myLeftView];
    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:myRightView];
    [center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:myLeftView];
    [center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:myRightView];


    [myLeftView setFoldersDisplayed:
            [[[userDefaultsValuesDict objectForKey:@"prefsBrowserLeft"]
                                      objectForKey:@"prefDisplayFoldersInTable"] boolValue]];
    [myRightView setFoldersDisplayed:
            [[[userDefaultsValuesDict objectForKey:@"prefsBrowserLeft"]
                                      objectForKey:@"prefDisplayFoldersInTable"] boolValue]];

    [_ContentSplitView addSubview:myLeftView.view];
    [_ContentSplitView addSubview:myRightView.view];

    /* Registering for receiving services */
    NSArray *sendTypes = [NSArray arrayWithObjects:NSURLPboardType,
                          NSFilenamesPboardType, nil];
    NSArray *returnTypes = [NSArray arrayWithObjects:NSURLPboardType,
                            NSFilenamesPboardType, nil];
    [NSApp registerServicesMenuSendTypes:sendTypes
                             returnTypes:returnTypes];


    //[_chkMP3_ID setEnabled:NO];
    //[_chkPhotoEXIF setEnabled:NO];
    //[_pbRemove setEnabled:NO];

}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    static BOOL firstAppActivation = YES;

    if (firstAppActivation == YES) {
        firstAppActivation = NO;
        // Right side
        [self goHome: myRightView]; // Display the User Preferences Left Home

        // Left Side
        [self goHome: myLeftView]; // Display the User Preferences Left Home
        if (0) { // Testing Catalyst Mode
            [(BrowserController*)myLeftView setViewMode:BViewCatalystMode];
            NSDictionary *taskInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      //homeDir,kRootPathKey,
                                      @"/Users/vika/Documents/",kRootPathKey,
                                      myLeftView, kSenderKey,
                                      [NSNumber numberWithInteger:BViewCatalystMode], kModeKey,
                                      nil];
            TreeScanOperation *Op = [[TreeScanOperation new] initWithInfo: taskInfo];
            treeUpdateOperationID = [Op operationID];
            [operationsQueue addOperation:Op];
            [self _startOperationBusyIndication];
        }
        if (0) { // Testing filter and catalog Branches
            NSURL *url = [NSURL fileURLWithPath:@"/Users/vika/Documents" isDirectory:YES];
            //item = [(TreeManager*)appTreeManager addTreeBranchWithURL:url];
            if(0) { // Debug Code
                searchTree *st = [[searchTree alloc] initWithSearch:@"*" name:@"Document Search" parent:nil];
                [st setUrl:url]; // Setting the url since the init doesn't !!! This is a workaround for the time being
                NSPredicate *filter;
                filterBranch *fb;
                filter = [NSPredicate predicateWithFormat:@"SELF.isBranch==FALSE"];
                [st setFilter:filter];
                for (int sz=1; sz < 10; sz+=1) {
                    NSString *pred = [NSString stringWithFormat:@"SELF.filesize < %d", sz*1000000];
                    filter = [NSPredicate predicateWithFormat:pred];
                    NSString *predname = [NSString stringWithFormat:@"Less Than %dMB", sz];
                    fb = [[filterBranch alloc] initWithFilter:filter name:predname parent:nil];
                    [st addChild:fb];
                }
                [st createSearchPredicate];
                [(BrowserController*)myLeftView afterLoadInitialization];
                [(BrowserController*)myLeftView setViewMode:BViewBrowserMode];
                [(BrowserController*)myLeftView addTreeRoot: st];
            }
            else {
                CatalogBranch *st = [[CatalogBranch alloc] initWithSearch:@"*" name:@"Document Search" parent:nil];
                [st setUrl:url]; // Setting the url since the init doesn't !!! This is a workaround for the time being
                [st setFilter:[NSPredicate predicateWithFormat:@"SELF.isBranch==FALSE"]];
                [st setCatalogKey:@"date_modified"];
                [st setValueTransformer:DateToYearTransformer()];
                [st createSearchPredicate];
                [(BrowserController*)myLeftView afterLoadInitialization];
                [(BrowserController*)myLeftView setViewMode:BViewBrowserMode];
                [(BrowserController*)myLeftView addTreeRoot: st];

            }
            [(BrowserController*)myLeftView selectFirstRoot];
        }
    }
    /* Ajust the subView window Sizes */
    [_ContentSplitView adjustSubviews];
    [_ContentSplitView setNeedsDisplay:YES];
}

#pragma mark Services Support
/* Services Pasteboard Operations */

- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType
{
    if ([sendType isEqual:NSFilenamesPboardType] ||
        [sendType isEqual:NSURLPboardType]) {
        NSLog(@"The return type is %@", returnType);
        return self;
    }
    //return [super validRequestorForSendType:sendType returnType:returnType];
    return nil;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types
{
    NSArray *typesDeclared;

    if ([types containsObject:NSFilenamesPboardType] == YES) {
        typesDeclared = [NSArray arrayWithObject:NSFilenamesPboardType];
        [pboard declareTypes:typesDeclared owner:nil];
        NSArray *selectedFiles = [selectedView getSelectedItems];
        NSArray *selectedURLs = [selectedFiles valueForKeyPath:@"@unionOfObjects.url"];
        NSArray *selectedPaths = [selectedURLs valueForKeyPath:@"@unionOfObjects.path"];
        return [pboard writeObjects:selectedPaths];
    }
    else if ([types containsObject:NSURLPboardType] == YES) {
        typesDeclared = [NSArray arrayWithObject:NSURLPboardType];
        [pboard declareTypes:typesDeclared owner:nil];
        NSArray *selectedFiles = [selectedView getSelectedItems];
        NSArray *selectedURLs = [selectedFiles valueForKeyPath:@"@unionOfObjects.url"];
        return [pboard writeObjects:selectedURLs];
    }

    return NO;
}

#pragma mark - Notifications

/* Receives the notification from the BrowserView to reload the Tree */
- (void) rootUpdate:(NSNotification*)theNotification {
    NSMutableDictionary *notifInfo = [NSMutableDictionary dictionaryWithDictionary:[theNotification userInfo]];
    BrowserController *BrowserView = [theNotification object];
    /* In a normal mode the Browser only has one Root */
    [BrowserView removeRootWithIndex:0];

    /* Add the Job to the Queue */
	//[queue cancelAllOperations];

	// start the GetPathsOperation with the root path to start the search
	TreeScanOperation *treeScanOp = [[TreeScanOperation alloc] initWithInfo:notifInfo];
    treeUpdateOperationID = [treeScanOp operationID];
	[operationsQueue addOperation:treeScanOp];	// this will start the "GetPathsOperation"
    [self _startOperationBusyIndication];

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
    if (treeUpdateOperationID == loadScanCountNum)
    {
        TreeRoot *receivedTree = [notifData valueForKey:kTreeRootKey];
        BrowserController *BView =[notifData valueForKey: kSenderKey];
        [BView addTreeRoot:receivedTree];
        [BView stopBusyAnimations];
        [BView selectFolderByItem: receivedTree];
        // set the number of images found indicator string
        [_StatusBar setTitle:@"Updated"];
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


- (IBAction)toolbarInformation:(id)sender {
    // !!! TODO: Implement Call to System Information Window
}

- (IBAction)toolbarRename:(id)sender {
    // !!! TODO: File Rename, if Multi-Selection, open dialog ?
}

- (IBAction)toolbarSearch:(id)sender {
    // !!! TODO: Search Mode : Similar files Same Size, Same Kind, Same Date, ..., or Directory Search
}

- (IBAction)toolbarGrouping:(id)sender {
    // !!! TODO: Grouping pointer, select column to use for grouping
}


- (IBAction)toolbarDelete:(id)sender {
    NSArray *selectedFiles = [selectedView getSelectedItems];
    sendItemsToRecycleBin(selectedFiles);
    NSLog(@"Menu Delete clicked");
}


- (IBAction)toolbarCopy:(id)sender {
    if (selectedView == myLeftView) {
        NSArray *selectedFiles = [selectedView getSelectedItems];
        copyItemsToBranch(selectedFiles, [myRightView treeNodeSelected]);
    }
    else if (selectedView == myRightView) {
        NSArray *selectedFiles = [selectedView getSelectedItems];
        copyItemsToBranch(selectedFiles, [myLeftView treeNodeSelected]);
    }
}

- (IBAction)toolbarMove:(id)sender {
    if (selectedView == myLeftView) {
        NSArray *selectedFiles = [selectedView getSelectedItems];
        moveItemsToBranch(selectedFiles, [myRightView treeNodeSelected]);
    }
    else if (selectedView == myRightView) {
        NSArray *selectedFiles = [selectedView getSelectedItems];
        moveItemsToBranch(selectedFiles, [myLeftView treeNodeSelected]);
    }
}

- (IBAction)toolbarOpen:(id)sender {
    NSArray *selectedFiles = [selectedView getSelectedItems];
    for (TreeItem *item in selectedFiles) {
        [[NSWorkspace sharedWorkspace] openFile:[item path]];
    }
}

- (IBAction)toolbarRefresh:(id)sender {
    if ([myLeftView isKindOfClass:[BrowserController class]]) {
        [(BrowserController*)myLeftView refreshTrees];
    }
    if ([myRightView isKindOfClass:[BrowserController class]]) {
        [(BrowserController*)myRightView refreshTrees];
    }
}

- (IBAction)toolbarHome:(id)sender {
    [self goHome:selectedView];
}

- (IBAction)operationCancel:(id)sender {
    NSArray *operations = [operationsQueue operations];
    [(NSOperation*)[operations firstObject] cancel];
}

- (IBAction)mruBackForwardAction:(id)sender {
    NSInteger backOrForward = [(NSSegmentedControl*)sender selectedSegment];
    // !!! TODO: Disable Back at the beginning Disable Forward
    // Create isABackFlag for the forward highlight and to test the Back
    // isAForward will make sure that the Forward is highlighted
    // otherwise Forward is disabled and Back Enabled
    id focused_browser = selectedView;
    if ([focused_browser isKindOfClass:[BrowserController class]]) {
        if (backOrForward==0) { // Backward
            [focused_browser backSelectedFolder];
        }
        else {
            [focused_browser forwardSelectedFolder];
        }
    }
    else {
        // !!! TODO: When App Modes are implemented
    }
}

#pragma mark Operations Handling
/* Called for the notificationDoFileOperation notification */
-(void) handleOperationInformation: (NSNotification*) note
{
    // Presently this only starts the Busy indications on the statusBar.
    [self _startOperationBusyIndication];
}

-(void) _startOperationBusyIndication {
    _operationInfoTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_operationsInfoFired:) userInfo:nil repeats:YES];
    [self.statusProgressIndicator setHidden:NO];
    [self.statusProgressIndicator startAnimation:self];
    [self.statusProgressLabel setHidden:NO];
    [self.statusProgressLabel setStringValue:@"..."];
    [self.statusCancelButton setHidden:NO];

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
        NSOperation *currOperation = operations[0];
        if ([currOperation isKindOfClass:[AppOperation class]]) {
            NSString *status = [(AppOperation*)currOperation statusText];
            [self.statusProgressLabel setStringValue:status];
        }
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
    [self.statusCancelButton setHidden:YES];
}

- (void) statusUpdate:(NSNotification*)theNotification {
    static NSUInteger dupShow = 0;
    NSString *statusText;
    selectedView = [theNotification object];
    if ([selectedView isKindOfClass:[BrowserController class]]) {

        NSArray *selectedFiles = [selectedView getSelectedItems];

        if (selectedFiles != nil) {
            NSInteger num_files=0;
            NSInteger files_size=0;
            NSInteger folders_size=0;
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
                //[self.toolbarDeleteButton setEnabled:NO];
//                if (selectedView==myLeftView) {
//                    [self.toolbarCopySegmentedButton setEnabled:NO];
//                }
//                else if (selectedView==myRightView) {
//                    [self.toolbarCopySegmentedButton setEnabled:NO];
//                }
                statusText = [NSString stringWithFormat:@"No Files Selected"];
            }
            else {
                for (TreeItem *item in selectedFiles ) {
                    if ([item isKindOfClass:[TreeLeaf class]]) {
                        num_files++;
                        files_size += [(TreeLeaf*)item filesize];
                    }
                    else if ([item isKindOfClass:[TreeBranch class]]) {
                        num_directories++;
                        folders_size += [(TreeBranch*)item filesize];
                    }
                }
                //[self.toolbarDeleteButton setEnabled:YES];
//                if (selectedView==myLeftView) {
//                    [self.self.toolbarCopySegmentedButton setEnabled:YES];
//                    //[self.toolbarCopyLeftButton setEnabled:NO];
//                }
//                else if (selectedView==myRightView) {
//                    //[self.toolbarCopyRightButton setEnabled:NO];
//                    [self.self.toolbarCopySegmentedButton setEnabled:YES];
//                }
                if ([(BrowserController*)selectedView viewMode]==BViewBrowserMode) {
                    NSString *sizeText = [NSByteCountFormatter stringFromByteCount:files_size countStyle:NSByteCountFormatterCountStyleFile];
                    statusText = [NSString stringWithFormat:@"%lu Directories, %lu Files adding up to %@ bytes",
                                  num_directories, num_files, sizeText];
                }
                else {
                    NSString *sizeText = [NSByteCountFormatter stringFromByteCount:files_size+folders_size countStyle:NSByteCountFormatterCountStyleFile];
                    statusText = [NSString stringWithFormat:@"%lu Files and %lu Directories, Total Size %@",
                                  num_files, num_directories, sizeText];
                }

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
-(void) processNextError:(NSNotification*)theNotification {
    NSArray *note = pendingOperationErrors[0]; // Fifo Like structure
    NSURL* sourceURL = note[0];
    NSURL* destinationURL = note[1];
    NSError *error = note[2];
    NSString *operation = [[[error userInfo] objectForKey:@"NSUserStringVariant"] firstObject];


    if (theNotification!=nil) { // It cames from the window closing
        NSString *new_name;
        // Lauch the new Operation based on the user choice
        fileExistsQuestionResult answer = [fileExistsWindow answer];
        switch (answer) {
            case FileExistsRename:
                new_name = [fileExistsWindow new_filename];
                // Creating the renamed URL
                destinationURL = urlWithRename(destinationURL, new_name) ;
                if ([operation isEqualToString:@"Copy"]) {
                    copyURLToURL(sourceURL, destinationURL);
                }
                else if ([operation isEqualToString:@"Move"]) {
                    moveURLToURL(sourceURL, destinationURL);

                }
                // !!! TODO: Its important now to put the notification from file system to work
                // Otherwise this won't be reflected on the Browser
                //[(TreeManager*)appTreeManager addTreeItemWithURL:destinationURL];
                break;
            case FileExistsSkip:
                /* Basically we don't do nothing */
                break;
            case FileExistsReplace:
                /* Erase the file */
                /* ... and copy again  */

                break;

            default:
                break;
        }
        [pendingOperationErrors removeObjectAtIndex:0];
    }
    if ([pendingOperationErrors count]>=1) { // If only one open the
        if (error.code==516) { // File already exists
            if (fileExistsWindow==nil) {
                fileExistsWindow = [[FileExistsChoice alloc] initWithWindowNibName:@"FileExistsChoice"];
                [fileExistsWindow loadWindow]; //This is needed to load the window
            }
            TreeItem *sourceItem=nil, *destItem=nil;
            // Tries to retrieve first from treeManager. Preferred way as parent is taken
            sourceItem = [(TreeManager*)appTreeManager getNodeWithURL:sourceURL];
            if (sourceItem==nil) // If it fails
                sourceItem = [TreeItem treeItemForURL:sourceURL parent:nil];
            // Tries to retrieve first from treeManager
            destItem = [(TreeManager*)appTreeManager getNodeWithURL:destinationURL];
            if (destItem==nil) // If it fails
                destItem = [TreeItem treeItemForURL:destinationURL parent:nil];

            if (sourceItem!=nil && destItem!=nil) {
                BOOL OK = [fileExistsWindow makeTableWithSource:sourceItem andDestination:destItem];
                if (OK)
                    [fileExistsWindow showWindow:self];
            }
            else {
                // TODO: Messagebox with alert
            }
        }
        else {
            NSLog(@"Error %@", error); // Don't comment this, before all tests are completed.
        }

    }

}

-(void) mainThreadErrorHandler:(NSArray*) note {

    if (pendingOperationErrors==nil) {
        pendingOperationErrors = [[NSMutableArray alloc] init];
    }
    [pendingOperationErrors addObject:note];
    if ([pendingOperationErrors count] == 1) { // Call it if there aren't more pending
        [self processNextError:nil];
    }

}


- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    NSArray *note = [NSArray arrayWithObjects:srcURL, dstURL, error, nil];
    [self performSelectorOnMainThread:@selector(mainThreadErrorHandler:) withObject:note waitUntilDone:NO];
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    NSArray *note = [NSArray arrayWithObjects:srcURL, dstURL, error, nil];
    [self performSelectorOnMainThread:@selector(mainThreadErrorHandler:) withObject:note waitUntilDone:NO];
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
