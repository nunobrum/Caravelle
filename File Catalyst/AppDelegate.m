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
#import "UserPreferencesDialog.h"
#import "RenameFileDialog.h"


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



@interface AppDelegate (Privates)

- (void)  refreshAllViews:(NSNotification*)theNotification;
- (void)     statusUpdate:(NSNotification*)theNotification;
- (void)       rootUpdate:(NSNotification*)theNotification;
- (void) processNextError:(NSNotification*)theNotification;
- (id)   selectedView;
@end

@implementation AppDelegate {
    ApplicationwMode applicationMode;
    NSTimer	*_operationInfoTimer;                  // update timer for progress indicator
    NSNumber *treeUpdateOperationID;
    DuplicateFindSettingsViewController *duplicateSettingsWindow;
    UserPreferencesDialog *userPreferenceWindow;
    RenameFileDialog *renameFilePanel;
    FileExistsChoice *fileExistsWindow;
    NSMutableArray *pendingOperationErrors;
    FileCollection *duplicates;
    BOOL isCutPending;
    NSInteger generalPasteBoardChangeCount;
}

// -------------------------------------------------------------------------------
//	init
// -------------------------------------------------------------------------------
- (id)init
{
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

        isCutPending = NO; // used for the Cut to Clipboard operations.
        //FSMonitorThread = [[FileSystemMonitoring alloc] init];

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
    }
}

-(id) selectedView {
    static id view = nil;

    if ([myLeftView hasFocus]) {
        view = myLeftView;
    }
    else if ([myRightView hasFocus]) {
        view = myRightView;
    }
    return view;
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
//- (void)awakeFromNib
//{
//    NSLog(@"App Delegate: awakeFromNib");
//
//}


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

    // TODO: ? Optimization Replace this notification with a simpler method
    // [NSApp sendAction:@selector(handleOperationInformation:)to:nil from:self];

    // register for the notification when an image file has been loaded by the NSOperation: "LoadOperation"
	[center addObserver:self selector:@selector(anyThread_handleTreeConstructor:) name:notificationTreeConstructionFinished object:nil];
    [center addObserver:self selector:@selector(handleOperationInformation:) name:notificationDoFileOperation object:nil];
    [center addObserver:self selector:@selector(processNextError:) name:notificationClosedFileExistsWindow object:nil];
    [center addObserver:self selector:@selector(startDuplicateFind:) name:notificationStartDuplicateFind object:nil];
    [center addObserver:self selector:@selector(anyThread_handleDuplicateFinish:) name:notificationDuplicateFindFinish object:nil];

    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:nil];

    [center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:nil];

    [center addObserver:self selector:@selector(refreshAllViews:) name:notificationRefreshViews object:nil];

    [myLeftView setFoldersDisplayed:
            [[[userDefaultsValuesDict objectForKey:@"prefsBrowserLeft"]
                                      objectForKey:@"prefDisplayFoldersInTable"] boolValue]];
    [myRightView setFoldersDisplayed:
            [[[userDefaultsValuesDict objectForKey:@"prefsBrowserLeft"]
                                      objectForKey:@"prefDisplayFoldersInTable"] boolValue]];
    [myLeftView setTwinName:@"Right"];
    [myRightView setTwinName:@"Left"];

    [_ContentSplitView addSubview:myLeftView.view];
    [_ContentSplitView addSubview:myRightView.view];

    /* Registering for receiving services */
    NSArray *sendTypes = [NSArray arrayWithObjects:NSURLPboardType,
                          NSFilenamesPboardType, nil];
    NSArray *returnTypes = [NSArray arrayWithObjects:NSURLPboardType,
                            NSFilenamesPboardType, nil];
    [NSApp registerServicesMenuSendTypes:sendTypes
                             returnTypes:returnTypes];


    // Left Side
    [self goHome: myLeftView]; // Display the User Preferences Left Home
    // Right side
    [self goHome: myRightView]; // Display the User Preferences Left Home

    [(BrowserController*)myLeftView selectFirstRoot];
    [(BrowserController*)myRightView selectFirstRoot];
    [(BrowserController*)myLeftView refreshTrees];
    [(BrowserController*)myRightView refreshTrees];

}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    static BOOL firstAppActivation = YES;

    if (firstAppActivation == YES) {
        firstAppActivation = NO;

        if (0) { // Testing Catalyst Mode
            [(BrowserController*)myLeftView initBrowserView:BViewCatalystMode twin:@"Right"];
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
                [(BrowserController*)myLeftView initBrowserView:BViewBrowserMode twin:@"Left"];
                [(BrowserController*)myLeftView addTreeRoot: st];
            }
            else {
                CatalogBranch *st = [[CatalogBranch alloc] initWithSearch:@"*" name:@"Document Search" parent:nil];
                [st setUrl:url]; // Setting the url since the init doesn't !!! This is a workaround for the time being
                [st setFilter:[NSPredicate predicateWithFormat:@"SELF.isBranch==FALSE"]];
                [st setCatalogKey:@"date_modified"];
                [st setValueTransformer:DateToYearTransformer()];
                [st createSearchPredicate];
                [(BrowserController*)myLeftView initBrowserView:BViewBrowserMode twin:@"Right"];
                [(BrowserController*)myLeftView addTreeRoot: st];

            }
            [(BrowserController*)myLeftView selectFirstRoot];
        }
    }
    /* Ajust the subView window Sizes */
    [_ContentSplitView adjustSubviews];
    [_ContentSplitView setNeedsDisplay:YES];
}

-(void) applicationWillTerminate:(NSNotification *)aNotification {
    // !!! TODO: applicationWillTerminate :Save Application State
    NSLog(@"Application Will Terminate");
}
//When the app is deactivated
-(void) applicationWillResignActive:(NSNotification *)aNotification {
    // TODO:!! Save Application State
    // TODO:!!! Close all active windows
    NSLog(@"Application Will Resign Active");
}
//When the user hides your app
-(void) applicationWillHide:(NSNotification *)aNotification {
    // !!! TODO: applicationWillHide :Save Application State
    NSLog(@"Application Will Hide");
}

#pragma mark Services Support
/* Services Pasteboard Operations */

- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType
{
    if ([sendType isEqual:NSFilenamesPboardType] ||
        [sendType isEqual:NSURLPboardType]) {
        //NSLog(@"Service return type is %@", returnType);
        return self;
    }
    //return [super validRequestorForSendType:sendType returnType:returnType];
    return nil;
}


/* This function  is used for the Services Menu */
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types
{
    NSArray *typesDeclared;

    if ([types containsObject:NSFilenamesPboardType] == YES) {
        typesDeclared = [NSArray arrayWithObject:NSFilenamesPboardType];
        [pboard declareTypes:typesDeclared owner:nil];
        NSArray *selectedFiles = [[self selectedView] getSelectedItems];
        NSArray *selectedURLs = [selectedFiles valueForKeyPath:@"@unionOfObjects.url"];
        NSArray *selectedPaths = [selectedURLs valueForKeyPath:@"@unionOfObjects.path"];
        return [pboard writeObjects:selectedPaths];
    }
    else if ([types containsObject:NSURLPboardType] == YES) {
        typesDeclared = [NSArray arrayWithObject:NSURLPboardType];
        [pboard declareTypes:typesDeclared owner:nil];
        NSArray *selectedFiles = [[self selectedView] getSelectedItems];
        NSArray *selectedURLs = [selectedFiles valueForKeyPath:@"@unionOfObjects.url"];
        return [pboard writeObjects:selectedURLs];
    }

    return NO;
}

#pragma mark - Notifications

/* Received when a complete refresh of views is needed */

-(void) refreshAllViews:(NSNotification*) theNotification {
    if ([myLeftView isKindOfClass:[BrowserController class]]) {
        [(BrowserController*)myLeftView refreshTrees];
    }
    if ([myRightView isKindOfClass:[BrowserController class]]) {
        [(BrowserController*)myRightView refreshTrees];
    }
}

/* Receives the notification from the BrowserView to reload the Tree */

//TODO:!!! Revise this code
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


#pragma mark Application Delegate

// -------------------------------------------------------------------------------
//	windowShouldClose:sender
// -------------------------------------------------------------------------------
- (BOOL)windowShouldClose:(id)sender
{
    // TODO:!!! Why isn't this being called ?
    NSLog(@"windowShoudClose");
	// are you sure you want to close, (threads running)
	NSInteger numOperationsRunning = [[operationsQueue operations] count];

	if (numOperationsRunning > 0)
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"Image files are currently loading."
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Please click the \"Stop\" button before closing."];
		[alert beginSheetModalForWindow:[self myWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
    // TODO:!!! Put here the remaining conditions to close
	return (numOperationsRunning == 0);
}

#pragma mark -

#pragma mark execution of Actions

- (void) executeInformation:(NSArray*) selectedFiles {
    NSUInteger numberOfFiles = [selectedFiles count];

    // Solution for one single file
    if (numberOfFiles == 1) {
        NSURL *item = [[selectedFiles firstObject] url];

        if ([item filePathURL]) {
            NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
            [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            [pboard setString:[[item filePathURL] path]  forType:NSStringPboardType];
            NSPerformService(@"Finder/Show Info", pboard);
        }
    }
    // Solution for multiple files
    else {

        NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
        [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];

        NSMutableArray *fileList = [NSMutableArray new];

        //Add as many as file's path in the fileList array
        for(TreeItem *item in selectedFiles) {
            [fileList addObject:[item path]];
        }

        [pboard setPropertyList:fileList forType:NSFilenamesPboardType];
        NSPerformService(@"Finder/Show Info", pboard);
    }

}

- (void) executeRename:(NSArray*) selectedFiles {
    NSUInteger numberOfFiles = [selectedFiles count];
    if (numberOfFiles == 1) {
        // If only one file, with edit with RenameFileDialog
        if (renameFilePanel==nil)
            renameFilePanel =[[RenameFileDialog alloc] initWithWindowNibName:@"RenameFileDialog"];
        TreeItem *selectedFile = [selectedFiles firstObject];
        NSString *oldFilename = [[selectedFile path] lastPathComponent];
        [renameFilePanel showWindow:self];
        // NOTE: If the showWindow is invoked after the statement below it doesn't work
        [renameFilePanel setRenamingFile:oldFilename];
        [NSApp runModalForWindow: [renameFilePanel window]];
        // Got info from window going to make the rename
        NSString *fileName = [renameFilePanel getRenameFile];
        if (NO==[oldFilename isEqualToString:fileName]) {
            NSURL *url = [selectedFile url];
            BOOL isDirectory = isFolder(url);
            NSURL *newURL = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:fileName isDirectory:isDirectory];
            BOOL OK = moveFileTo(url, newURL);
            if (OK==YES) {
                /* This code will work because it is a rename, if its is a move, the TreeItem would have
                 to be created from scratch */
                [selectedFile setUrl:newURL];
                [(BrowserController*)[self selectedView] reloadItem:selectedFile];
            }
        }
    }
    else if (numberOfFiles > 1) {
        // TODO:!! Implement the multi-rename
        // If more than one file, will invoke the multi-rename dialog

    }
}

-(void) executeCopyTo:(NSArray*) selectedFiles {
    if ([self selectedView] == myLeftView) {
        copyItemsToBranch(selectedFiles, [myRightView treeNodeSelected]);
    }
    else if ([self selectedView] == myRightView) {
        copyItemsToBranch(selectedFiles, [myLeftView treeNodeSelected]);
    }
}

-(void) executeMoveTo:(NSArray*) selectedFiles {
    if ([self selectedView] == myLeftView) {
        moveItemsToBranch(selectedFiles, [myRightView treeNodeSelected]);
    }
    else if ([self selectedView] == myRightView) {
        moveItemsToBranch(selectedFiles, [myLeftView treeNodeSelected]);
    }
}

-(void) executeOpen:(NSArray*) selectedFiles {
    for (TreeItem *item in selectedFiles) {
        [[NSWorkspace sharedWorkspace] openFile:[item path]];
    }
}

- (void) executeNewFolder:(TreeBranch*)selectedBranch {
    // TODO:!!! Implementation of the new Folder
}


- (void)executeCut:(NSArray*) selectedFiles {
    // The cut: is identical to the copy: but the isCutPending is activated.
    // Its on the paste operation that the a decision is taken whether the cut
    // Can be done, if the application still maintains ownership of the pasteboard
    for (TreeItem *item in selectedFiles) {
        [item setTag:tagTreeItemToMove+tagTreeItemDirty];
    }
    [[self selectedView] refreshTableViewKeepingSelections];
    [self executeCopy:selectedFiles];
    isCutPending = YES;
}

- (void)executeCopy:(NSArray*) selectedFiles {

    // Get the urls from the view
    NSArray* items = [[self selectedView] getSelectedItems];
    NSArray* urls  = [items valueForKeyPath:@"@unionOfObjects.url"];
    // Will create name list for text application paste
    NSArray* names = [items valueForKeyPath:@"@unionOfObjects.name"];
    // Join the paths, one name per line
    NSString* pathPerLine = [names componentsJoinedByString:@"\n"];

    // Get The clipboard
    NSPasteboard* clipboard = [NSPasteboard generalPasteboard];

    // Store the Pasteboard counter for later to check ownership
    generalPasteBoardChangeCount = [clipboard changeCount];
    isCutPending = NO;

    // TODO:!! multi copy, where an additional copy will append items to the pasteboard
    /* use the following function of NSFileManager to create a directory that will serve as
     clipboard for situation where the Application can be closed.
     - (NSURL *)URLForDirectory:(NSSearchPathDirectory)directory
     inDomain:(NSSearchPathDomainMask)domain
     appropriateForURL:(NSURL *)url
     create:(BOOL)shouldCreate
     error:(NSError **)error
     */

    [clipboard clearContents];
    [clipboard writeObjects:urls];
    //Now add the pathsPerLine as a string
    [clipboard setString:pathPerLine forType:NSStringPboardType];

    NSUInteger count = [urls count];
    NSString *statusText;
    if (count==0) {
        statusText = [NSString stringWithFormat:@"No files selected"];
    } else if (count==1) {
        statusText = [NSString stringWithFormat:@"%lu file copied", (unsigned long)count];
    }
    else {
        statusText = [NSString stringWithFormat:@"%lu files copied", (unsigned long)count];
    }
    [_StatusBar setTitle:statusText];

}

- (void) executePaste:(TreeBranch*) destinationBranch {

    NSPasteboard *clipboard = [NSPasteboard generalPasteboard];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             NSPasteboardURLReadingFileURLsOnlyKey, [NSNumber numberWithBool:NO] ,
                             NSPasteboardURLReadingContentsConformToTypesKey, [NSArray arrayWithObjects: NSFilenamesPboardType, nil],
                             nil];
    NSArray *files = [clipboard readObjectsForClasses:
                      [NSArray arrayWithObjects: [NSURL class], nil]
                                              options:options];
    if (files!=nil && [files count]>0) {
        if (isCutPending) {
            if (generalPasteBoardChangeCount == [clipboard changeCount]) {
                // Make the move
                moveItemsToBranch(files, destinationBranch);
                // Update the Status bar with the information of a move
                NSString *statusText = [NSString stringWithFormat:@"Moving %ld files to %@",
                                        [files count],
                                        [destinationBranch path]
                                        ];
                [_StatusBar setTitle: statusText];
            }
            else {
                // Display a warning saying that the application lost control of the clipboard
                // and that the cut cannot be done. Will be aborted.
                NSAlert *alert = [NSAlert alertWithMessageText:@"Can't complete the Cut operation !"
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"Another application changed the System Clipboard."];
                [alert beginSheetModalForWindow:[self myWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
            }
        }
        else { // Make a regular copy
            copyItemsToBranch(files, destinationBranch);
            // Update the Status bar with the information of a copy
            NSString *statusText = [NSString stringWithFormat:@"Copying %ld files to %@",
                                    [files count],
                                    [destinationBranch path]
                                    ];
            [_StatusBar setTitle: statusText];
        }
    }
    else
        [_StatusBar setTitle: @"Nothing to paste"];
}


-(void) executeDelete:(NSArray*) selectedFiles {
    sendItemsToRecycleBin(selectedFiles);
}


#pragma mark Action Outlets


- (IBAction)toolbarInformation:(id)sender {
    [self executeInformation: [[self selectedView] getSelectedItems]];
}

- (IBAction)contextualInformation:(id)sender {
    [self executeInformation: [[self selectedView] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarRename:(id)sender {
    [self executeRename:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualRename:(id)sender {
    [self executeRename:[[self selectedView] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarDelete:(id)sender {
    [self executeDelete:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualDelete:(id)sender {
    [self executeDelete:[[self selectedView] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarCopyTo:(id)sender {
    [self executeCopyTo:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualCopyTo:(id)sender {
    [self executeCopyTo:[[self selectedView] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarMoveTo:(id)sender {
    [self executeMoveTo:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualMoveTo:(id)sender {
    [self executeMoveTo:[[self selectedView] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarOpen:(id)sender {
    [self executeOpen:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualOpen:(id)sender {
    [self executeOpen:[[self selectedView] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarNewFolder:(id)sender {
    NSArray *selectedItems = [[self selectedView] getSelectedItems];
    assert ([selectedItems count]==1); // This needs to be verified by the validateUserIterfaceItem
    [self executeNewFolder:(TreeBranch*) [selectedItems firstObject]];
}

- (IBAction)contextualNewFolder:(id)sender {
    // The last item is forcefully a Branch since it was checked in the validateUserIterfaceItem
    [self executeNewFolder:(TreeBranch*)[[self selectedView] getLastClickedItem]];
}


- (IBAction)toolbarSearch:(id)sender {
    // TODO:! Search Mode : Similar files Same Size, Same Kind, Same Date, ..., or Directory Search
    //- (BOOL)showSearchResultsForQueryString:(NSString *)queryString
}

- (IBAction)toolbarGrouping:(id)sender {
    // TODO:! Grouping pointer, select column to use for grouping
}

- (IBAction)toolbarRefresh:(id)sender {
    [self refreshAllViews:nil];
}

- (IBAction)toolbarHome:(id)sender {
    if ([sender isKindOfClass:[BrowserController class]]) {
        [self goHome:[self selectedView]];
        [(BrowserController*)[self selectedView] selectFirstRoot];
        [(BrowserController*)[self selectedView] refreshTrees];
    }
}


- (IBAction)orderPreferencePanel:(id)sender {
    NSLog(@"Preference Panel");
    if (userPreferenceWindow==nil)
        userPreferenceWindow =[[UserPreferencesDialog alloc] initWithWindowNibName:@"UserPreferencesDialog"];
    [userPreferenceWindow showWindow:self];

}

- (IBAction)operationCancel:(id)sender {
    NSArray *operations = [operationsQueue operations];
    [(NSOperation*)[operations firstObject] cancel];
}

- (IBAction)mruBackForwardAction:(id)sender {
    NSInteger backOrForward = [(NSSegmentedControl*)sender selectedSegment];
    // TODO:! Disable Back at the beginning Disable Forward
    // Create isABackFlag for the forward highlight and to test the Back
    // isAForward will make sure that the Forward is highlighted
    // otherwise Forward is disabled and Back Enabled
    id focused_browser = [self selectedView];
    if ([focused_browser isKindOfClass:[BrowserController class]]) {
        if (backOrForward==0) { // Backward
            [focused_browser backSelectedFolder];
        }
        else {
            [focused_browser forwardSelectedFolder];
        }
    }
    else {
        // TODO:! When other View Constrollers are implemented
    }
}


- (IBAction)cut:(id)sender {
    if ([sender isKindOfClass:[BrowserController class]] &&
        (sender==myLeftView || sender==myRightView)) {
        // First will mark the selected files to move
        [self executeCut:[[self selectedView] getSelectedItems]];
    }
    else {
        // other objects that can send a cut:
    }
}

- (IBAction)contextualCut:(id)sender {
    if ([sender isKindOfClass:[BrowserController class]] &&
        (sender==myLeftView || sender==myRightView)) {
        // First will mark the selected files to move
        [self executeCut:[[self selectedView] getSelectedItemsForContextMenu]];
    }
}

- (IBAction)copy:(id)sender {
    if ([sender isKindOfClass:[BrowserController class]] &&
        (sender==myLeftView || sender==myRightView)) {
        [self executeCopy:[[self selectedView] getSelectedItems]];
    }
    else {
        // other objects that can send a copy:
    }
}

- (IBAction)contextualCopy:(id)sender {
    if ([sender isKindOfClass:[BrowserController class]] &&
        (sender==myLeftView || sender==myRightView)) {
        [self executeCopy:[[self selectedView] getSelectedItemsForContextMenu]];
    }
}

- (IBAction)paste:(id)sender {
    if ([sender isKindOfClass:[BrowserController class]] &&
        (sender==myLeftView || sender==myRightView)) {
        TreeBranch *destinationBranch = [[self selectedView] treeNodeSelected];
        [self executePaste:destinationBranch];
    }
    else {
        // other objects that can send a paste:
    }
}

- (IBAction)contextualPaste:(id)sender {
    if ([sender isKindOfClass:[BrowserController class]] &&
        (sender==myLeftView || sender==myRightView)) {
        // TODO: Need to insure on the validateUserInterfaceItem that node is Branch
        [self executePaste:(TreeBranch*)[[self selectedView] getLastClickedItem]];
    }
}

-(IBAction)delete:(id)sender {
    if ([sender isKindOfClass:[BrowserController class]] &&
        (sender==myLeftView || sender==myRightView)) {
        [self executeDelete:[(BrowserController*)sender getSelectedItems]];
    }
    else {
        // other objects that can send a delete:
    }
}


#pragma mark Menu Validation

//- (BOOL)validateMenuItem:(NSMenuItem *)item {
//    NSInteger row = [_myTableView selectedRow];
//    if ([item action] == @selector(newFolder) &&
//        (row == [tableData indexOfObject:[tableData lastObject]])) {
//        return NO;
//    }
//    if ([item action] == @selector(priorRecord) && row == 0) {
//        return NO;
//    }
//    return YES;
//}

// These pragmas avoid the warning on the toolbarNewFolder
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wundeclared-selector"
//#pragma clang diagnostic pop


- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    SEL theAction = [anItem action];
    BOOL allow = YES; // The default is yes, unless there is a condition that invalidates it

    /* This is done like this so that not more than one folder is selected */
    NSArray *itemsSelected=nil;

    // Actions that can always be done
    if (theAction == @selector(toolbarHome:) ||
        theAction == @selector(toolbarRefresh:) ||
        theAction == @selector(toolbarSearch:) ||
        theAction == @selector(toolbarGrouping:)
        ) {
        return YES;
    }

    // Actions that require a contextual selection
    if (theAction == @selector(contextualCopy:) ||
        theAction == @selector(contextualCopyTo:) ||
        theAction == @selector(contextualCut:) ||
        theAction == @selector(contextualDelete:) ||
        theAction == @selector(contextualInformation:) ||
        theAction == @selector(contextualMoveTo:) ||
        theAction == @selector(contextualNewFolder:) ||
        theAction == @selector(contextualOpen:) ||
        theAction == @selector(contextualRename:) ||
        theAction == @selector(contextualPaste:)
        ) {
        itemsSelected = [(BrowserController*)[self selectedView] getSelectedItemsForContextMenu];
    }
    else {
        itemsSelected = [(BrowserController*)[self selectedView] getSelectedItems];
    }


    //NSLog(@"Items selected");
    //for (TreeItem *d in itemsSelected) {
    //    NSLog(@"%@", [d path]);
    //}

    if ([itemsSelected count]==0) { // no selection, go for the selected view
        TreeBranch *targetFolder = [[self selectedView] treeNodeSelected];
        // TODO:!!! check whether the folder is accessible
        // For now assuming a NO

        if (theAction == @selector(toolbarNewFolder:) ||
            theAction == @selector(contextualNewFolder:)) {
            if ([targetFolder hasTags:tagTreeItemReadOnly]) {
                allow = NO;
            }
        }
        else if (theAction == @selector(paste:) ||
                 theAction == @selector(contextualPaste:)) {
            if ([targetFolder hasTags:tagTreeItemReadOnly]) {
                allow = NO;
            }
        }
        else
        {
            allow = NO;
        }
    }
    else {
        for (TreeItem *item in itemsSelected) {
            // Actions that can always be made
            if (theAction == @selector(contextualCopy:) ||
                theAction == @selector(contextualCopyTo:) ||
                theAction == @selector(contextualInformation:) ||
                theAction == @selector(contextualOpen:) ||
                theAction == @selector(copy:) ||
                theAction == @selector(toolbarCopyTo:) ||
                theAction == @selector(toolbarInformation:) ||
                theAction == @selector(toolbarOpen:)
                ) {

            }
            // Actions that can only be made in one file and req. R/W
            if (theAction == @selector(contextualRename:) ||
                theAction == @selector(toolbarRename:)
                ) {
                if (([itemsSelected count]!=1) || ([item hasTags:tagTreeItemReadOnly]))
                    allow = NO;
            }

            // actions that require Folder write access
            else if (theAction == @selector(toolbarNewFolder:) ||
                theAction == @selector(paste:) ||
                theAction == @selector(contextualNewFolder:) ||
                theAction == @selector(contextualPaste:)
                ) {
                if ([item isKindOfClass:[TreeBranch class]]==NO)
                {
                    allow = NO;
                }
                else if ([item hasTags:tagTreeItemReadOnly]) {
                    allow = NO;
                }
            }

            // Actions that require delete access
            else if (theAction == @selector(contextualCut:) ||
                theAction == @selector(contextualDelete:) ||
                theAction == @selector(contextualMoveTo:) ||
                theAction == @selector(toolbarDelete:) ||
                theAction == @selector(cut:) ||
                theAction == @selector(delete:)
                ) {
                if ([item hasTags:tagTreeItemReadOnly]) {
                    allow = NO;
                }
            }

            if (!allow) // Stop if a not allow is found
                break;
        }
    }
    //NSLog(@"%ld  %hhd", (long)[anItem tag], allow);
    return allow; //[super validateUserInterfaceItem:anItem];
}

#pragma mark -


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
    id selView = [theNotification object];
    // Updates the window Title
    NSArray *titleComponents = [NSArray arrayWithObjects:@"File Catalyst",
                                [myLeftView title],
                                [myRightView title], nil];
    NSString *windowTitle = [titleComponents componentsJoinedByString:@" - "];
    [[self myWindow] setTitle:windowTitle];

    if ([selView isKindOfClass:[BrowserController class]]) {

        NSArray *selectedFiles = [selView getSelectedItems];

        if (selectedFiles != nil) {
            NSInteger num_files=0;
            NSInteger files_size=0;
            NSInteger folders_size=0;
            NSInteger num_directories=0;
            if (applicationMode==ApplicationwModeDuplicate && selView==myLeftView) {
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
                if ([(BrowserController*)selView viewMode]==BViewBrowserMode) {
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
                // The file system notifications will make sure that the views are updated
                break;
            case FileExistsSkip:
                /* Basically we don't do nothing */
                break;
            case FileExistsReplace: {
                // Erase the file ... and copy again.
                //sendToRecycleBin();

                [[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:destinationURL] completionHandler:^(NSDictionary *newURLs, NSError *error) {
                    if (error!=nil) {
                        copyURLToURL(sourceURL, destinationURL);
                    }
                }];
                }
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
                // Failed to created either the source or the destination. Not likely to happen but...
                // Messagebox with alert
                NSAlert *alert = [NSAlert alertWithMessageText:@"Can't complete the operation !"
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"Failed to allocate memory."];
                [alert beginSheetModalForWindow:[self myWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
            }
        }
        else {
            NSLog(@"Error not processed %@", error); // Don't comment this, before all tests are completed.
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
