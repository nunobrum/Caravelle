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
#import "TreePackage.h"
#import "TreeManager.h"
#import "TreeRoot.h"
#import "searchTree.h"
#import "FileOperation.h"
#import "DuplicateFindOperation.h"
#import "ExpandFolders.h"

#import "FileExistsChoice.h"

#import "DuplicateFindSettingsViewController.h"
#import "UserPreferencesDialog.h"
#import "RenameFileDialog.h"
#import "PasteboardUtils.h"

#import "StartupScreenController.h"
#import "DuplicateModeStartWindow.h"

// TODO:! Virtual Folders
// #import "filterBranch.h"
// #import "CatalogBranch.h"
#import "myValueTransformers.h"

NSString *notificationStatusUpdate=@"StatusUpdateNotification";


//NSString *notificationCatalystRootUpdate=@"RootUpdate";
NSString *catalystRootUpdateNotificationPath=@"RootUpdatePath";


NSString *notificationDoFileOperation = @"DoOperation";
NSString *kDFOOperationKey =@"OperationKey";
NSString *kDFODestinationKey =@"DestinationKey";
NSString *kDFORenameFileKey = @"RenameKey";
NSString *kNewFolderKey = @"NewFolderKey";
NSString *kDFOFilesKey=@"FilesSelected";
NSString *kDFOErrorKey =@"ErrorKey";
NSString *kDFOOkKey = @"OKKey";
NSString *kDFOOkCountKey = @"OkCountKey";
NSString *kDFOStatusCountKey = @"StatusCountKey";
NSString *kDFOFromViewKey = @"FromObjectKey";

#ifdef USE_UTI
const CFStringRef kTreeItemDropUTI=CFSTR("com.cascode.treeitemdragndrop");
#endif

NSString const *opOpenOperation=@"OpenOperation";
NSString const *opCopyOperation=@"CopyOperation";
NSString const *opMoveOperation =@"MoveOperation";
NSString const *opReplaceOperation = @"ReplaceOperation";
NSString const *opEraseOperation =@"EraseOperation";
NSString const *opSendRecycleBinOperation = @"SendRecycleBin";
NSString const *opNewFolder = @"NewFolderOperation";
NSString const *opRename = @"RenameOperation";
NSString const *opDuplicateFind = @"DuplicateFindOperation";
NSString const *opFlatOperation = @"com.cascode.op.flat";

NSFileManager *appFileManager;
NSOperationQueue *operationsQueue;         // queue of NSOperations (1 for parsing file system, 2+ for loading image files)
NSOperationQueue *browserQueue;    // Queue for directory viewing (High Priority)
NSOperationQueue *lowPriorityQueue; // Queue for size calculation (Low Priority)
EnumApplicationMode applicationMode;

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

BOOL toggleMenuState(NSMenuItem *menui) {
    NSInteger st = [menui state];
    if (st == NSOnState)
        st = NSOffState;
    else
        st = NSOnState;
    [menui setState:st];
    return st == NSOnState;
}

@interface AppDelegate (Privates)

- (void)  refreshAllViews:(NSNotification*)theNotification;
- (void)     statusUpdate:(NSNotification*)theNotification;
- (void)       rootUpdate:(NSNotification*)theNotification;
- (void) processNextError:(NSNotification*)theNotification;
- (id<MYViewProtocol>)   selectedView;
@end

@implementation AppDelegate {
    NSTimer	*_operationInfoTimer;                  // update timer for progress indicator
    NSNumber *treeUpdateOperationID;
    DuplicateModeStartWindow *duplicateStartupScreenCtrl; // Duplicates Dialog
    DuplicateFindSettingsViewController *duplicateSettingsWindow;
    UserPreferencesDialog *userPreferenceWindow;
    RenameFileDialog *renameFilePanel;
    FileExistsChoice *fileExistsWindow;
    NSMutableArray *pendingOperationErrors;
    NSMutableArray *pendingStatusMessages;
    BOOL isCutPending;
    BOOL isApplicationTerminating;
    BOOL isWindowClosing;
    NSInteger generalPasteBoardChangeCount;
    NSInteger statusTimeoutCounter;
    NSInteger statusFilesMoved,statusFilesCopied,statusFilesDeleted;
    // Duplicate Support
    FileCollection *duplicates;
    TreeRoot *selectedDuplicatesRoot;
}

// -------------------------------------------------------------------------------
//	init
// -------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
	if (self)
    {
        self->duplicateSettingsWindow = nil;
        self->duplicateStartupScreenCtrl = nil;
        self->userPreferenceWindow = nil;
        self->renameFilePanel = nil;
        self->fileExistsWindow = nil;
        
        operationsQueue   = [[NSOperationQueue alloc] init];
        browserQueue      = [[NSOperationQueue alloc] init];
        lowPriorityQueue  = [[NSOperationQueue alloc] init];

        // Browser Queue
        // We limit the concurrency to see things easier for demo purposes. The default value NSOperationQueueDefaultMaxConcurrentOperationCount will yield better results, as it will create more threads, as appropriate for your processor
        [browserQueue setMaxConcurrentOperationCount:2];
        // Use the myPathPopDownMenu outlet to get the maximum tag number
        // Now its fixed to a 7 as a constant see maxItemsInBrowserPopMenu
        
        [lowPriorityQueue setMaxConcurrentOperationCount:1];


        appFileManager = [[NSFileManager alloc] init];
        appTreeManager = [[TreeManager alloc] init];
        [appFileManager setDelegate:self];
        /* Registering Transformers */
        DateToStringTransformer *date_transformer = [[DateToStringTransformer alloc] init];
        [NSValueTransformer setValueTransformer:date_transformer forName:@"date"];
        SizeToStringTransformer *size_transformer = [[SizeToStringTransformer alloc] init];
        [NSValueTransformer setValueTransformer:size_transformer forName:@"size"];
        IntegerToStringTransformer *integer_transformer = [[IntegerToStringTransformer alloc] init];
        [NSValueTransformer setValueTransformer:integer_transformer forName:@"integer"];
        
        isCutPending = NO; // used for the Cut to Clipboard operations.
        isApplicationTerminating = NO; // to inform that the application should quit after all processes are finished.
        isWindowClosing = NO;
        //FSMonitorThread = [[FileSystemMonitoring alloc] init];

	}
	return self;
}

#pragma mark auxiliary functions

-(void) prepareView:(id<MYViewProtocol>) view withItem:(TreeBranch*)item {
    [(BrowserController*)view removeAll];
    [(BrowserController*)view setViewMode:BViewBrowserMode ];
    [(BrowserController*)view setViewType:BViewTypeVoid];
    
    [(BrowserController*)view loadPreferences];
    [(BrowserController*)view setFlatView:NO];
    
    [(BrowserController*)view addTreeRoot: item];
    [(BrowserController*)view selectFirstRoot]; // This calls a refresh
    //[(BrowserController*)view refresh];
    
}

-(void) goHome:(id<MYViewProtocol>) view {
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
                [self prepareView:view withItem:item];
                return;
            }
            else {
                NSLog(@"AppDelegate.goHome: No authorization to access: %@", homepath);
            }
        }
        else {
            NSLog(@"AppDelegate.goHome:Failed to retrieve home folder from NSUserDefaults");
        }
        // TODO:An possible workaround this is just using the first Bookmark available
        
        [self executeOpenFolderInView:view withTitle:@"Select a Folder to Browse"];
        [self savePreferences];

#else
        if (homepath == nil || [homepath isEqualToString:@""]) {
            NSLog(@"Failed to retrieve home folder from NSUserDefaults. Using Home Directory");
            homepath = NSHomeDirectory();
        }

        url = [NSURL fileURLWithPath:homepath isDirectory:YES];
        id item = [(TreeManager*)appTreeManager addTreeItemWithURL:url];
        [self prepareView:view withItem:item];
#endif
    }
}

-(id<MYViewProtocol>) selectedView {
    return _selectedView;
}

-(id) contextualFocus {
    return self->_contextualFocus;
}

-(BOOL) savePreferences {
    NSLog(@"AppDelegate.savePreferences:");
    if (applicationMode != ApplicationModeDuplicate) {
        NSString *homepath = [[myLeftView treeNodeSelected] path];
        [[NSUserDefaults standardUserDefaults] setObject:homepath forKey:USER_DEF_LEFT_HOME];
    }
    [myLeftView savePreferences];
    if (myRightView) {
        if (applicationMode != ApplicationModeDuplicate) {
            NSString *homepath = [[myRightView treeNodeSelected] path];
            [[NSUserDefaults standardUserDefaults] setObject:homepath forKey:USER_DEF_RIGHT_HOME];
        }
        [myRightView savePreferences];
    }
    BOOL OK = [[NSUserDefaults standardUserDefaults] synchronize];
    if (!OK)
        NSLog(@"AppDelegate.savePreferences: Failed to store User Defaults");
    return OK;
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
	//[center addObserver:self selector:@selector(anyThread_handleTreeConstructor:) name:notificationTreeConstructionFinished object:nil];
    [center addObserver:self selector:@selector(startOperationHandler:) name:notificationDoFileOperation object:nil];
    [center addObserver:self selector:@selector(processNextError:) name:notificationClosedFileExistsWindow object:nil];
    [center addObserver:self selector:@selector(startDuplicateFind:) name:notificationStartDuplicateFind object:nil];
    [center addObserver:self selector:@selector(anyThread_handleDuplicateFinish:) name:notificationDuplicateFindFinish object:nil];

    [center addObserver:self selector:@selector(anyThread_operationFinished:) name:notificationFinishedOperation object:nil];

    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:nil];

    //[center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:nil];

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

    // Configuring the FunctionBar according to User Defaults
    BOOL displayFunctionBar = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_APP_DISPLAY_FUNCTION_BAR];
    [self.toolbarFunctionBarSelect setSelected:displayFunctionBar forSegment:0];
    [self toolbarToggleFunctionKeys:self.toolbarFunctionBarSelect];
    
    
    // TODO:!!! Implement the modes preview and Sync
    if (applicationMode == ApplicationModeDuplicate ||
        applicationMode == ApplicationModeSync ||
        applicationMode == ApplicationModePreview) {
        // For now just defaults to one Pane Mode
        applicationMode = ApplicationMode1View;
        [self.toolbarAppModeSelect setSelected:YES forSegment:ApplicationMode1View];
    }

    if (applicationMode == ApplicationMode2Views) {
        myRightView = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
        [myRightView setParentController:self];

        [myLeftView  setName:@"Left"  TwinName:@"Right"];  // A first call not valid, because its called before the add view
        [myRightView setName:@"Right" TwinName:@"Left"];
        [_ContentSplitView addSubview:myLeftView.view];
        [_ContentSplitView addSubview:myRightView.view];
    }
    else if (applicationMode == ApplicationMode1View) {
        myRightView = nil;
        [myLeftView setName:@"Single" TwinName:nil]; // setting to nil causes the cross operations menu's to be disabled
        [_ContentSplitView addSubview:myLeftView.view];
    }
    else {
        NSAssert(NO,@"Application start mode not supported");
    }
    
    // Displaying Startup Screen
    if ([[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_DONT_START_SCREEN]==NO) {
        StartupScreenController *startupScreenCtrl = [[StartupScreenController alloc] initWithWindowNibName:@"StartupScreen"];
        NSInteger dont = [NSApp runModalForWindow:startupScreenCtrl.window];
        if (dont == 1) { // Doesn't display the message again
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEF_DONT_START_SCREEN];
        }
        //[startupScreenCtrl showWindow:self];
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
    [self adjustSideInformation:myLeftView];

    

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
            [self _startOperationBusyIndication:taskInfo];
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
        [self savePreferences];
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
                if (!fromWindowClosing) {
                    if (fileExistsWindow) {
                        [fileExistsWindow displayWindow:self];
                    }
                    else {
                        [self processNextError:nil];
                    }
                }
                return NSTerminateCancel;
            }

            // only displayed if message is comming from window closing
            else if (reponse == NSAlertThirdButtonReturn) {
                if (fileExistsWindow) {
                    [fileExistsWindow displayWindow:self];
                }
                else {
                    [self processNextError:nil];
                }
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
    NSLog(@"Application Will Terminate");
}*/

//When the app is deactivated
-(void) applicationWillResignActive:(NSNotification *)aNotification {
    //NSLog(@"Application Will Resign Active");

    // Force a store of the User Defaults
    [self savePreferences];
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
    NSArray *selectedFiles = [[self selectedView] getSelectedItems];
    return writeItemsToPasteboard(selectedFiles, pboard, types);
}

#pragma mark - NSMenuDelegate

- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu
                    forEvent:(NSEvent *)event
                      target:(id *)target
                      action:(SEL *)action {
    *action = (SEL)NULL;
    if ([event modifierFlags] & NSFunctionKeyMask) {
        NSString *theArrow = [event charactersIgnoringModifiers];
        unichar keyChar = 0;
        if ( [theArrow length] == 1 ) {
            keyChar = [theArrow characterAtIndex:0];
            if ( keyChar == NSF1FunctionKey )
                *action = @selector(toolbarInformation:);
            else if ( keyChar == NSF2FunctionKey )
                *action = @selector(toolbarRename:);
            //else if ( keyChar == NSF3FunctionKey )
            //    *action = @selector(toolbarRename:);
            else if ( keyChar == NSF4FunctionKey )
                *action = @selector(toolbarOpen:);
            else if ( keyChar == NSF5FunctionKey )
                *action = @selector(toolbarCopyTo:);
            else if ( keyChar == NSF6FunctionKey )
                *action = @selector(toolbarMoveTo:);
            else if ( keyChar == NSF7FunctionKey )
                *action = @selector(toolbarNewFolder:);
            else if ( keyChar == NSF8FunctionKey )
                *action = @selector(toolbarDelete:);
            //else if ( keyChar == NSF9FunctionKey )
            //    *action = @selector(toolbarD:);
            //else if ( keyChar == NSF10FunctionKey )
            //    *action = @selector(toolbarInformation:);
            else
                *action = (SEL)NULL;
        }
    }
    if (*action!=(SEL)NULL) {
        *target = self;
        return YES;
    }
    else
        return NO;
}
/*
-(void) setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:USER_DEF_SEE_HIDDEN_FILES]) {
        if ([value isKindOfClass:[NSNumber class]])
        [[NSUserDefaults standardUserDefaults] setBool:[value integerValue]==1 forKey:USER_DEF_SEE_HIDDEN_FILES];
    }
    else
        [super setValue:value forKey:key];
}

- (id) valueForKey:(NSString *)key {
    if ([key isEqualToString:USER_DEF_SEE_HIDDEN_FILES]) {
        BOOL b=[[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_SEE_HIDDEN_FILES];
        NSInteger i;
        if (b)
            i = 1;
        else
            i = 0;
        return [NSNumber numberWithInteger:i];
    }
    return [super valueForKey:key];
}
*/



#pragma mark - Notifications

/* Received when a complete refresh of views is needed */

-(void) refreshAllViews:(NSNotification*) theNotification {
    [(id<MYViewProtocol>)myLeftView refresh];
    if (myRightView!=nil) {
        [(id<MYViewProtocol>)myRightView refresh];
    }
}

/* Receives the notification from the BrowserView to reload the Tree */

//TODO: Marked for clean-up. Revise this code. Only used in notificationCatalystRootUpdate.
//- (void) rootUpdate:(NSNotification*)theNotification {
//    NSDictionary *notifInfo = [theNotification userInfo];
//    BrowserController *BrowserView = [theNotification object];
//    /* In a normal mode the Browser only has one Root */
//    [BrowserView removeRootWithIndex:0];
//
//    /* Add the Job to the Queue */
//	//[queue cancelAllOperations];
//
//	// start the GetPathsOperation with the root path to start the search
//	TreeScanOperation *treeScanOp = [[TreeScanOperation alloc] initWithInfo:notifInfo];
//    treeUpdateOperationID = [treeScanOp operationID];
//	[operationsQueue addOperation:treeScanOp];	// this will start the "GetPathsOperation"
//    [self _startOperationBusyIndication: notifInfo];
//
//}

//- (void)mainThread_handleTreeConstructor:(NSNotification *)note
//{
//    // Pending NSNotifications can possibly back up while waiting to be executed,
//	// and if the user stops the queue, we may have left-over pending
//	// notifications to process.
//	//
//	// So make sure we have "active" running NSOperations in the queue
//	// if we are to continuously add found image files to the table view.
//	// Otherwise, we let any remaining notifications drain out.
//	//
//	NSDictionary *notifData = [note userInfo];
//
//    NSNumber *loadScanCountNum = [notifData valueForKey:kOperationCountKey];
//
//    // make sure the current scan matches the scan of our loaded image
//    if (treeUpdateOperationID == loadScanCountNum)
//    {
//        TreeRoot *receivedTree = [notifData valueForKey:kTreeRootKey];
//        BrowserController *BView =[notifData valueForKey: kSenderKey];
//        id sender = [note object];
//        assert(BView!=sender); // check if the kSenderKey can't be deleted
//        [BView addTreeRoot:receivedTree];
//        [BView stopBusyAnimations];
//        [BView selectFolderByItem: receivedTree];
//        // set the number of images found indicator string
//        [_StatusBar setTitle:@"Updated"];
//    }
//}

// -------------------------------------------------------------------------------
//	anyThread_handleLoadedImages:note
//
//	This method is called from any possible thread (any NSOperation) used to
//	update our table view and its data source.
//
//	The notification contains the NSDictionary containing the image file's info
//	to add to the table view.
// -------------------------------------------------------------------------------
//- (void)anyThread_handleTreeConstructor:(NSNotification *)note
//{
//	// update our table view on the main thread
//	[self performSelectorOnMainThread:@selector(mainThread_handleTreeConstructor:) withObject:note waitUntilDone:NO];
//}



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
        
        NSArray * fileList = [selectedFiles valueForKeyPath:@"@unionOfObjects.path"];

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
        if (1) { // Rename done in place // TODO: Put this is a USer Configuration
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
                [self startFileOperation: taskinfo];
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

-(BOOL) startFileOperation:(NSDictionary *) operationInfo {
    [self _startOperationBusyIndication: operationInfo];
    // TODO:FILOP Divide the operations per classes
    FileOperation *operation = [[FileOperation alloc] initWithInfo:operationInfo];
    putInQueue(operation);
    return YES;
}

-(void) copyItems:(NSArray*)files toBranch:(TreeBranch*)target {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opCopyOperation, kDFOOperationKey,
                              files, kDFOFilesKey,
                              target, kDFODestinationKey,
                              nil];
    [self startFileOperation:taskinfo];
}

-(void) moveItems:(NSArray*)files toBranch:(TreeBranch*)target {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opMoveOperation, kDFOOperationKey,
                              files, kDFOFilesKey,
                              target, kDFODestinationKey,
                              nil];
    [self startFileOperation:taskinfo];
}

-(void) executeCopyTo:(NSArray*) selectedFiles {
    if ([self selectedView] == myLeftView) {
        [self copyItems:selectedFiles toBranch: [myRightView treeNodeSelected]];
    }
    else if ([self selectedView] == myRightView) {
        [self copyItems:selectedFiles toBranch: [myLeftView treeNodeSelected]];
    }
}

-(void) executeMoveTo:(NSArray*) selectedFiles {
    if ([self selectedView] == myLeftView) {
        [self moveItems:selectedFiles toBranch: [myRightView treeNodeSelected]];
    }
    else if ([self selectedView] == myRightView) {
        [self moveItems:selectedFiles toBranch: [myLeftView treeNodeSelected]];
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
    [[self selectedView] refresh]; // Can be replaced with KVO observed->reloadItem
    [self executeCopy:selectedFiles onlyNames:NO];
    isCutPending = YES; // This instruction has to be always made after the executeCopy
}


- (void)executeCopy:(NSArray*) selectedFiles onlyNames:(BOOL)onlyNames {


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
        NSArray* str_representation = [selectedFiles valueForKeyPath:@"@unionOfObjects.name"];
        // Join the paths, one name per line
        NSString* pathPerLine = [str_representation componentsJoinedByString:@"\n"];
        //Now add the pathsPerLine as a string
        [clipboard setString:pathPerLine forType:NSStringPboardType];
    }
    // if only names are copied, the urls are not
    else {
        NSArray* urls  = [selectedFiles valueForKeyPath:@"@unionOfObjects.url"];
        [clipboard writeObjects:urls];
    }

    // Store the Pasteboard counter for later to check ownership
    generalPasteBoardChangeCount = [clipboard changeCount];
    isCutPending = NO;

    NSUInteger count = [selectedFiles count];
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
                [self moveItems:files toBranch: destinationBranch];
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
            [self copyItems:files toBranch: destinationBranch];
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
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opSendRecycleBinOperation, kDFOOperationKey,
                              selectedFiles, kDFOFilesKey,
                              nil];
    [self startFileOperation:taskinfo];
}


#pragma mark Action Outlets


- (void) updateFocus:(id)sender {
    if (sender == myLeftView || sender == myRightView) {
        if (_selectedView != sender) {
            _selectedView = sender;
            [self adjustSideInformation:sender];
        }
    }
    else {
        NSLog(@"AppDelegate.updateSelected: - Case not expected. Unknown View");
        assert(false);
    }
}

- (void) contextualFocus:(id)sender {
    if (sender == myLeftView || sender == myRightView) {
        _contextualFocus = sender;
    }
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
    [self executeInformation: [[self contextualFocus] getSelectedItemsForContextualMenu1]];
}

- (IBAction)toolbarRename:(id)sender {
    [self executeRename:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualRename:(id)sender {
    [self executeRename:[[self contextualFocus] getSelectedItemsForContextualMenu2]];
}

- (IBAction)toolbarDelete:(id)sender {
    [self executeDelete:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualDelete:(id)sender {
    [self executeDelete:[[self contextualFocus] getSelectedItemsForContextualMenu2]];
}

- (IBAction)toolbarCopyTo:(id)sender {
    [self executeCopyTo:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualCopyTo:(id)sender {
    [self executeCopyTo:[[self contextualFocus] getSelectedItemsForContextualMenu2]];
}

- (IBAction)toolbarMoveTo:(id)sender {
    [self executeMoveTo:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualMoveTo:(id)sender {
    [self executeMoveTo:[[self contextualFocus] getSelectedItemsForContextualMenu2]];
}

- (IBAction)toolbarOpen:(id)sender {
    [self executeOpen:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualOpen:(id)sender {
    [self executeOpen:[[self contextualFocus] getSelectedItemsForContextualMenu2]];
}

- (IBAction)toolbarNewFolder:(id)sender {
    NSArray *selectedItems = [[self selectedView] getSelectedItems];
    NSInteger selectionCount = [selectedItems count];
    if (selectionCount!=0) {
        // TODO:! Ask whether to move the files into the new created Folder
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

- (IBAction)toolbarToggleFunctionKeys:(id)sender { // TODO: !!!!!! Replace this with bindings to User Defaults
    CGFloat constant;
    BOOL setting = [sender isSelectedForSegment:0];
    if (setting) {
        NSRect newFrame = [self.FunctionBar frame];
        constant = NSHeight(newFrame); // Creates space for the view
        [self.FunctionBar setHidden:NO];
    }
    else {
        constant = 0;
        [self.FunctionBar setHidden:YES];
    }
    [[self SplitViewBottomLineConstraint] setConstant:constant];
    [[self ContentSplitView] setNeedsDisplay:YES];
    // Reposition the value in the user defaults
    [[NSUserDefaults standardUserDefaults] setBool:setting forKey:USER_DEF_APP_DISPLAY_FUNCTION_BAR];
}


- (IBAction)orderPreferencePanel:(id)sender {
    if (userPreferenceWindow==nil)
        userPreferenceWindow =[[UserPreferencesDialog alloc] initWithWindowNibName:@"UserPreferencesDialog"];
    [userPreferenceWindow showWindow:self];

}

- (IBAction)operationCancel:(id)sender {
    NSArray *operations = [operationsQueue operations];
    [(NSOperation*)[operations firstObject] cancel];
    [self.statusProgressLabel setTextColor:[NSColor redColor]];
    [self.statusProgressLabel setStringValue: @"Canceling..."];
}

- (IBAction)cut:(id)sender {
    [self executeCut:[[self selectedView] getSelectedItems]];
}

- (IBAction)contextualCut:(id)sender {
    [self executeCut:[[self contextualFocus] getSelectedItemsForContextualMenu2]];
}

- (IBAction)copy:(id)sender {
    [self executeCopy:[[self selectedView] getSelectedItems] onlyNames:NO];
}

- (IBAction)contextualCopy:(id)sender {
    [self executeCopy:[[self contextualFocus] getSelectedItemsForContextualMenu2] onlyNames:NO];
}

- (IBAction)copyName:(id)sender {
    [self executeCopy:[[self selectedView] getSelectedItems] onlyNames:YES];
}

- (IBAction)contextualCopyName:(id)sender {
    [self executeCopy:[[self contextualFocus] getSelectedItemsForContextualMenu2] onlyNames:YES];
}


- (IBAction)paste:(id)sender {
    TreeBranch *destinationBranch = [[self selectedView] treeNodeSelected];
    [self executePaste:destinationBranch];

}

- (IBAction)contextualPaste:(id)sender {
    // the validateMenuItems insures that node is Branch
    NSArray *items = [[self contextualFocus] getSelectedItemsForContextualMenu1];
    if ([items count]==1) { // Can only paste on one item. TODO: In the future can paste to many
        TreeItem *item = [items firstObject];
        // TODO:!! need to test if its an application,
        //if ([item isKindOfClass:[TreePackage class]]) {
            // and if it is will simply use it to open the items on the clipboard.

        //}
        if ([item itemType]==ItemTypeLeaf) { // If its a leaf, will use the parent instead
            item = [item parent];
        }
        [self executePaste:(TreeBranch*)item];
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

- (IBAction)appModeChanged:(id)sender {
    NSInteger mode = [(NSSegmentedControl*)sender selectedSegment];
    
    if (mode != applicationMode) {
        EnumApplicationMode old_mode = applicationMode;
        applicationMode = mode;
        
        NSUInteger panelCount = [[self.ContentSplitView subviews] count];
        
        // Cancelation of the previous mode of operation
        if (old_mode==ApplicationModeDuplicate) {
            NSArray *roots = [[myLeftView roots] copy]; // Save the roots first
            
            [myLeftView setViewMode:BViewBrowserMode];
            [myRightView setViewMode:BViewBrowserMode];
            [self.toolbarViewTypeSelect setEnabled:YES forSegment:BViewTypeIcon];
            
            if ([roots count]>=1) {
                
                [self prepareView:myLeftView withItem:roots[0]];
                if (myRightView!=nil) {
                    if ([roots count]>=2)
                        [self prepareView:myRightView withItem:roots[1]];
                    else
                        [self goHome:myRightView];
                }
            }
            else {
                [self goHome:myLeftView];
                [self goHome:myRightView];
            }
        }
        
        else if (old_mode == ApplicationModePreview) {
            // TODO:1.4 code here for Application Mode Preview
            // Delete the current preview view
            // and add myRightView
        }
        else if (old_mode == ApplicationModeSync){
            // TODO:1.4 develop this if needed
        }
        
        // Initialization of the new Mode
        if (applicationMode == ApplicationMode1View) {
            if (myRightView!=nil && panelCount == 2) {
                [myRightView.view removeFromSuperview];
                //myRightView.view = nil;
            }
            [myLeftView setName:@"Single" TwinName:nil];
            [myLeftView refresh];  // Needs to force a refresh since the preferences were updated
        }
        else if (applicationMode == ApplicationMode2Views) {
            if (panelCount==1) {
                if (myRightView == nil) {
                    myRightView = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
                    [myRightView setParentController:self];
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
                }
            }
            else {
                
                [myRightView refresh]; // Refreshes just in case
            }
            [myLeftView  setName:@"Left"  TwinName:@"Right"];
            [myRightView setName:@"Right" TwinName:@"Left"];
            
            [myLeftView  refresh];  // Needs to always refresh the left view since preferences may have changed
            [myRightView refresh];
            
        }
        else if (mode == ApplicationModePreview) {
            // TODO:1.4 Preview Mode
            NSLog(@"AppDelegate.appModeChanged: Preview Mode");
            // Now displaying an NSAlert with the information that this will be available in a next version
            NSAlert *notAvailableAlert =  [NSAlert alertWithMessageText:@"Preview Pane"
                                                          defaultButton:@"OK"
                                                        alternateButton:nil
                                                            otherButton:nil
                                              informativeTextWithFormat:@"This feature will be implemented in a future version. For more information consult the Caravelle Roadmap.  www.nunobrum.com/roadmap"];
            [notAvailableAlert setAlertStyle:NSInformationalAlertStyle];
            [notAvailableAlert beginSheetModalForWindow:[self myWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
            // Reposition last mode
            [(NSSegmentedControl*)sender setSelectedSegment:applicationMode];
            
        }
        else if (mode == ApplicationModeSync) {
            // TODO:1.4 Sync Mode
            NSLog(@"AppDelegate.appModeChanged: Sync Mode");// TODO: !!! Preview Mode
            // Now displaying an NSAlert with the information that this will be available in a next version
            NSAlert *notAvailableAlert =  [NSAlert alertWithMessageText:@"Directory Compare & Synchronization"
                                                          defaultButton:@"OK"
                                                        alternateButton:nil
                                                            otherButton:nil
                                              informativeTextWithFormat:@"This feature will be implemented in a future version. For more information consult the Caravelle Roadmap.  www.nunobrum.com/roadmap"];
            [notAvailableAlert setAlertStyle:NSInformationalAlertStyle];
            [notAvailableAlert beginSheetModalForWindow:[self myWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
            // Reposition last mode
            [(NSSegmentedControl*)sender setSelectedSegment:applicationMode];
            
        }
        else if (mode == ApplicationModeDuplicate) {
            [self FindDuplicates:sender];
            return;
        }
    }
    [self adjustSideInformation: self.selectedView];
    [self.ContentSplitView adjustSubviews];
    [self.ContentSplitView displayIfNeeded];
}

- (IBAction)viewTypeChanged:(id)sender {
    if ([self.selectedView isKindOfClass:[BrowserController class]]) {
        NSInteger newType = [(NSSegmentedControl*)sender selectedSegment ];
        [(BrowserController*)self.selectedView setViewType:newType];
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
        theAction == @selector(toolbarGotoFolder:) ||
        theAction == @selector(orderPreferencePanel:) ||
        theAction == @selector(FindDuplicates:)
        ) {
        return YES;
    }

    // Actions that require a contextual selection including the current Node
    if (theAction == @selector(contextualInformation:) ||
        theAction == @selector(contextualNewFolder:) ||
        theAction == @selector(contextualPaste:)
        ) {
        itemsSelected = [(BrowserController*)[self contextualFocus] getSelectedItemsForContextualMenu1];
    }
    // Actions that require a contextual selection excluding the current Node
    else if (theAction == @selector(contextualCut:) ||
             theAction == @selector(contextualDelete:) ||
             theAction == @selector(contextualCopy:) ||
             theAction == @selector(contextualCopyName:) ||
             theAction == @selector(contextualCopyTo:) ||
             theAction == @selector(contextualOpen:) ||
             theAction == @selector(contextualRename:) ||
             theAction == @selector(contextualMoveTo:)
             ) {
        itemsSelected = [(BrowserController*)[self contextualFocus] getSelectedItemsForContextualMenu2];
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
            // Check if paste board has valid data
            NSPasteboard *clipboard = [NSPasteboard generalPasteboard];
            NSArray *files = get_clipboard_files(clipboard);
            if ([files count]==0) {
                allow = NO;
            }
            // No other conditions. This is supposed to be a folder, no need to test this condition
        }
        else if ((applicationMode != ApplicationMode2Views) && (
                 theAction == @selector(contextualCopyTo:) ||
                 theAction == @selector(contextualMoveTo:) ||
                 theAction == @selector(toolbarCopyTo:) ||
                 theAction == @selector(toolbarMoveTo:)
                 )) {
            allow = NO;
        }
        else {
            allow = NO;
        }
    }
    else {
        for (TreeItem *item in itemsSelected) {
            // Actions depending on the application mode
            if ((applicationMode != ApplicationMode2Views) &&
                     (theAction == @selector(contextualCopyTo:) ||
                      theAction == @selector(contextualMoveTo:) ||
                      theAction == @selector(toolbarCopyTo:) ||
                      theAction == @selector(toolbarMoveTo:)
                      )) {
                         allow = NO;
            }
            // Actions that can always be made
            else if (theAction == @selector(contextualCopy:) ||
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
                // Check if paste board has valid data
                NSPasteboard *clipboard = [NSPasteboard generalPasteboard];
                NSArray *files = get_clipboard_files(clipboard);
                if ([files count]==0) {
                    allow = NO;
                }
            }
            // actions that require one folder with Right access
            else if (theAction == @selector(toolbarNewFolder:) ||
                     theAction == @selector(contextualNewFolder:)) {
                if ([item itemType] != ItemTypeBranch) {
                    allow = NO;
                }
//                else if ([item hasTags:tagTreeItemReadOnly]) {
//                    allow = NO;
//                } Commented since the read only is applicable to the folder itself not its contents
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
    //NSLog(@"%s  %hhd", sel_getName(theAction), allow);
    return allow; //[super validateUserInterfaceItem:anItem];
}

#pragma mark - Parent Protocol

- (void)focusOnNextView:(id)sender {
    id<MYViewProtocol> focused_view;
    if (sender == myLeftView) {
        if (applicationMode == ApplicationMode2Views ||
            applicationMode == ApplicationModeSync ||
            applicationMode == ApplicationModeDuplicate) {
            focused_view = myRightView;
        }
        else {
            focused_view = myLeftView;
        }
    }
    else if (sender == myRightView) {
        focused_view = myLeftView;
    }
    [focused_view focusOnFirstView];
    [self adjustSideInformation:focused_view];
}


- (void) focusOnPreviousView:(id)sender {
    id<MYViewProtocol> focused_view;
    if (sender == myLeftView) {
        if (applicationMode == ApplicationMode2Views ||
            applicationMode == ApplicationModeSync ||
            applicationMode == ApplicationModeDuplicate) {
            focused_view = myRightView;
        }
        else {
            focused_view = myLeftView;
        }
    }
    else if (sender == myRightView) {
        focused_view = myLeftView;
    }
    [focused_view focusOnLastView];
    [self adjustSideInformation:focused_view];
}


#pragma mark - Operations Handling
/* Called for the notificationDoFileOperation notification 
 This routine is called by the views to initiate opeations, such as 
 the case of the edit of the file name or the drag/drop operations */
-(void) startOperationHandler: (NSNotification*) note {

    NSString *operation = [[note userInfo] objectForKey:kDFOOperationKey];
    if ([operation isEqualTo:opOpenOperation]) {
        NSArray *receivedItems = [[note userInfo] objectForKey:kDFOFilesKey];
        BOOL oneFolder=YES;
        for (TreeItem *node in receivedItems) {
            /* Do something here */
            if ([node itemType] == ItemTypeLeaf) { // It is a file : Open the File
                [node openFile]; // TODO:!!! Register this folder as one of the MRU
            }
            else if ([node itemType] == ItemTypeBranch && oneFolder==YES) { // It is a directory
                // Going to open the Select That directory on the Outline View
                /* This also sets the node for Table Display and path bar */
                [(BrowserController*)self.selectedView selectFolderByItem:node];
                oneFolder = NO; /* Only one Folder can be Opened */
            }
            else
                NSLog(@"AppDelegate.startOperationHandler: - Unknown Class '%@'", [node className]);

        }
    }
    else if (([operation isEqualTo:opCopyOperation]) ||
        ([operation isEqualTo:opMoveOperation]) ||
        ([operation isEqualTo:opNewFolder])||
        ([operation isEqualTo:opRename])) {
        // Redirects all to file operation
        [self startFileOperation:[note userInfo]];
    }
    else if ([operation isEqualTo:opFlatOperation]) {
        ExpandFolders * op = [[ExpandFolders alloc] initWithInfo:[note userInfo]];
        [op setQueuePriority:NSOperationQueuePriorityNormal];
        [op setThreadPriority:0.25];
        [self _startOperationBusyIndication: [note userInfo]];
        putInQueue(op);
    }
}

-(void) _startOperationBusyIndication:(NSDictionary*) operationInfo {
    // Displays the first status message
    NSString *operationStatus = @"...";
    NSString *operation = [operationInfo objectForKey:kDFOOperationKey];
    NSInteger count = [[operationInfo objectForKey:kDFOFilesKey] count];
    // manage the singular vs plural
    NSString *nItems;
    if (count == 1) {
        nItems = @"1 item";
    }
    else {
        nItems = [NSString stringWithFormat:@"%ld items", (long)count];
    }
    // TODO:FILOP Move this to the File Operations
    if ([operation isEqualTo:opCopyOperation]) {
        operationStatus = [NSString stringWithFormat:@"Copying %@",nItems];
    }
    else if ([operation isEqualTo:opMoveOperation]) {
        operationStatus = [NSString stringWithFormat:@"Moving %@",nItems];
    }
    else if ([operation isEqualTo:opSendRecycleBinOperation]) {
        operationStatus = [NSString stringWithFormat:@"Trashing %@",nItems];
    }
    else if ([operation isEqualTo:opEraseOperation]) {
        operationStatus = [NSString stringWithFormat:@"Erasing %@",nItems];
    }
    else if ([operation isEqualTo:opRename]) {
        operationStatus = [NSString stringWithFormat:@"Renaming %@",nItems];
    }
    else if ([operation isEqualTo:opNewFolder]) {
        operationStatus = @"Adding Folder";
    }
    else if ([operation isEqualTo:opDuplicateFind]) {
        operationStatus = @"Starting Duplicate Find";
    }
    else if ([operation isEqualTo:opFlatOperation]) {
        operationStatus = @"Flattening Folder";
    }
    else {
        operationStatus = @"Unknown Operation";
    }
    //NSLog(operationStatus);
    [self.statusProgressIndicator setHidden:NO];
    [self.statusProgressIndicator startAnimation:self];
    [self.statusProgressLabel setHidden:NO];
    [self.statusProgressLabel setTextColor:[NSColor blueColor]];
    [self.statusProgressLabel setStringValue: operationStatus];
    [self.statusCancelButton setHidden:NO];
    statusTimeoutCounter = 0;
    statusFilesCopied = 0;
    statusFilesDeleted = 0;
    statusFilesMoved = 0;
    _operationInfoTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_operationsInfoFired:) userInfo:nil repeats:YES];
    
}

- (void)_operationsInfoFired:(NSTimer *)timer {
    if ([operationsQueue operationCount]==0) {

        if ([pendingStatusMessages count]>=1) { // This was called from the notifications finished, and there is only one message pending
            // Make Status Update here
            NSString *statusText=nil;

            NSDictionary *info = [pendingStatusMessages firstObject];
            [pendingStatusMessages removeObjectAtIndex:0];
            //NSUInteger num_files = [[info objectForKey:kDFOFilesKey] count];
            NSString *operation = [info objectForKey:kDFOOperationKey];
            BOOL OK = [[info objectForKey:kDFOOkKey] boolValue];
            // TODO:FILOP The FileOperations should generate their own messages to display here.
            // Its more correct in an object oriented perspective. File Operations should also be subclassed.
            // the main on the File Operations is becomming a big mess
            // Also, make sure that the URL vs TreeItem recovery is done in the FileUtils.
            if ([operation isEqualTo:opCopyOperation]) {
                if (OK)
                    statusText  = [NSString stringWithFormat:@"%lu Files copied",
                                   statusFilesCopied];
                else
                    statusText = @"Copy Failed";

            }
            else if ([operation isEqualTo:opMoveOperation]) {
                if (OK)
                    statusText  = [NSString stringWithFormat:@"%lu Files moved",
                                   statusFilesMoved];
                else
                    statusText = @"Move Failed";
            }
            else if ([operation isEqualTo:opSendRecycleBinOperation]) {
                if (OK)
                    statusText  = [NSString stringWithFormat:@"%@ Files Trashed",
                                   [info objectForKey:kDFOOkCountKey]];
                else
                    statusText = @"Trash Failed";

            }
            else if ([operation isEqualTo:opEraseOperation]) {
                if (OK)
                    statusText  = [NSString stringWithFormat:@"%lu Files Trashed",
                                   statusFilesDeleted];
                else
                    statusText = @"Trash Failed";

            }
            else if ([operation isEqualTo:opRename]) {
                if (!OK) {
                    statusText = @"Rename Failed";
                }
                else {
                    NSInteger count = [[info objectForKey:kDFOOkCountKey] integerValue];
                    statusText  = [NSString stringWithFormat:@"%lu Files renamed", count];
                }
            }
            else if ([operation isEqualTo:opNewFolder]) {
                if (!OK) {
                    statusText = @"New Folder creation failed";
                }
                else
                    statusText = @"Folder Created";
            }
            else if ([operation isEqualTo:opDuplicateFind]) {
                if (!OK)
                    statusText = @"Duplicate Find Aborted";
                else {
                    NSInteger count = [(NSArray*)[info objectForKey:kDuplicateList] count];
                    if (count==0)
                        statusText = @"No Duplicates Found";
                    else
                        statusText = [NSString stringWithFormat:@"%ld Duplicates Found", count];
                }
            }
            else if ([operation isEqualTo:opFlatOperation]) {
                if (!OK)
                    statusText = @"Flat View Aborted";
                else
                    statusText = nil; // Cancel any existing text
            }
            else {
                NSLog(@"Unkown operation"); // Unknown operation
            }

            if (!OK) {
                [self.statusProgressLabel setTextColor:[NSColor redColor]];
            }
            else {
                [self.statusProgressLabel setTextColor:[NSColor textColor]];
            }
            
            if (statusText!=nil)
                [self.statusProgressLabel setStringValue: statusText];
            else {
                // If nothing was set, don't update status
                [self _stopOperationBusyIndication];
                [self.statusProgressLabel setStringValue: @""];
            }
        }
        else {
            // Update nothing, so that the previous message does not stand for less time than expected
        }
        if (statusTimeoutCounter==0) { // first stops the indications
            [self.statusProgressIndicator stopAnimation:self];
        }
        else if (statusTimeoutCounter>=3) { // at 3 seconds it will make the indicators disappear
            [self _stopOperationBusyIndication];
            [timer invalidate];
        }
        if (timer) statusTimeoutCounter++;
    }
    else {
        // Get from Operation the status Text
        NSString *status = @"Internal Error";
        NSArray *operations = [operationsQueue operations];
        NSOperation *currOperation = operations[0];
        if ([currOperation isKindOfClass:[FileOperation class]]) { // TODO:FILOP This should be moved to File Operations statusText Selector
            NSString *op = [[(FileOperation*)currOperation info] objectForKey:kDFOOperationKey];
            
            if ([op isEqualTo:opCopyOperation]) {
                status = [NSString stringWithFormat:@"Copying...%ld", statusFilesCopied];
            }
            else if ([op isEqualTo:opMoveOperation]) {
                status = [NSString stringWithFormat:@"Moving...%ld", statusFilesMoved];
            }
            else if ([op isEqualTo:opSendRecycleBinOperation]) {
                status = [NSString stringWithFormat:@"Trashing...%ld", statusFilesDeleted];
            }
        }
        else if ([currOperation isKindOfClass:[AppOperation class]]) {
            status = [(AppOperation*)currOperation statusText];
        }
        [self.statusProgressLabel setTextColor:[NSColor blueColor]];
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
    [self.statusCancelButton setHidden:YES];
}

- (void) mainThread_operationFinished:(NSNotification*)theNotification {
    NSDictionary *info = [theNotification userInfo];

    // check if alerts or immediate display refreshes are needed
    BOOL OK = [[info objectForKey:kDFOOkKey] boolValue];
    if (!OK) {
        NSString *operation = [info objectForKey:kDFOOperationKey];
        if ([operation isEqualTo:opRename]) {

            // Since the rename actually didn't activate the FSEvents, have to update the view
            // Reload the items in the Selected View
            for (id item in [info objectForKey:kDFOFilesKey]) {
                [(BrowserController*)_selectedView reloadItem:item];
            }
        }
        else if ([operation isEqualTo:opNewFolder]) {
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
        else if ([operation isEqualTo:opFlatOperation]) {
            // Cancel the Flat View
            BrowserController *selView = [info objectForKey:kDFOFromViewKey];
            [selView setFlatView:NO];
            [selView refresh];
        }
        else {
            TreeBranch *dest = [info objectForKey:kDFODestinationKey];
            if (dest) {// a URL arrived here in one of the tests. Placing here an assertion to trap it if it happens again
                NSAssert([dest isKindOfClass:[TreeBranch class]], @"ERROR. Received an object that isn't a TreeBranch");
                [dest setTag:tagTreeItemDirty];
                [dest refreshContents];
            }
        }
    }

    if (pendingStatusMessages==nil)
        pendingStatusMessages = [NSMutableArray arrayWithObject:info];
    else
        [pendingStatusMessages addObject:info];

    [self _operationsInfoFired:nil];

    if ([operationsQueue operationCount] == 0) {
        // Hiddes the cancel button
        [self.statusCancelButton setHidden:YES];
        
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

    }
    [self statusUpdate:nil];
}

- (void) anyThread_operationFinished:(NSNotification*) theNotification {
    // update our table view on the main thread
    [self performSelectorOnMainThread:@selector(mainThread_operationFinished:) withObject:theNotification waitUntilDone:NO];

}

-(void) adjustSideInformation:(id) sender {
    if (applicationMode == ApplicationMode2Views ||
        applicationMode == ApplicationModeSync) {
        [self.buttonCopyTo setEnabled:YES];
        [self.buttonMoveTo setEnabled:YES];
        if (sender == myLeftView) {
            [self.buttonCopyTo setTitle: @"Copy Right"];
            [self.buttonMoveTo setTitle: @"Move Right"];
        }
        else {
            [self.buttonCopyTo setTitle: @"Copy Left"];
            [self.buttonMoveTo setTitle: @"Move Left"];
        }
    }
    else {
        [self.buttonCopyTo setEnabled:NO];
        [self.buttonMoveTo setEnabled:NO];
        [self.buttonCopyTo setTitle: @"Copy"];
        [self.buttonMoveTo setTitle: @"Move"];
    }

    // Update the View Type
    if ([sender isKindOfClass:[BrowserController class]]) {
        EnumBrowserViewType type = [(BrowserController*)sender viewType];
        [self.toolbarViewTypeSelect setSelected:YES forSegment:type];
    }
}

-(void) updateStatus:(NSDictionary *)status {
    NSLog(@"Status Update missing");
}

- (void) statusUpdate:(NSNotification*)theNotification {
    static NSUInteger dupShow = 0;
    NSString *statusText;
    NSString *leftTitle = nil, *rightTitle = nil;
    
    switch (applicationMode) {
        case ApplicationModeSync:
        case ApplicationMode2Views:
            rightTitle = [myRightView title];
        case ApplicationMode1View:
        case ApplicationModePreview:
            leftTitle = [myLeftView title];
            break;
        case ApplicationModeDuplicate:
            leftTitle = @"Duplicate Find";
            break;
        default:
            leftTitle = @"Unknown Mode";
            break;
    }
    
    // Updates the window Title
    NSArray *titleComponents = [NSArray arrayWithObjects:@"Caravelle",
                                leftTitle,
                                rightTitle, nil];
    NSString *windowTitle = [titleComponents componentsJoinedByString:@" - "];
    [[self myWindow] setTitle:windowTitle];
    
    NSArray *selectedFiles;

    //if ([selView isKindOfClass:[BrowserController class]]) {

    if (applicationMode==ApplicationModeDuplicate) {
        id selView = [theNotification object];
        //Check first if the object sending the
        if (selView==nil) { // Sent by Operation Finished
            //Defaults to the LeftView
            selView = myLeftView;
        }
        if (selView==myLeftView || selView ==myLeftView.detailedViewController) {
            selectedFiles = [selView getSelectedItems];
            dupShow++;
            FileCollection *selectedDuplicates = [[FileCollection alloc] init];
            for (TreeItem *item in selectedFiles ) {
                FileCollection *itemDups = [duplicates duplicatesInPath:[item path] dCounter:dupShow];
                [selectedDuplicates concatenateFileCollection: itemDups];
            }
            /* will now populate the Right View with Duplicates*/
            [selectedDuplicatesRoot setFileCollection:selectedDuplicates];
            [myRightView refresh];
        }
    }
    
    selectedFiles = [self.selectedView getSelectedItems];

    if (selectedFiles != nil) {
        NSInteger num_files=0;
        NSInteger files_size=0;
        NSInteger folders_size=0;
        NSInteger num_directories=0;
        
        if ([selectedFiles count]==0) {
            statusText = [NSString stringWithFormat:@"No Files Selected"];
        }
        else if ([selectedFiles count] == 1) {
            TreeItem *item = [selectedFiles objectAtIndex:0];
            long long size = [[item fileSize] longLongValue];
            NSString *sizeText;
            if (size != -1) {
                sizeText = [NSString stringWithFormat: @" Size:%@",[NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile]];
            }
            else {
                sizeText = @"";
            }
            NSString *type;
            ItemType iType = [item itemType];
            if (iType == ItemTypeLeaf) {
                type = @"File";
            }
            else if (iType == ItemTypeBranch){
                type = @"Folder";
            }
            else {
                type = @"";
                sizeText = @"Size Unknown";
            }

            statusText = [NSString stringWithFormat:@"%@ (%@%@)", [item name], type, sizeText];
        }
        else {
            for (TreeItem *item in selectedFiles ) {
                if ([item itemType] == ItemTypeLeaf) {
                    num_files++;
                    files_size += [[(TreeLeaf*)item fileSize] longLongValue];
                }
                else if ([item itemType] == ItemTypeBranch) {
                    num_directories++;
                    folders_size += [[(TreeBranch*)item fileSize] longLongValue];
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
        duplicateSettingsWindow =[[DuplicateFindSettingsViewController alloc] initWithWindowNibName:@"DuplicatesFindSettings"];
    
    // Setting the current node in the list
    NSMutableArray *selectedNodes;
    selectedNodes = [NSMutableArray arrayWithObjects:[[myLeftView treeNodeSelected] url], nil]; // Prefering this form since the url can be nil
    if (applicationMode != ApplicationMode1View) {
        if ([[myLeftView treeNodeSelected] compareTo:[myRightView treeNodeSelected]] == pathsHaveNoRelation)
            [selectedNodes addObject:[[myRightView treeNodeSelected] url]];
    }
    [duplicateSettingsWindow showWindow:self];
    [self->duplicateSettingsWindow setURLs:selectedNodes];
}

/* invoked by Find Duplicates Dialog on OK Button */
- (void) startDuplicateFind:(NSNotification*)theNotification {
    // First check if is not a cancel
    // If there isn't an UserInfo Dictionary then its a cancel
    NSDictionary *notifInfo = [theNotification userInfo];
    if (notifInfo==nil) {
        // Reverts back to the previous view . Nothing is changed
        [self.toolbarAppModeSelect setSelected:YES forSegment:applicationMode];
    }
    else {
        
        if (myRightView!=nil )
            [myRightView startAllBusyAnimations];
        [myLeftView startAllBusyAnimations];
        
        [self.toolbarAppModeSelect setSelected:YES forSegment:ApplicationModeDuplicate];
        
        duplicates = [[FileCollection alloc] init];
        NSDictionary *notifInfo = [theNotification userInfo];
        
        // start the GetPathsOperation with the root path to start the search
        DuplicateFindOperation *dupFindOp = [[DuplicateFindOperation alloc] initWithInfo:notifInfo];
        [operationsQueue addOperation:dupFindOp];	// this will start the "GetPathsOperation"
        [self _startOperationBusyIndication:notifInfo];
        
        // While the process runs, the user can choose what is the prefered way of displaying
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_DONT_START_DUP_SCREEN]==NO) {
            duplicateStartupScreenCtrl = [[DuplicateModeStartWindow alloc] initWithWindowNibName:@"DuplicateModeStartWindow"];
            [duplicateStartupScreenCtrl showWindow:self];
        }
    }
}

-(void) closeDuplicatesStartUpWindow {
    if (self->duplicateStartupScreenCtrl!=nil) {
        [self->duplicateStartupScreenCtrl close];
        self->duplicateStartupScreenCtrl = nil;
    }
}

- (void) mainThread_duplicateFindFinish:(NSNotification*)theNotification {
    BOOL use_classic_view = NO;
    NSDictionary *info = [theNotification userInfo];
    BOOL OK = [[info objectForKey:kDFOOkKey] boolValue];
    NSArray *duplicatedFileArray = [info objectForKey:kDuplicateList];
    // Check if operation was not aborted
    if (!OK || ([duplicatedFileArray count]==0)) {
        // Reverts back to the previous view . Nothing is changed
        [self.toolbarAppModeSelect setSelected:YES forSegment:applicationMode];
        [myLeftView stopBusyAnimations];
        [myRightView stopBusyAnimations];
        
        if (OK) { // The operation was not cancelled.
            // closing the window if it was opened
            if (self->duplicateStartupScreenCtrl!=nil) {
                [self->duplicateStartupScreenCtrl.message setStringValue:@"No duplicate files were found. Auto closing..."];
                [self performSelector:@selector(closeDuplicatesStartUpWindow) withObject:nil afterDelay:3.0];
            }
            else {
                // Display information that no duplicates were found
                NSAlert *alert = [NSAlert alertWithMessageText:@"Congratulations !"
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"No duplicate files were found"];
                [alert setAlertStyle:NSInformationalAlertStyle];
                [alert beginSheetModalForWindow:[self myWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
            }
        }
        else {
            [self closeDuplicatesStartUpWindow];
        }
        return;
    }
    
    // Updating operation Status
    if (pendingStatusMessages==nil)
        pendingStatusMessages = [NSMutableArray array];
    [pendingStatusMessages addObject:info];
    [self _operationsInfoFired:nil];
    
    
    if (self->duplicateStartupScreenCtrl !=  nil) {
        
        if ((self->duplicateStartupScreenCtrl.answer & DupDialogMaskOKPressed) == 0) {
            NSModalSession session = [NSApp beginModalSessionForWindow:self->duplicateStartupScreenCtrl.window];
            for (;;) {
                if ([NSApp runModalSession:session] != NSModalResponseContinue)
                    break;
            }
            [NSApp endModalSession:session];
        }
        use_classic_view = (self->duplicateStartupScreenCtrl.answer & DupDialogMaskClassicView) != 0;
        if (self->duplicateStartupScreenCtrl.answer & DupDialogMaskChkDontDisplayAgain) {
            // Then stores this in the User Defaults
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEF_DONT_START_DUP_SCREEN];
            [[NSUserDefaults standardUserDefaults] setBool:use_classic_view forKey:USER_DEF_DUPLICATE_CLASSIC_VIEW];
            
        }
    }
    else  { // retrieve the option from the last used. Default is Caravelle View
        use_classic_view = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_DUPLICATE_CLASSIC_VIEW];
    }
    
    applicationMode = ApplicationModeDuplicate;
    
    // ___________________________________
    // Prepare the view for Duplicate View
    // -----------------------------------
    if (use_classic_view) {
        // Reduce to single panel view
        if ([[self.ContentSplitView subviews] count]==2) { // in dual mode view
            [[[self.ContentSplitView subviews] objectAtIndex:1] removeFromSuperview];
        }
        [myLeftView setName:@"DuplicateSingle" TwinName:nil];
        [myLeftView setViewMode:BViewDuplicateMode];
        [myLeftView setViewType:BViewTypeTable];
        [myLeftView setTreeViewCollapsed:YES];
        // Activate the Flat View
        [myLeftView setFlatView:YES];
        NSArray *dupColumns = [NSArray arrayWithObjects:@"COL_PATH", @"COL_SIZE", @"COL_DATE_MODIFIED", nil];
        [myLeftView.detailedViewController setupColumns:dupColumns];
        // Group by Location
        [myLeftView.detailedViewController makeSortOnFieldID:@"COL_DUP_GROUP" ascending:YES grouping:YES];
        
        // ___________________________
        // Setting the duplicate Files
        // ---------------------------
        [duplicates setFiles: duplicatedFileArray];
        selectedDuplicatesRoot = [[TreeRoot alloc] init];
        [selectedDuplicatesRoot setName:@"Duplicates"];
        [selectedDuplicatesRoot setFileCollection:duplicates];
        [myLeftView setRoots:[NSArray arrayWithObject:selectedDuplicatesRoot]];
        [myLeftView stopBusyAnimations];
        [myLeftView selectFirstRoot];
        
    }
    else {
         // Create right window if needed
        if (myRightView == nil) {
            myRightView = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
            [myRightView setParentController:self];
        }
        
        // Change the name so to get new preferences
        [myLeftView setName:@"DuplicateMaster" TwinName:nil];
        [myRightView setName:@"DuplicateDetail" TwinName:nil];
        
        // change to Dual View
        if ([[_ContentSplitView subviews] count]==1) { // in single mode view
            [_ContentSplitView addSubview:myRightView.view];
            [_ContentSplitView adjustSubviews];
            //[_ContentSplitView setNeedsDisplay:YES];
        }
        [myLeftView setViewMode:BViewDuplicateMode];
        [myLeftView setViewType:BViewTypeTable];
        // Activate the Tree View on the Left
        [myLeftView setTreeViewCollapsed:NO];
        // Make the FlatView and Group by Location
        [myLeftView setFlatView:YES];
        // TODO:!!!! use the [view setName:twinName:] To change to a "Dup Left" and "Dup Right"
        // TODO:!!! Mode Duplicate should cancel all operations, except if plugin is activated
        NSArray *dupColumns = [NSArray arrayWithObjects:@"COL_DUP_GROUP", @"COL_NAME", @"COL_SIZE", nil];
        [myLeftView.detailedViewController setupColumns:dupColumns];
        [myLeftView.detailedViewController makeSortOnFieldID:@"COL_LOCATION" ascending:YES grouping:YES];
        
        [myRightView setViewMode:BViewDuplicateMode];
        [myRightView setViewType:BViewTypeTable];
        // Deactivate the Tree View on the Left
        [myRightView setTreeViewCollapsed:YES];
        // Activate the Flat View
        [myRightView setFlatView:YES];
        [myRightView.detailedViewController setupColumns:dupColumns];
        // Group by Location
        [myRightView.detailedViewController makeSortOnFieldID:@"COL_LOCATION" ascending:YES grouping:YES];
        
        // ___________________________
        // Setting the duplicate Files
        // ---------------------------
        
        [duplicates setFiles: duplicatedFileArray];
        NSArray *rootDirs = [info objectForKey:kRootsList];
        [myLeftView setRoots:rootDirs];
        [myLeftView stopBusyAnimations];
        
        selectedDuplicatesRoot = [[TreeRoot alloc] init];
        [selectedDuplicatesRoot setName:@"Duplicates"];
        [myRightView setRoots:[NSArray arrayWithObject:selectedDuplicatesRoot]];
        [myRightView stopBusyAnimations];
        [myRightView selectFirstRoot];
        
        [myLeftView selectFirstRoot]; // This has to be done at the end since it triggers the statusUpdate:
    }
    // Disables the Icon View
    [self.toolbarViewTypeSelect setEnabled:NO forSegment:BViewTypeIcon];
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

    if (pendingOperationErrors==nil || [pendingOperationErrors count]==0) {
        [fileExistsWindow closeWindow];
        return;
    }

    if (theNotification!=nil) { // It cames from the window closing
        NSArray *note = pendingOperationErrors[0]; // Fifo Like structure
        NSURL* sourceURL = note[0];
        NSURL* destinationURL = note[1];
        NSError *error = note[2];
        //TODO:!!!!! This can be dangerous with Localizations
        NSString *operation = [[[error userInfo] objectForKey:@"NSUserStringVariant"] firstObject];

        NSDictionary *info = [theNotification userInfo];
        NSString *new_name = [info objectForKey:kFileExistsNewFilenameKey];

        NSAssert(error.code == NSFileWriteFileExistsError, @"To ensure that the processing is being done to the correct code");
        // Lauch the new Operation based on the user choice
        fileExistsQuestionResult answer = [[info objectForKey:kFileExistsAnswerKey] integerValue];
        if  (answer== FileExistsRename) {
            NSString const *op;
            if ([operation isEqualToString:@"Copy"]) {
                op = opCopyOperation;
            }
            else if ([operation isEqualToString:@"Move"]) {
                op = opMoveOperation;
            }
            else {
                NSAssert(NO, @"Invalid Operation");
            }
            // Need to pass the parent folder for the file operations
            NSURL *destURL = [destinationURL URLByDeletingLastPathComponent];

            NSArray *items = [NSArray arrayWithObject:sourceURL];
            NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      op, kDFOOperationKey,
                                      items, kDFOFilesKey,
                                      destURL, kDFODestinationKey,
                                      new_name, kDFORenameFileKey,
                                      nil];

            [self startFileOperation:taskinfo];
            // The file system notifications will make sure that the views are updated
        }
        else if (answer == FileExistsSkip) {

            /* Basically we don't do nothing */
        }
        else if (answer ==  FileExistsReplace) {
            NSArray *items = [NSArray arrayWithObject:sourceURL];
            NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      opReplaceOperation, kDFOOperationKey,
                                      items, kDFOFilesKey,
                                      destinationURL, kDFODestinationKey,
                                      //new_name, kDFORenameFileKey, // No renaming, just replaces the file
                                      nil];

            [self startFileOperation:taskinfo];

        }
        [pendingOperationErrors removeObjectAtIndex:0];
    }
    if ([pendingOperationErrors count]>=1) { // If only one open the
        NSArray *note = pendingOperationErrors[0]; // Fifo Like structure
        NSURL* sourceURL = note[0];
        NSURL* destinationURL = note[1];
        NSError *error = note[2];
        //NSString *operation = [[[error userInfo] objectForKey:@"NSUserStringVariant"] firstObject];

        if (error.code==NSFileWriteFileExistsError) { // File already exists
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
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert beginSheetModalForWindow:[self myWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];

            NSLog(@"AppDelegate.processNext:Error: Error not processed %@", error); // Don't comment this, before all tests are completed.
            // Delete the error not processed
            [pendingOperationErrors removeObjectAtIndex:0];
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
    // TODO: !!!!! Only add errors that can be treated.
    [pendingOperationErrors addObject:note];
    if ([pendingOperationErrors count] == 1) { // Call it if there aren't more pending
        [self processNextError:nil]; // Nil is passed on purpose to trigger the reading of the error queue
    }
    else if ([pendingOperationErrors count] > 1) {
        // Focus on the Window
        [fileExistsWindow displayWindow:self];
    }
}

#pragma - NSFileManagerDelegate

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    NSArray *note = [NSArray arrayWithObjects:srcURL, dstURL, error, nil];
    [self performSelectorOnMainThread:@selector(mainThreadErrorHandler:) withObject:note waitUntilDone:NO];
    statusFilesCopied--;
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    NSArray *note = [NSArray arrayWithObjects:srcURL, dstURL, error, nil];
    [self performSelectorOnMainThread:@selector(mainThreadErrorHandler:) withObject:note waitUntilDone:NO];
    statusFilesMoved--;
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    NSLog(@"AppDelegate.fileManager:shouldProceedAfterError:copyingItemAtPath:toPath");
    statusFilesCopied--;
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    NSLog(@"AppDelegate.fileManager:shouldProceedAfterError:movingItemAtPath:toPath");
    statusFilesMoved--;
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error removingItemAtPath:(NSString *)path {
    NSLog(@"AppDelegate.fileManager:shouldProceedAfterError:removingItemAtPath:toPath");
    statusFilesDeleted--;
    return NO;
}
- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error removingItemAtURL:(NSURL *)URL {
    NSLog(@"AppDelegate.fileManager:shouldProceedAfterError:removingItemAtURL:toPath");
    statusFilesDeleted--;
    return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager
shouldCopyItemAtURL:(NSURL *)srcURL
              toURL:(NSURL *)dstURL {
    enumPathCompare comp = url_relation(srcURL, dstURL);
    if (comp==pathIsParent || comp == pathIsChild) {
        // If the path is contained or contains the operation cannot be completed
        //TODO:! create an error subclass
        return NO;
    }
    //NSLog(@"should copy item\n%@ to\n%@", srcURL, dstURL);
    statusFilesCopied++;
    return YES;
}

- (BOOL)fileManager:(NSFileManager *)fileManager
shouldMoveItemAtURL:(NSURL *)srcURL
              toURL:(NSURL *)dstURL {
    enumPathCompare comp = url_relation(srcURL, dstURL);
    if (comp==pathIsParent || comp == pathIsChild) {
        // If the path is contained or contains the operation cannot be completed
        //TODO:! create an error subclass
        return NO;
    }
    //NSLog(@"should move item\n%@ to\n%@", srcURL, dstURL);
    statusFilesMoved++;
    return YES;
}

-(BOOL) fileManager:(NSFileManager *)fileManager
shouldRemoveItemAtURL:(NSURL *)URL {
    //NSLog(@"should remove item\n%@", URL);
    statusFilesDeleted++;
    return YES;
}

@end
