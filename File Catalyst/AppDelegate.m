//
//  AppDelegate.m
//  Caravelle
//
//  Created by Nuno Brum on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//


#import "AppDelegate.h"
#import "FileCollection.h"
#import "TreeLeaf.h"
#import "TreeManager.h"
#import "TreeScanOperation.h"
#import "searchTree.h"
#import "FileUtils.h" // The app shouldnt use functions that access the system directly. Rather go through the Operations
#import "FileOperation.h"
#import "DuplicateFindOperation.h"
#import "FileExistsChoice.h"

#import "DuplicateFindSettingsViewController.h"
#import "UserPreferencesDialog.h"
#import "RenameFileDialog.h"


// TODO:! Virtual Folders
// #import "filterBranch.h"
// #import "CatalogBranch.h"
#import "myValueTransformers.h"

NSString *notificationStatusUpdate=@"StatusUpdateNotification";


NSString *notificationCatalystRootUpdate=@"RootUpdate";
NSString *catalystRootUpdateNotificationPath=@"RootUpdatePath";


NSString *notificationDoFileOperation = @"DoOperation";
NSString *kDFOOperationKey =@"OperationKey";
NSString *kDFODestinationKey =@"DestinationKey";
NSString *kDFORenameFileKey = @"RenameKey";
NSString *kNewFolderKey = @"NewFolderKey";
NSString *kDFOFilesKey=@"FilesSelected";
NSString *kDFOErrorKey =@"ErrorKey";
NSString *kDFOOkKey = @"OKKey";
//NSString *kFromObjectKey = @"FromObjectKey";

#ifdef USE_UTI
const CFStringRef kTreeItemDropUTI=CFSTR("com.cascode.treeitemdragndrop");
#endif

NSString *opOpenOperation=@"OpenOperation";
NSString *opCopyOperation=@"CopyOperation";
NSString *opMoveOperation =@"MoveOperation";
NSString *opEraseOperation =@"EraseOperation";
NSString *opSendRecycleBinOperation = @"SendRecycleBin";
NSString *opNewFolder = @"NewFolderOperation";
NSString *opRename = @"RenameOperation";

NSFileManager *appFileManager;
NSOperationQueue *operationsQueue;         // queue of NSOperations (1 for parsing file system, 2+ for loading image files)

NSArray *get_clipboard_files(NSPasteboard *clipboard) {

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             /* obj */   [NSNumber numberWithBool:YES] ,
                             /* key */    NSPasteboardURLReadingFileURLsOnlyKey,
                             ///* obj */   [NSArray arrayWithObjects: NSFilenamesPboardType, nil],
                             ///* key */    NSPasteboardURLReadingContentsConformToTypesKey,
                             nil];
    NSArray *files = [clipboard readObjectsForClasses:
                      [NSArray arrayWithObjects: [NSURL class], nil]
                                              options:options];
    return files;
    
}

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
    BOOL isApplicationTerminating;
    BOOL isWindowClosing;
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
        NSValueTransformer *date_transformer = [[DateToStringTransformer alloc] init];
        [NSValueTransformer setValueTransformer:date_transformer forName:@"date"];
        NSValueTransformer *size_transformer = [[SizeToStringTransformer alloc] init];
        [NSValueTransformer setValueTransformer:size_transformer forName:@"size"];

        isCutPending = NO; // used for the Cut to Clipboard operations.
        isApplicationTerminating = NO; // to inform that the application should quit after all processes are finished.
        isWindowClosing = NO;
        //FSMonitorThread = [[FileSystemMonitoring alloc] init];

	}
	return self;
}

#pragma mark auxiliary functions

-(void) goHome:(id) view {
    // Change the selected view to go Home in Browser Mode
    if ([view isKindOfClass:[BrowserController class]]) {
        NSString *homepath;
        NSURL *url;
        if (view == myLeftView) {
            // Get from User Parameters
            homepath = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEF_LEFT_HOME];
        }
        else if (view == myRightView) {
            homepath = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEF_RIGHT_HOME];
            if (homepath == nil || [homepath isEqualToString:@""]) {
                // if there is no path assigned, just use the one of the left
                homepath = [[myLeftView treeNodeSelected] path];
            }
        }

        // Check whether the url is authorized
#if (APP_IS_SANDBOXED==1)

        // there is a stored homepath
        if (homepath != nil && ![homepath isEqualToString:@""]) {
            url = [NSURL fileURLWithPath:homepath isDirectory:YES];
            NSURL *url_allowed = [(TreeManager*)appTreeManager secScopeContainer:url];

            // and this homepath is authorized
            if (url_allowed!=nil) {
                id item = [(TreeManager*)appTreeManager addTreeItemWithURL:url_allowed];
                [(BrowserController*)view removeAll];
                [(BrowserController*)view setViewMode:BViewBrowserMode ];
                [(BrowserController*)view setViewType:BViewTypeVoid];
                [(BrowserController*)view addTreeRoot: item];
                [(BrowserController*)view selectFirstRoot];
                [(BrowserController*)view refresh];
                return;
            }
            else {
                NSLog(@"AppDelegate.goHome: No authorization to access: %@", homepath);
            }
        }
        else {
            NSLog(@"AppDelegate.goHome:Failed to retrieve home folder from NSUserDefaults");
        }

        [self executeOpenFolderInView:view withTitle:@"Select a Folder to Browse"];


#else
        if (homepath == nil || [homepath isEqualToString:@""]) {
            NSLog(@"Failed to retrieve home folder from NSUserDefaults. Using Home Directory");
            homepath = NSHomeDirectory();
        }

        url = [NSURL fileURLWithPath:homepath isDirectory:YES];
        id item = [(TreeManager*)appTreeManager addTreeItemWithURL:url];
        [(BrowserController*)view removeAll];
        [(BrowserController*)view setViewMode:BViewBrowserMode];
        [(BrowserController*)view setViewType:BViewTypeVoid];
        [(BrowserController*)view addTreeRoot: item];
        [(BrowserController*)view selectFirstRoot];
#endif
        [(BrowserController*)view refresh];
    }
}

-(id) selectedView {
    return _selectedView;
}

-(id) contextualFocus {
    return self->_contextualFocus;
}

#pragma mark - Application Delegate

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

    // register for the notification when an image file has been loaded by the NSOperation: "LoadOperation"
	[center addObserver:self selector:@selector(anyThread_handleTreeConstructor:) name:notificationTreeConstructionFinished object:nil];
    [center addObserver:self selector:@selector(startOperationHandler:) name:notificationDoFileOperation object:nil];
    [center addObserver:self selector:@selector(processNextError:) name:notificationClosedFileExistsWindow object:nil];
    [center addObserver:self selector:@selector(startDuplicateFind:) name:notificationStartDuplicateFind object:nil];
    [center addObserver:self selector:@selector(anyThread_handleDuplicateFinish:) name:notificationDuplicateFindFinish object:nil];

    [center addObserver:self selector:@selector(anyThread_operationFinished:) name:notificationFinishedFileOperation object:nil];

    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:nil];

    [center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:nil];

    [center addObserver:self selector:@selector(refreshAllViews:) name:notificationRefreshViews object:nil];

    // register self as the the Delegate for the main window
    [_myWindow setDelegate:self];

    /* Registering for receiving services */
    NSArray *sendTypes = [NSArray arrayWithObjects:NSURLPboardType,
                          NSFilenamesPboardType, nil];
    NSArray *returnTypes = [NSArray arrayWithObjects:NSURLPboardType,
                            NSFilenamesPboardType, nil];
    [NSApp registerServicesMenuSendTypes:sendTypes
                             returnTypes:returnTypes];

    myLeftView  = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
    [myLeftView setParentController:self];

    applicationMode = [[NSUserDefaults standardUserDefaults] integerForKey:USER_DEF_APP_VIEW_MODE];

    if (applicationMode == ApplicationMode2Views) {
        myRightView = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
        [myRightView setParentController:self];

        [myLeftView  setName:@"Left"  TwinName:@"Right"];
        [myRightView setName:@"Right" TwinName:@"Left"];
        [_ContentSplitView addSubview:myLeftView.view];
        [_ContentSplitView addSubview:myRightView.view];
        [self.buttonCopyTo setEnabled:YES];
        [self.buttonMoveTo setEnabled:YES];
    }
    else if (applicationMode == ApplicationMode1View) {
        myRightView = nil;
        [myLeftView setName:@"Single" TwinName:nil]; // setting to nil causes the cross operations menu's to be disabled
        [_ContentSplitView addSubview:myLeftView.view];
        [self.buttonCopyTo setEnabled:NO];
        [self.buttonMoveTo setEnabled:NO];

    }


    //NSDictionary *viewsDictionary = [NSDictionary dictionaryWithObject:myLeftView.view forKey:@"myLeftView"];
    //NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[myLeftView]-0-|"
    //                                                               options:0 metrics:nil views:viewsDictionary];
    //[myLeftView.view addConstraints:constraints];

    // Left Side
    [self goHome: myLeftView]; // Display the User Preferences Left Home
    // Right side
    if (myRightView)
        [self goHome: myRightView]; // Display the User Preferences Left Home

    [self.ContentSplitView adjustSubviews];
    // Make a default focus
    self->_selectedView = myLeftView;
    // Set the Left view as first responder
    [myLeftView focusOnFirstView];

}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    static BOOL firstAppActivation = YES;

    if (firstAppActivation == YES) {
        firstAppActivation = NO;

        /*if (0) { // Testing Catalyst Mode
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
        }*/
        /*if (0) { // TODO:! Testing filter and catalog Branches
            NSURL *url = [NSURL fileURLWithPath:@"/Users/vika/Documents" isDirectory:YES];
            //item = [(TreeManager*)appTreeManager addTreeBranchWithURL:url];
            if(0) { // Debug Code
                searchTree *st = [[searchTree alloc] initWithSearch:@"*" name:@"Document Search" parent:nil];
                [st setUrl:url]; // Setting the url since the init doesn't. This is a workaround for the time being
                NSPredicate *filter;
                filterBranch *fb;
                filter = [NSPredicate predicateWithFormat:@"SELF.itemType==ItemTypeBranch"];
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
                [st setUrl:url]; // Setting the url since the init doesn't. This is a workaround for the time being
                [st setFilter:[NSPredicate predicateWithFormat:@"SELF.itemType==ItemTypeBranch"]];
                [st setCatalogKey:@"date_modified"];
                [st setValueTransformer:DateToYearTransformer()];
                [st createSearchPredicate];
                [(BrowserController*)myLeftView initBrowserView:BViewBrowserMode twin:@"Right"];
                [(BrowserController*)myLeftView addTreeRoot: st];

            }
            [(BrowserController*)myLeftView selectFirstRoot];
        }*/
    }
    /* Ajust the subView window Sizes */
    [_ContentSplitView adjustSubviews];
    [_ContentSplitView setNeedsDisplay:YES];

    // Showing non Modal child dialogs
    [fileExistsWindow displayWindow:self];
}

-(NSApplicationTerminateReply) shouldTerminate:(id) sender {
    // are you sure you want to close, (threads running)
    NSInteger numOperationsRunning = [[operationsQueue operations] count];
    NSInteger numErrorsPending = [pendingOperationErrors count];

    BOOL fromWindowClosing = sender == _myWindow;

    if (fromWindowClosing) {
        // Force a store of the User Defaults
        NSString *homepath = [[myLeftView treeNodeSelected] path];
        [[NSUserDefaults standardUserDefaults] setObject:homepath forKey:USER_DEF_LEFT_HOME];
        homepath = [[myRightView treeNodeSelected] path];
        [[NSUserDefaults standardUserDefaults] setObject:homepath forKey:USER_DEF_RIGHT_HOME];
        BOOL OK = [[NSUserDefaults standardUserDefaults] synchronize];
        if (!OK)
            NSLog(@"AppDelegate.shouldTerminate: Failed to store User Defaults");
    }

    if (numOperationsRunning ==0 && numErrorsPending==0) {
        return NSTerminateNow;
    }
    else {
        if (numErrorsPending) {
            NSAlert *alert = [[NSAlert alloc] init];
            if (fromWindowClosing) {
                [alert addButtonWithTitle:@"Exit"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"Show Window"];
            }
            else {
                [alert addButtonWithTitle:@"Exit"];
                [alert addButtonWithTitle:@"Show Window"];
            }
            [alert setMessageText:@"There are pending errors to be evaluated. Are you sure to exit the Application"];
            [alert setInformativeText:@"Errors were found in copy/move operations and\nuser input is being requested."];

            [alert setAlertStyle:NSWarningAlertStyle];
            NSModalResponse reponse = [alert runModal];
            if (reponse == NSAlertFirstButtonReturn) {
                [fileExistsWindow closeWindow];
                return NSTerminateNow;
            }
            else if (reponse == NSAlertSecondButtonReturn) {
                if (!fromWindowClosing)
                    [fileExistsWindow displayWindow:self];
                return NSTerminateCancel;
            }

            // only displayed if message is comming from window closing
            else if (reponse == NSAlertThirdButtonReturn) {
                [fileExistsWindow displayWindow:self];
                return NSTerminateLater;
            }

        }
        // Repeat the the text. Operations might have been finished.
        numOperationsRunning = [[operationsQueue operations] count];

        if (numOperationsRunning!=0) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Exit"];
            if (fromWindowClosing)
                [alert addButtonWithTitle:@"Cancel"];
            else
                [alert addButtonWithTitle:@"Wait"];
            [alert setMessageText:@"There are still operations ongoing. Are you sure to exit the Application"];
            [alert setInformativeText:@"If wait is selected, the application will terminate\nonce ongoing operations are finished."];
            [alert setAlertStyle:NSWarningAlertStyle];
            NSModalResponse reponse = [alert runModal];
            if (reponse == NSAlertFirstButtonReturn) {
                return NSTerminateNow;
            }
            else if (reponse == NSAlertSecondButtonReturn) {
                if (fromWindowClosing) {
                    return NSTerminateCancel;
                }
                else {
                    return NSTerminateLater;
                }
            }
        }
        else {
            return NSTerminateNow;
        }
        return NSTerminateCancel;
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    NSApplicationTerminateReply answer = [self shouldTerminate:sender];
    if (answer==NSTerminateLater)
        // Will terminate the application once the operations finish
        isApplicationTerminating = YES;
    else if (answer == NSTerminateNow) {
        // liberate resources
        [appTreeManager stopAccesses];
    }
    return answer;
}

/*-(void) applicationWillTerminate:(NSNotification *)aNotification {
    // TODO:!! applicationWillTerminate :Save Application State
    NSLog(@"Application Will Terminate");
}*/

//When the app is deactivated
-(void) applicationWillResignActive:(NSNotification *)aNotification {
    //NSLog(@"Application Will Resign Active");

    // Force a store of the User Defaults
    BOOL OK = [[NSUserDefaults standardUserDefaults] synchronize];
    if (!OK)
        NSLog(@"AppDelegate.applicationWillResignActive: Failed to store User Defaults");
}


//When the user hides your app
-(void) applicationWillHide:(NSNotification *)aNotification {
    [fileExistsWindow closeWindow];
}

#pragma mark - NSWindow Delegate
-(BOOL) windowShouldClose:(id)sender {
    // closes the window if the application is OK to terminate
    NSApplicationTerminateReply answer = [self shouldTerminate:sender];
    if (answer==NSTerminateNow) {
        return YES;
    }
    else if (answer == NSTerminateLater) {
        isApplicationTerminating = YES;
        isWindowClosing = YES;
    }
    return NO;
}

#pragma mark Services Support
/* Services Pasteboard Operations */

- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType
{
    if ([sendType isEqual:NSFilenamesPboardType] ||
        [sendType isEqual:NSURLPboardType]) {
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
    [(id<MYViewProtocol>)myLeftView refresh];
    [(id<MYViewProtocol>)myRightView refresh];
}

/* Receives the notification from the BrowserView to reload the Tree */

//TODO:!! Revise this code. Only used in notificationCatalystRootUpdate
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

- (void) executeOpenFolderInView:(id)view withTitle:(NSString*) dialogTitle {
    if ([view isKindOfClass:[BrowserController class]]) {
        /* Will get a new node from shared tree Manager and add it to the root */
        /* This addTreeBranchWith URL will retrieve from the treeManager if not creates it */

        NSURL *url = [appTreeManager powerboxOpenFolderWithTitle:dialogTitle];
        if (url != nil) {
            id item = [(TreeManager*)appTreeManager addTreeItemWithURL:url];
            if (item != nil) {
                // Add to the Browser View
                [(BrowserController*)view removeAll];
                [(BrowserController*)view setViewMode:BViewBrowserMode];
                [(BrowserController*)view setViewType:BViewTypeVoid];
                [(BrowserController*)view addTreeRoot: item];
                [(BrowserController*)view selectFirstRoot];
                [(BrowserController*)view refresh];

            }
        }

    }
}

- (void) executeRename:(NSArray*) selectedFiles {
    NSUInteger numberOfFiles = [selectedFiles count];
    // TODO: ! Option for the rename, on the table or on a dedicated dialog
    if (numberOfFiles == 1) {
        TreeItem *selectedFile = [selectedFiles firstObject];
        NSString *oldFilename = [[selectedFile path] lastPathComponent];
        if (1) { // Rename done in place
            [[self selectedView] startEditItemName:selectedFile];
        }
        // Using a dialog Box
        else {
            // If only one file, with edit with RenameFileDialog
            if (renameFilePanel==nil)
                renameFilePanel =[[RenameFileDialog alloc] initWithWindowNibName:@"RenameFileDialog"];
            [renameFilePanel showWindow:self];
            // NOTE: If the showWindow is invoked after the statement below it doesn't work
            [renameFilePanel setRenamingFile:oldFilename];
            [NSApp runModalForWindow: [renameFilePanel window]];
            // Got info from window going to make the rename
            NSString *fileName = [renameFilePanel getRenameFile];

            if (NO==[oldFilename isEqualToString:fileName]) {

                // Create the File Operation
                NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      selectedFiles, kDFOFilesKey,
                                      opRename, kDFOOperationKey,
                                      fileName, kDFORenameFileKey,
                                      [[self selectedView] treeNodeSelected], kDFODestinationKey,
                                      nil];
                putInQueue(taskinfo);
            }
        }
    }
    else if (numberOfFiles > 1) {
        // TODO:!! Implement the multi-rename
        // If more than one file, will invoke the multi-rename dialog
        // For the time being this is an invalid condition. Need to notify user.
        NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid Selection !"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Select only one Folder"];
        [alert beginSheetModalForWindow:[self myWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];

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
    NSURL *newURL = [[selectedBranch url] URLByAppendingPathComponent:@"New Folder"];
    TreeBranch *newFolder = [[TreeBranch alloc] initWithURL:newURL parent:selectedBranch];
    [newFolder setTag:tagTreeItemNew];
    [newFolder resetTag:tagTreeItemReadOnly];
    [[self selectedView] insertItem:newFolder];
    [[self selectedView] startEditItemName:newFolder];
}


- (void)executeCut:(NSArray*) selectedFiles {
    // The cut: is identical to the copy: but the isCutPending is activated.
    // Its on the paste operation that the a decision is taken whether the cut
    // Can be done, if the application still maintains ownership of the pasteboard

    // First will mark the selected files to move
    for (TreeItem *item in selectedFiles) {
        [item setTag:tagTreeItemToMove+tagTreeItemDirty];
    }
    [[self selectedView] refresh]; // TODO:! replace this with KVO observed->reloadItem
    [self executeCopy:selectedFiles onlyNames:NO];
    isCutPending = YES; // This instruction has to be always made after the executeCopy
}


- (void)executeCopy:(NSArray*) selectedFiles onlyNames:(BOOL)onlyNames {

    // Get the urls from the view
    NSArray* items = [[self selectedView] getSelectedItems];

    // Will create name list for text application paste
    // TODO:!! multi copy, where an additional copy will append items to the pasteboard
    /* use the following function of NSFileManager to create a directory that will serve as
     clipboard for situation where the Application can be closed.
     - (NSURL *)URLForDirectory:(NSSearchPathDirectory)directory
     inDomain:(NSSearchPathDomainMask)domain
     appropriateForURL:(NSURL *)url
     create:(BOOL)shouldCreate
     error:(NSError **)error
     */


    // Get The clipboard
    NSPasteboard* clipboard = [NSPasteboard generalPasteboard];
    [clipboard clearContents];
    [clipboard declareTypes:[NSArray arrayWithObjects:
                                    NSURLPboardType,
                                    //NSFilenamesPboardType,
                                    // NSFileContentsPboardType, not passing file contents
                                    NSStringPboardType, nil]
                      owner:nil];

    if (onlyNames==YES) {
        NSArray* str_representation = [items valueForKeyPath:@"@unionOfObjects.name"];
        // Join the paths, one name per line
        NSString* pathPerLine = [str_representation componentsJoinedByString:@"\n"];
        //Now add the pathsPerLine as a string
        [clipboard setString:pathPerLine forType:NSStringPboardType];
    }
    // if only names are copied, the urls are not
    else {
        NSArray* urls  = [items valueForKeyPath:@"@unionOfObjects.url"];
        [clipboard writeObjects:urls];
    }

    // Store the Pasteboard counter for later to check ownership
    generalPasteBoardChangeCount = [clipboard changeCount];
    isCutPending = NO;

    NSUInteger count = [items count];
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
    NSArray *files = get_clipboard_files(clipboard);

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


- (void) updateFocus:(id)sender {
    if (sender == myLeftView || sender == myRightView)
        _selectedView = sender;
    else {
        NSLog(@"AppDelegate.updateSelected: - Case not expected. Unknown View");
        assert(false);
    }
}

- (void) contextualFocus:(id)sender {
    if (sender == myLeftView || sender == myRightView)
        _contextualFocus = sender;
    else {
        NSLog(@"AppDelegate.updateSelected: - Case not expected. Unknown View");
        assert(false);
    }
}


- (IBAction)toolbarInformation:(id)sender {
    NSArray *selectedFiles = [[self selectedView] getSelectedItems];
    if (selectedFiles != nil && [selectedFiles count]!=0) {
        [self executeInformation: selectedFiles];
    }
}

- (IBAction)contextualInformation:(id)sender {
    [self executeInformation: [[self contextualFocus] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarRename:(id)sender {
    [self executeRename:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualRename:(id)sender {
    [self executeRename:[[self contextualFocus] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarDelete:(id)sender {
    [self executeDelete:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualDelete:(id)sender {
    [self executeDelete:[[self contextualFocus] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarCopyTo:(id)sender {
    [self executeCopyTo:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualCopyTo:(id)sender {
    [self executeCopyTo:[[self contextualFocus] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarMoveTo:(id)sender {
    [self executeMoveTo:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualMoveTo:(id)sender {
    [self executeMoveTo:[[self contextualFocus] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarOpen:(id)sender {
    [self executeOpen:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualOpen:(id)sender {
    [self executeOpen:[[self contextualFocus] getSelectedItemsForContextMenu]];
}

- (IBAction)toolbarNewFolder:(id)sender {
    NSArray *selectedItems = [[self selectedView] getSelectedItems];
    NSInteger selectionCount = [selectedItems count];
    if (selectionCount!=0) {
        // TODO:!! Ask whether to move the files into the new created Folder
    }
    [self executeNewFolder:[[self selectedView] treeNodeSelected]];
}

- (IBAction)contextualNewFolder:(id)sender {
    // The last item is forcefully a Branch since it was checked in the validateUserIterfaceItem
    [self executeNewFolder:(TreeBranch*)[[self selectedView] getLastClickedItem]];
}

- (IBAction)toolbarGotoFolder:(id)sender {
    [self executeOpenFolderInView:[self selectedView] withTitle:@"Select a Folder"];
}

- (IBAction)contextualGotoFolder:(id)sender {
    [self executeOpenFolderInView:sender withTitle:@"Select a Folder"];
}


- (IBAction)toolbarSearch:(id)sender {
    // TODO:! Search Mode : Similar files Same Size, Same Kind, Same Date, ..., or Directory Search
    //- (BOOL)showSearchResultsForQueryString:(NSString *)queryString
}

- (IBAction)toolbarGrouping:(id)sender {
    // TODO:!!! Grouping pointer, select column to use for grouping
}

- (IBAction)toolbarRefresh:(id)sender {
    [self refreshAllViews:nil];
}

- (IBAction)toolbarHome:(id)sender {
    if ([sender isKindOfClass:[BrowserController class]]) {
        [self goHome:[self selectedView]];
        [(BrowserController*)[self selectedView] selectFirstRoot];
        [(BrowserController*)[self selectedView] refresh];
    }
}


- (IBAction)orderPreferencePanel:(id)sender {
    if (userPreferenceWindow==nil)
        userPreferenceWindow =[[UserPreferencesDialog alloc] initWithWindowNibName:@"UserPreferencesDialog"];
    [userPreferenceWindow showWindow:self];

}

- (IBAction)operationCancel:(id)sender {
    NSArray *operations = [operationsQueue operations];
    [(NSOperation*)[operations firstObject] cancel];
}

//- (IBAction)mruBackForwardAction:(id)sender {
//    NSInteger backOrForward = [(NSSegmentedControl*)sender selectedSegment];
//    //To do: ! Disable Back at the beginning Disable Forward
//    // Create isABackFlag for the forward highlight and to test the Back
//    // isAForward will make sure that the Forward is highlighted
//    // otherwise Forward is disabled and Back Enabled
//    id focused_browser = [self selectedView];
//    if ([focused_browser isKindOfClass:[BrowserController class]]) {
//        if (backOrForward==0) { // Backward
//            [focused_browser backSelectedFolder];
//        }
//        else {
//            [focused_browser forwardSelectedFolder];
//        }
//    }
//    else {
//        // TODO:! When other View Constrollers are implemented
//    }
//}


- (IBAction)cut:(id)sender {
    [self executeCut:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualCut:(id)sender {
    [self executeCut:[[self contextualFocus] getSelectedItemsForContextMenu]];
}

- (IBAction)copy:(id)sender {
    [self executeCopy:[[self selectedView] getSelectedItems] onlyNames:NO];
}

- (IBAction)contextualCopy:(id)sender {
    [self executeCopy:[[self contextualFocus] getSelectedItemsForContextMenu] onlyNames:NO];
}

- (IBAction)copyName:(id)sender {
    [self executeCopy:[[self selectedView] getSelectedItems] onlyNames:YES];
}

- (IBAction)contextualCopyName:(id)sender {
    [self executeCopy:[[self contextualFocus] getSelectedItemsForContextMenu] onlyNames:YES];
}


- (IBAction)paste:(id)sender {
    TreeBranch *destinationBranch = [[self selectedView] treeNodeSelected];
    [self executePaste:destinationBranch];

}

- (IBAction)contextualPaste:(id)sender {
    // the validateMenuItems insures that node is Branch
    [self executePaste:(TreeBranch*)[[self selectedView] getLastClickedItem]];
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

- (IBAction)appModeChanged:(id)sender {
    NSInteger mode = [(NSSegmentedControl*)sender selectedSegment];
    NSUInteger panelCount = [[self.ContentSplitView subviews] count];

    if (mode == ApplicationMode1View) {
        if (myRightView!=nil && panelCount == 2) {
            [myLeftView setName:@"Single" TwinName:nil];
            [myRightView.view removeFromSuperview];
            [self.buttonCopyTo setEnabled:NO];
            [self.buttonMoveTo setEnabled:NO];
            //myRightView.view = nil;
        }
    }
    else if (mode == ApplicationMode2Views) {
        if (panelCount==1) {
            if (myRightView == nil) {
                myRightView = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
                [myLeftView setName:@"Left" TwinName:@"Right"];
                [myRightView setName:@"Right" TwinName:@"Left"];
                [_ContentSplitView addSubview:myRightView.view];
                [self goHome:myRightView];
            }
            else if (myRightView.view==nil) {
                NSLog(@"AppDelegate.appModeChanged: No valid View in the myRightView Object");
                return;
            }
            else {
                [_ContentSplitView addSubview:myRightView.view];
                [myRightView refresh]; // Just Refreshes
            }
            [self.buttonCopyTo setEnabled:YES];
            [self.buttonMoveTo setEnabled:YES];

        }
    }
    [self.ContentSplitView adjustSubviews];
    [self.ContentSplitView displayIfNeeded];
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
        theAction == @selector(toolbarGrouping:) ||
        theAction == @selector(toolbarGotoFolder:) ||
        theAction == @selector(orderPreferencePanel:)
        ) {
        return YES;
    }

    // Actions that require a contextual selection
    if (theAction == @selector(contextualCopy:) ||
        theAction == @selector(contextualCopyName:) ||
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
        itemsSelected = [(BrowserController*)[self contextualFocus] getSelectedItemsForContextMenu];
    }
    else {
        itemsSelected = [(BrowserController*)[self selectedView] getSelectedItems];
    }

    if (itemsSelected==nil) {
        // If nothing was returned is selected then don't allow anything
        allow = NO;
    }
    else if ([itemsSelected count]==0) { // no selection, go for the selected view
        TreeBranch *targetFolder = [[self selectedView] treeNodeSelected];
        
        if (theAction == @selector(toolbarNewFolder:) ||
            theAction == @selector(contextualNewFolder:)) {
            if ([targetFolder hasTags:tagTreeItemReadOnly]) {
                allow = NO;
            }
            // No other conditions. This is supposed to be a folder, no need to test this condition
        }
        else if (theAction == @selector(paste:) ||
                 theAction == @selector(contextualPaste:)) {
            if ([targetFolder hasTags:tagTreeItemReadOnly]) {
                allow = NO;
            }
            // Check if paste board has valid data
            else {
                NSPasteboard *clipboard = [NSPasteboard generalPasteboard];
                NSArray *files = get_clipboard_files(clipboard);
                if ([files count]==0) {
                    allow = NO;
                }
            }
            // No other conditions. This is supposed to be a folder, no need to test this condition
        }
        else {
            allow = NO;
        }
    }
    else {
        for (TreeItem *item in itemsSelected) {
            // Actions that can always be made
            if (theAction == @selector(contextualCopy:) ||
                theAction == @selector(contextualCopyName:) ||
                theAction == @selector(contextualCopyTo:) ||
                theAction == @selector(contextualInformation:) ||
                theAction == @selector(contextualOpen:) ||
                theAction == @selector(copy:) ||
                theAction == @selector(copyName:) ||
                theAction == @selector(toolbarCopyTo:) ||
                theAction == @selector(toolbarInformation:) ||
                theAction == @selector(toolbarOpen:)
                ) {

            }
            // Actions that can only be made in one file and req. R/W
            else if (theAction == @selector(contextualRename:) ||
                theAction == @selector(toolbarRename:)
                ) {
                if (([itemsSelected count]!=1) || ([item hasTags:tagTreeItemReadOnly]))
                    allow = NO;
            }

            // actions that require Folder write access
            else if (theAction == @selector(paste:) ||
                     theAction == @selector(contextualPaste:)
                ) {
                if ([item itemType] != ItemTypeBranch) {
                    allow = NO;
                }
                else if ([item hasTags:tagTreeItemReadOnly]) {
                    allow = NO;
                }
            }
            // actions that require one folder with Right access
            else if (theAction == @selector(toolbarNewFolder:) ||
                     theAction == @selector(contextualNewFolder:)) {
                if ([item itemType] != ItemTypeBranch) {
                    allow = NO;
                }
                else if ([item hasTags:tagTreeItemReadOnly]) {
                    allow = NO;
                }
                else if ([itemsSelected count]!=1) {
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
            else
                allow = NO; // Deny all other unknown cases

            if (!allow) // Stop if a not allow is found
                break;
        }
    }
    //NSLog(@"%ld  %hhd", (long)[anItem tag], allow);
    return allow; //[super validateUserInterfaceItem:anItem];
}

#pragma mark - Parent Protocol

- (void)focusOnNextView:(id)sender {
    if (sender == myLeftView) {
        if (applicationMode == ApplicationMode2Views) {
            [myRightView focusOnFirstView];
        }
        else {
            [myLeftView focusOnFirstView];
        }
    }
    else if (sender == myRightView) {
        [myLeftView focusOnFirstView];
    }
}

- (void) focusOnPreviousView:(id)sender {
    if (sender == myLeftView) {
        if (applicationMode == ApplicationMode2Views) {
            [myRightView focusOnLastView];
        }
        else {
            [myLeftView focusOnLastView];
        }
    }
    else if (sender == myRightView) {
        [myLeftView  focusOnLastView];
    }
}



#pragma mark - Operations Handling
/* Called for the notificationDoFileOperation notification 
 This routine is called by the views to initiate opeations, such as 
 the case of the edit of the file name or the drag/drop operations */
-(void) startOperationHandler: (NSNotification*) note {

    NSString *operation = [[note userInfo] objectForKey:kDFOOperationKey];
    if ([operation isEqualToString:opOpenOperation]) {
        NSArray *receivedItems = [[note userInfo] objectForKey:kDFOFilesKey];
        BOOL oneFolder=YES;
        for (TreeItem *node in receivedItems) {
            /* Do something here */
            if ([node isKindOfClass: [TreeLeaf class]]) { // It is a file : Open the File
                [node openFile]; // TODO:!!! Register this folder as one of the MRU
            }
            else if ([node isKindOfClass: [TreeBranch class]] && oneFolder==YES) { // It is a directory
                // Going to open the Select That directory on the Outline View
                /* This also sets the node for Table Display and path bar */
                [(BrowserController*)self.selectedView selectFolderByItem:node];
                oneFolder = NO; /* Only one Folder can be Opened */
            }
            else
                NSLog(@"BrowserController.TableDoubleClickEvent: - Unknown Class '%@'", [node className]);

        }
    }
    else if (([operation isEqualToString:opCopyOperation]) ||
        ([operation isEqualToString:opMoveOperation]) ||
        ([operation isEqualToString:opNewFolder])||
        ([operation isEqualToString:opRename])) {
        // Redirects all to file operation
        putInQueue([note userInfo]);

        // Presently this only starts the Busy indications on the statusBar.
        [self _startOperationBusyIndication];
    }
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
        //NSLog(@"operation Status Updating after a stop");
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

- (void) mainThread_operationFinished:(NSNotification*)theNotification {
    if ([operationsQueue operationCount] == 0) {
        [self _stopOperationBusyIndication];

        if (isApplicationTerminating == YES) {
            if ([pendingOperationErrors count]==0) {
                if (isWindowClosing) {
                    [_myWindow close];
                    isWindowClosing = NO;
                }
                else {
                    [NSApp replyToApplicationShouldTerminate:YES];
                    // liberate resources
                    [appTreeManager stopAccesses];
                }
            }
        }

        // Make Status Update here
        NSString *statusText=nil;

        NSDictionary *info = [theNotification userInfo];
        NSUInteger num_files = [[info objectForKey:kDFOFilesKey] count];
        NSString *operation = [info objectForKey:kDFOOperationKey];
        BOOL OK = [[info objectForKey:kDFOOkKey] boolValue];

        if ([operation isEqualToString:opCopyOperation]) {
            if (OK)
                statusText  = [NSString stringWithFormat:@"%lu Files copied",
                           num_files];
            else
                statusText = @"Copy Failed";

        }
        else if ([operation isEqualToString:opMoveOperation]) {
            if (OK)
                statusText  = [NSString stringWithFormat:@"%lu Files moved",
                           num_files];
            else
                statusText = @"Move Failed";
        }
        else if ([operation isEqualToString:opSendRecycleBinOperation] ||
                 [operation isEqualToString:opEraseOperation]) {
            if (OK)
                statusText  = [NSString stringWithFormat:@"%lu Files deleted",
                               num_files];
            else
                statusText = @"Delete Failed";

        }
        else if ([operation isEqualToString:opRename]) {
            if (!OK) {
                statusText = @"Rename Failed";

                // Since the rename actually didn't activate the FSEvents, have to update the view
                // Reload the items in the Selected View
                for (id item in [info objectForKey:kDFOFilesKey]) {
                    [(BrowserController*)_selectedView reloadItem:item];
                 }
            }
        }
        else if ([operation isEqualToString:opNewFolder]) {
            if (!OK) {
                statusText = @"New Folder creation failed";

                // Removing the inserted item
                for (TreeItem* item in [info objectForKey:kDFOFilesKey]) {
                    [item removeItem];
                }

                // Inform User
                NSAlert *alert = [NSAlert alertWithMessageText:@"Error creating Folder"
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"Possible Causes:\nFile already exists or write is restricted"];
                [alert beginSheetModalForWindow:[self myWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
            }
        }
        else {
            assert(NO); // Unknown operation
        }

        if (!OK) {
            // refreshes the view to clear any errors, such as in the new Folder or failed drop
            TreeBranch *dest = [info objectForKey:kDFODestinationKey];
            [dest setTag:tagTreeItemDirty];
            [dest refreshContentsOnQueue:operationsQueue];
        }
        else {
            // TODO:!! MRU Option that only includes directories where operations have hapened.
            // Register the folder in a list of last *used* locations

        }

        if (statusText!=nil) // If nothing was set, don't update status
            [_StatusBar setTitle: statusText];

    }
}

- (void) anyThread_operationFinished:(NSNotification*) theNotification {
    // update our table view on the main thread
    [self performSelectorOnMainThread:@selector(mainThread_operationFinished:) withObject:theNotification waitUntilDone:NO];

}

-(void) updateStatus:(NSDictionary *)status {
    NSLog(@"Status Update missing");
}

- (void) statusUpdate:(NSNotification*)theNotification {
    static NSUInteger dupShow = 0;
    NSString *statusText;
    id selView = [theNotification object];
    // Updates the window Title
    NSArray *titleComponents = [NSArray arrayWithObjects:@"Caravelle",
                                [myLeftView title],
                                [myRightView title], nil];
    NSString *windowTitle = [titleComponents componentsJoinedByString:@" - "];
    [[self myWindow] setTitle:windowTitle];

    //if ([selView isKindOfClass:[BrowserController class]]) {

    NSArray *selectedFiles = [selView getSelectedItems];

    if (selectedFiles != nil) {
        NSInteger num_files=0;
        NSInteger files_size=0;
        NSInteger folders_size=0;
        NSInteger num_directories=0;
        if (applicationMode==ApplicationModeDuplicate && selView==myLeftView) {
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
            statusText = [NSString stringWithFormat:@"No Files Selected"];
        }
        else if ([selectedFiles count] == 1) {
            TreeItem *item = [selectedFiles objectAtIndex:0];
            NSString *sizeText;
            NSString *type;
            if ([item itemType] == ItemTypeLeaf) {
                type = @"File";
                sizeText = [NSString stringWithFormat: @" Size:%@",[NSByteCountFormatter stringFromByteCount:[item filesize] countStyle:NSByteCountFormatterCountStyleFile]];
            }
            else {
                // TODO:!! Check if Folder Size is valid, make change also in the condition below
                type = @"Folder";
                sizeText = @"";
            }

            statusText = [NSString stringWithFormat:@"%@ (%@%@)", [item name], type, sizeText];
        }
        else {
            for (TreeItem *item in selectedFiles ) {
                if ([item itemType] == ItemTypeLeaf) {
                    num_files++;
                    files_size += [(TreeLeaf*)item filesize];
                }
                else if ([item itemType] == ItemTypeBranch) {
                    num_directories++;
                    folders_size += [(TreeBranch*)item filesize];
                }
            }

            NSString *sizeText = [NSByteCountFormatter stringFromByteCount:files_size countStyle:NSByteCountFormatterCountStyleFile];

            NSString *dir_info, *file_info;
            if (num_directories==0)
                dir_info = @"";
            else if (num_directories == 1)
                dir_info = @"1 Folder selected. ";
            else
                dir_info = [NSString stringWithFormat:@"%lu Folders selected. ", num_directories];

            if (num_files==0)
                file_info = @"";
            else if (num_files == 1)
                file_info = [NSString stringWithFormat:@"1 File selected (File Size:%@).", sizeText];
            else
                file_info = [NSString stringWithFormat:@"%lu Files selected (File Total:%@).", num_files, sizeText];

            statusText = [NSString stringWithFormat:@"%@%@", dir_info, file_info];

        }
        [_StatusBar setTitle: statusText];
    }
    else {
        [_StatusBar setTitle: @"Ooops! Received Notification without User Info"];
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
    [myLeftView setViewMode:BViewDuplicateMode];
    [myLeftView setViewType:BViewTypeTable];
    [myRightView setViewMode:BViewDuplicateMode];
    [myRightView setViewType:BViewTypeTable];
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
    self->applicationMode = ApplicationModeDuplicate;
    TreeRoot *rootDir = [TreeRoot treeWithFileCollection:duplicates];
    [myLeftView addTreeRoot:rootDir];
    [myLeftView stopBusyAnimations];
    [myLeftView selectFolderByItem: rootDir];

    [myRightView addTreeRoot:rootDir];
    [myRightView stopBusyAnimations];
    [myRightView selectFolderByItem:rootDir];

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

    if (pendingOperationErrors==nil || [pendingOperationErrors count]==0)
        return;

    if (theNotification!=nil) { // It cames from the window closing
        NSArray *note = pendingOperationErrors[0]; // Fifo Like structure
        NSURL* sourceURL = note[0];
        NSURL* destinationURL = note[1];
        NSError *error = note[2];
        NSString *operation = [[[error userInfo] objectForKey:@"NSUserStringVariant"] firstObject];

        NSDictionary *info = [theNotification userInfo];
        NSString *new_name = [info objectForKey:kFileExistsNewFilenameKey];
        // Lauch the new Operation based on the user choice
        fileExistsQuestionResult answer = [[info objectForKey:kFileExistsAnswerKey] integerValue];
        switch (answer) {
            case FileExistsRename:
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

                // TODO: !!!! Put this in the operations
                [[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:destinationURL] completionHandler:^(NSDictionary *newURLs, NSError *error) {
                    if (error==nil) {
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
        NSArray *note = pendingOperationErrors[0]; // Fifo Like structure
        NSURL* sourceURL = note[0];
        NSURL* destinationURL = note[1];
        NSError *error = note[2];
        //NSString *operation = [[[error userInfo] objectForKey:@"NSUserStringVariant"] firstObject];

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
                if (OK) {
                    [fileExistsWindow displayWindow:self];
                }
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
            NSLog(@"AppDelegate.processNext:Error: Error not processed %@", error); // Don't comment this, before all tests are completed.
        }

    }
    else {
        // The window needs to be closed
        [fileExistsWindow closeWindow];

        // If there was a request for terminating the application
        if (isApplicationTerminating == YES) {
            // and if all is done and clean.
            if ([[operationsQueue operations] count]==0) {
                if (isWindowClosing) {
                    [_myWindow close];
                    isWindowClosing = NO;
                }
                else {
                    [NSApp replyToApplicationShouldTerminate:YES];
                    // liberate resources
                    [appTreeManager stopAccesses];
                }
            }
        }
        //fileExistsWindow = nil;
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
    else if ([pendingOperationErrors count] > 1) {
        // Focus on the Window
        [fileExistsWindow displayWindow:self];
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
    NSLog(@"AppDelegate.fileManager:shouldProceedAfterError:copyingItemAtPath:toPath");
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    NSLog(@"AppDelegate.fileManager:shouldProceedAfterError:movingItemAtPath:toPath");
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error removingItemAtPath:(NSString *)path {
    NSLog(@"AppDelegate.fileManager:shouldProceedAfterError:removingItemAtPath:toPath");
    return NO;
}
- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error removingItemAtURL:(NSURL *)URL {
    NSLog(@"AppDelegate.fileManager:shouldProceedAfterError:removingItemAtURL:toPath");
    return NO;
}


@end
