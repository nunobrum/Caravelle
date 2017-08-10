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
#import "UserPreferencesManager.h"
#import "RenameFileDialog.h"
#import "PasteboardUtils.h"

#import "StartupScreenController.h"
#import "DuplicateModeStartWindow.h"
#import "DuplicateDelegate.h"

// TODO:2.0 Virtual Folders
// #import "filterBranch.h"
// #import "CatalogBranch.h"
#import "myValueTransformers.h"

NSString *notificationStatusUpdate=@"StatusUpdateNotification";


NSString *notificationViewChanged=@"ViewChanged";
NSString *kViewChangedWhatKey=@"kViewChangedWhatKey";


NSString *notificationDoFileOperation = @"DoOperation";
NSString *kDFOOperationKey =@"OperationKey";
NSString *kDFODestinationKey =@"DestinationKey";
NSString *kDFORenameFileKey = @"RenameKey";
NSString *kNewFolderKey = @"NewFolderKey";
NSString *kDFOFilesKey=@"FilesSelected";
NSString *kDFOErrorKey =@"ErrorKey";
NSString *kDFOOkKey = @"OKKey";
NSString *kDFOIDKey = @"IDKey";
NSString *kDFOStatusKey = @"StatusKey";
NSString *kDFOFromViewKey = @"FromObjectKey";
NSString *kDFODepthKey = @"FlatDepthKey";

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
NSString const *opChangeMode    = @"com.cascode.op.changemode";

NSFileManager *appFileManager;
NSOperationQueue *operationsQueue;         // queue of NSOperations (1 for parsing file system, 2+ for loading image files)
NSOperationQueue *browserQueue;    // Queue for directory viewing (High Priority)
NSOperationQueue *lowPriorityQueue; // Queue for size calculation (Low Priority)

UserPreferencesManager *userPreferenceManager;


EnumApplicationMode _application_mode;
inline EnumApplicationMode application_mode() {
    return _application_mode;
}


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

void menuForTag(EnumContextualMenuItemTags tag, NSMenuItem *menuItem) {
    unichar key = 0;
    NSUInteger mask = 0;
    switch (tag) {
        case menuAddFavorite:
            menuItem.title = @"Add to Favorites";
            [menuItem setAction:@selector(contextualAddFavorite:)];
            break;
            
        case menuInformation:
            menuItem.title = @"Get Info";
            key = NSF1FunctionKey;
            [menuItem setAction:@selector(contextualInformation:)];
            break;
            
        case menuRename:
            menuItem.title = @"Rename";
            key = NSF2FunctionKey;
            [menuItem setAction: @selector(contextualRename:)];
            break;
            
        case menuOpen:
            menuItem.title = @"Open";
            key = NSF4FunctionKey;
            [menuItem setAction: @selector(contextualOpen:)];
            break;
            
        case menuView:
            menuItem.title = @"View";
            key = NSF3FunctionKey;
            [menuItem setAction: @selector(contextualRename:)];
            break;
            
        case menuOpenWith:
            menuItem.title = @"Open With...";
            //key = NSLeftArrowFunctionKey;
            break;
            
        case menuDelete:
            menuItem.title = @"Delete";
            key = NSF8FunctionKey;
            [menuItem setAction: @selector(contextualDelete:)];
            break;
            
        case menuCopyTo:
            menuItem.title = @"Copy to...";
            key = NSF5FunctionKey;
            [menuItem setAction: @selector(contextualCopyTo:)];
            break;
            
        case menuCopyLeft:
            menuItem.title = @"Copy to Left";
            key = NSF6FunctionKey;
            [menuItem setAction: @selector(contextualCopyTo:)];
            break;
            
        case menuCopyRight:
            menuItem.title = @"Copy Right";
            key = NSF6FunctionKey;
            [menuItem setAction: @selector(contextualCopyTo:)];
            break;
            
        case menuMoveTo:
            menuItem.title = @"Move to...";
            key = NSF7FunctionKey;
            [menuItem setAction: @selector(contextualMoveTo:)];
            break;
            
        case menuMoveLeft:
            menuItem.title = @"Move to Left";
            key = NSF7FunctionKey;
            [menuItem setAction: @selector(contextualMoveTo:)];
            break;

        case menuMoveRight:
            menuItem.title = @"Move to Right";
            key = NSF7FunctionKey;
            [menuItem setAction: @selector(contextualMoveTo:)];
            break;
            
        case menuClipCut:
            menuItem.title = @"Cut";
            key = 'x';
            mask = NSCommandKeyMask;
            [menuItem setAction: @selector(contextualCut:)];
            break;
            
        case menuClipCopy:
            menuItem.title = @"Copy";
            key = 'c';
            mask = NSCommandKeyMask;
            [menuItem setAction: @selector(contextualCopy:)];
            break;
            
        case menuClipCopyName:
            menuItem.title = @"Copy Name";
            key = 'c';
            mask = NSCommandKeyMask + NSAlternateKeyMask;
            [menuItem setAction: @selector(contextualCopyName:)];
            break;
            
        case menuClipPaste:
            menuItem.title = @"Paste";
            key = 'v';
            mask = NSCommandKeyMask;
            [menuItem setAction: @selector(contextualPaste:)];
            break;
            
        case menuNewFolder:
            menuItem.title = @"New Folder";
            key = NSF7FunctionKey;
            [menuItem setAction: @selector(contextualNewFolder:)];
            break;
            
        case menuDivider:
        default:
            menuItem.title = @"";
            break;
    }
    if (key != 0) {
        [menuItem setKeyEquivalent:[NSString stringWithCharacters:&key length:1]];
        [menuItem setKeyEquivalentModifierMask:mask];
        
    }
}

void updateContextualMenu(NSMenu *menu, NSArray *itemsSelected, EnumContextualMenuItemTags itemTags[]) {
    NSInteger index = 0;
    BOOL addDivider = NO;
    while (itemTags[index] != menuEnd) {
        EnumContextualMenuItemTags tag = itemTags[index++];
        if (tag == menuDivider) {
            addDivider = YES; // This avoids adding two consecutive dividers if menus are eliminated
        }
        else {
            BOOL isIncluded = NO;
            for (TreeItem *item in itemsSelected) {
                if ([item respondsToMenuTag:tag & 0xFFFFFFF0]) {
                    isIncluded = YES;
                    break;
                }
            }
            if (isIncluded) {
                if (addDivider) {
                    [menu addItem:[NSMenuItem separatorItem]];
                    addDivider = NO;
                }
                NSMenuItem *menuItem = [[NSMenuItem alloc] init];
                menuForTag(tag, menuItem);
                [menu addItem:menuItem];
                if (tag == menuOpenWith) {
                    // Special situation where the menu is handled here. Because it has to be asked from the item Selected.
                    
                    // Check that all files have common open applications
                    TreeItem *firstItem = [itemsSelected firstObject];
                    
                    NSMutableArray *apps =
                        [NSMutableArray arrayWithArray: [firstItem openWithApplications]];
                    // If more than two files is selected it will reduce to the common open with applications
                    for (NSInteger i = 1 ; i < itemsSelected.count ; i++) {
                        TreeItem *item = itemsSelected[i];
                        NSArray *appsx = [item openWithApplications];
                        [apps filterUsingPredicate: [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                            return [appsx containsObject:evaluatedObject];
                                }]];
                    }
                    
                    if (apps != nil && [apps count] > 0) {
                        NSMenu *menu = [[NSMenu alloc] init];
                        for (NSURL *app in apps) {
                            NSMenuItem *menuApp = [[NSMenuItem alloc] initWithTitle:app.lastPathComponent action:@selector(contextualOpenWith:) keyEquivalent:@""];
                            [menuApp setRepresentedObject:app];
                            [menu addItem:menuApp];
                        }
                        [menu setAutoenablesItems:NO]; // Default enables everything
                        [menu setSubmenu:menu forItem:menuItem];
                    }
                }
            }
        }
    }
    if (addDivider) {
        [menu addItem:[NSMenuItem separatorItem]];
    }
}

NSUInteger segmentForApplicationMode(EnumApplicationMode mode) {
    NSUInteger segment;
    switch (mode) {
        case ApplicationMode1View:
            segment = 0;
            break;
        case ApplicationMode2Views:
            segment = 1;
            break;
        case ApplicationModeDupSingle:
            segment = 0;
            break;
        case ApplicationModeDupDual:
            segment = 1; // This must be updated
            break;
        case ApplicationModeSync:
            segment = 1;
            break;
        case ApplicationModePreview:
            segment = 2;
            break;
        default:
            segment = 1;
            break;
    }
    return segment;
}

EnumApplicationMode applicationModeForSegment(NSUInteger segment) {
    EnumApplicationMode mode;
    if (applicationMode & ApplicationModeDupBrowser) {
        switch (segment) {
            case 0:
                mode = ApplicationModeDupSingle;
                break;
            default:
                mode = ApplicationModeDupDual;
                break;
        }
    }
    else {
        switch (segment) {
            case 0:
                mode = ApplicationMode1View;
                break;
            case 1:
                mode = ApplicationMode2Views;
                break;
                /*case 2: // TODO:1.5:
                 mode = ApplicationModePreview;
                 break;*/
            default:
                mode = ApplicationMode1View;
                break;
        }
    }
    return mode;
}


@interface AppDelegate (Privates)

- (void)         refreshAllViews:(NSNotification*)theNotification;
- (void)            statusUpdate:(NSNotification*)theNotification;
- (void) viewChangedNotification:(NSNotification*)theNotification;
- (void)        processNextError:(NSNotification*)theNotification;
- (id<MYViewProtocol>)   selectedView;
@end

@implementation AppDelegate {
    NSTimer	*_operationInfoTimer;                  // update timer for progress indicator
    NSNumber *treeUpdateOperationID;
    DuplicateModeStartWindow *duplicateStartupScreenCtrl; // Duplicates Dialog
    DuplicateFindSettingsViewController *duplicateSettingsWindow;
    RenameFileDialog *renameFilePanel;
    FileExistsChoice *fileExistsWindow;
    NSMutableArray *pendingOperationErrors;
    NSMutableArray *pendingStatusMessages;
    BOOL isCutPending;
    BOOL isApplicationTerminating;
    BOOL isWindowClosing;
    NSInteger generalPasteBoardChangeCount;
    NSInteger statusTimeoutCounter;
    // Duplicate Support
    DuplicateDelegate *duplicateController;
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
        self->renameFilePanel = nil;
        self->fileExistsWindow = nil;
        self->myLeftView = nil;
        self->myRightView = nil;
        self->pendingOperationErrors = nil;
        self->pendingStatusMessages = nil;
        
        operationsQueue   = [[NSOperationQueue alloc] init];
        browserQueue      = [[NSOperationQueue alloc] init];
        lowPriorityQueue  = [[NSOperationQueue alloc] init];
        userPreferenceManager = nil;
        
        // Browser Queue
        // We limit the concurrency to see things easier for demo purposes. The default value NSOperationQueueDefaultMaxConcurrentOperationCount will yield better results, as it will create more threads, as appropriate for your processor
        [browserQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        [browserQueue setQualityOfService:NSOperationQualityOfServiceUserInitiated];
        
        [lowPriorityQueue setMaxConcurrentOperationCount:1];
        [lowPriorityQueue setQualityOfService:NSOperationQualityOfServiceBackground];


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
        DuplicateIDToStringTransformer *duplicateID_transformer = [[DuplicateIDToStringTransformer alloc] init];
        [NSValueTransformer setValueTransformer:duplicateID_transformer forName:@"duplicate_id"];
        
        isCutPending = NO; // used for the Cut to Clipboard operations.
        isApplicationTerminating = NO; // to inform that the application should quit after all processes are finished.
        isWindowClosing = NO;
        //FSMonitorThread = [[FileSystemMonitoring alloc] init];
        self.appInImage = nil; //[NSImage imageNamed:@"PRO"];
	}
	return self;
}

#pragma mark auxiliary functions

-(void) prepareView:(id<MYViewProtocol>) view withItem:(TreeBranch*)item {
    [(BrowserController*)view removeAll];
    [(BrowserController*)view refresh];
    [(BrowserController*)view startAllBusyAnimations];
    [(BrowserController*)view setViewMode:BViewBrowserMode ];
    [(BrowserController*)view setViewType:BViewTypeVoid];
    
    [(BrowserController*)view loadPreferences];
    [(BrowserController*)view setDrillDepth:0];
    
    [(BrowserController*)view setRoots: [NSArray arrayWithObject:item]];
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
                homepath = [myLeftView homePath];
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
                id item = [(TreeManager*)appTreeManager addTreeItemWithURL:url askIfNeeded:YES];
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
        // An possible workaround this is just using the first Bookmark available
        
        [self executeOpenFolderInView:view withTitle:@"Select a Folder to Browse"];
        [self savePreferences];

#else
        if (homepath == nil || [homepath isEqualToString:@""]) {
            NSLog(@"AppDelegate.goHome: Failed to retrieve home folder from NSUserDefaults. Using Home Directory");
            homepath = NSHomeDirectory();
        }

        url = [NSURL fileURLWithPath:homepath isDirectory:YES];
        id item = [(TreeManager*)appTreeManager addTreeItemWithURL:url askIfNeeded:NO];
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
    //NSLog(@"AppDelegate.savePreferences:");
    if (applicationMode <= ApplicationMode2Views) { // Only records simple Single and Dual Pane Views
                                                    // TODO:1.4 This will have to be revised
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithLong:applicationMode] forKey:USER_DEF_APP_VIEW_MODE];
        NSString *homepath = [myLeftView homePath];
        [[NSUserDefaults standardUserDefaults] setObject:homepath forKey:USER_DEF_LEFT_HOME];
        
        [myLeftView savePreferences];
        if (myRightView) {
            if (applicationMode <= ApplicationMode2Views) {
                NSString *homepath = [myRightView homePath];
                [[NSUserDefaults standardUserDefaults] setObject:homepath forKey:USER_DEF_RIGHT_HOME];
            }
            [myRightView savePreferences];
        }
        
        // Store the width
        CGFloat width = NSWidth([[[self.BrowserSplitView subviews] firstObject] bounds]);
        [[NSUserDefaults standardUserDefaults] setFloat:width forKey:USER_DEF_LEFT_VIEW_SIZE];
    }
    BOOL sideCollapsed = [self.ContentSplitView isSubviewCollapsed: self->sideBarController.view] ;
    [[NSUserDefaults standardUserDefaults] setBool:(sideCollapsed==NO) forKey:USER_DEF_LEFT_PANEL_VISIBLE];
    if (!sideCollapsed) {
        NSInteger width = NSWidth([(NSView*)[[self.ContentSplitView subviews] objectAtIndex:0] bounds]);
        [[NSUserDefaults standardUserDefaults] setInteger:width forKey:USER_DEF_LEFT_PANEL_SIZE];
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

-(void) makeView1:(NSString*)view1 view2:(NSString*)view2 {
    NSArray *subViews = [self.BrowserSplitView subviews];
    NSUInteger panelCount = [subViews count];
    
    if (myLeftView == nil) {
        myLeftView  = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
        [myLeftView setParentController:self];
        
        
    }
    if (panelCount == 0) {
        [self.BrowserSplitView addSubview:myLeftView.view];
        panelCount++;
    }
    [myLeftView  setName:view1  TwinName:view2];  // A first call not valid, because its called before the add view
    
    if (view2 == nil) { // Removing the Right View if needed
        if (panelCount == 2) {
            [myRightView.view removeFromSuperview];
        }
    }
    else { // Adding a Right View if needed
        if (myRightView == nil) {
            myRightView = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
            [myRightView setParentController:self];
                    }
        if (panelCount == 1) {
            [self.BrowserSplitView addSubview:myRightView.view];
        }
        [myRightView setName:view2 TwinName:view1];
    }
    
    if (myLeftView.detailedViewController.currentNode==nil) {
        // Left Side
        [self goHome: myLeftView]; // Display the User Preferences Left Home
        
    }
    if (myRightView.detailedViewController.currentNode==nil) {
        // Right side
        if ((applicationMode & ApplicationModeDupBrowser)==0) {
            // Only does it if not in duplicate mode.
            [self goHome: myRightView]; // Display the User Preferences Left Home
        }
    }
    
    [_ContentSplitView adjustSubviews];
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

    [center addObserver:self selector:@selector(viewChangedNotification:) name:notificationViewChanged object:nil];

    [center addObserver:self selector:@selector(refreshAllViews:) name:notificationRefreshViews object:nil];

    // register self as the the Delegate for the main window
    [_myWindow setDelegate:self];

    userPreferenceManager =[[UserPreferencesManager alloc] initWithWindowNibName:@"UserPreferencesDialog"];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:userPreferenceManager];

    /* Registering for receiving services */
    NSArray *sendTypes = [NSArray arrayWithObjects:NSURLPboardType,
                          NSFilenamesPboardType, nil];
    NSArray *returnTypes = [NSArray arrayWithObjects:NSURLPboardType,
                            NSFilenamesPboardType, nil];
    [NSApp registerServicesMenuSendTypes:sendTypes
                             returnTypes:returnTypes];

    _application_mode = [[NSUserDefaults standardUserDefaults] integerForKey:USER_DEF_APP_VIEW_MODE];
    
    
    [self.myWindow setFrameAutosaveName:@"CRVLMainWindowSize"];
    NSSize windowSize = self.myWindow.frame.size;
    //NSLog(@"Saved Window Size %f,%f", windowSize.width, windowSize.height);

    
    sideBarController = [[MainSideBarController alloc] initWithNibName:@"MainSideBarView" bundle:nil ];
    [self.ContentSplitView addSubview:sideBarController.view];
    
    self.BrowserSplitView = [[NSSplitView alloc] init];
    [self.BrowserSplitView setVertical:YES];
    [self.BrowserSplitView setDividerStyle:NSSplitViewDividerStylePaneSplitter];
    [self.BrowserSplitView setContentCompressionResistancePriority:200 forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.BrowserSplitView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable ];
    [self.BrowserSplitView setAutoresizesSubviews:YES];

    [self.ContentSplitView addSubview:self.BrowserSplitView];
    
    // TODO:1.4 Implement the modes preview and Sync
    if (applicationMode != ApplicationMode2Views ) {
        // For now just defaults to one Pane Mode
        _application_mode = ApplicationMode1View;

    }
    [self.toolbarAppModeSelect setSelected:YES forSegment:segmentForApplicationMode(applicationMode)];

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
    
    if (applicationMode == ApplicationMode2Views) {
        [self makeView1:@"Left" view2:@"Right"];
        // repositions the splitter.
        CGFloat dividerPosition = [[NSUserDefaults standardUserDefaults] floatForKey:USER_DEF_LEFT_VIEW_SIZE];
        if (dividerPosition!=0) {
            [self.BrowserSplitView setPosition:dividerPosition ofDividerAtIndex:0];
        }
    }
    else if (applicationMode == ApplicationMode1View) {
        [self makeView1:@"Single" view2:nil];
    }
    else {
        NSAssert(NO,@"Application start mode not supported");
    }
    // Configuring the FunctionBar according to User Defaults
    BOOL displayFunctionBar = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_APP_DISPLAY_FUNCTION_BAR];
    [self.toolbarFunctionBarSelect setSelected:displayFunctionBar forSegment:MAIN_VIEW_OPTION_VISIBLE_FUNCTIONS];
    [self setDisplayFunctionKeys:displayFunctionBar];
    
    // Get from user defaults the presence of the panel
    BOOL sideBarVisible = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_LEFT_PANEL_VISIBLE];
    [self.toolbarFunctionBarSelect setSelected:sideBarVisible forSegment:MAIN_VIEW_OPTION_VISIBLE_SIDEBAR];
    [self setDisplaySideBar:sideBarVisible];
    
    // Corrects the problem with the expansion of the window
    
    if (windowSize.height!=0 && windowSize.width!=0)
    {
        [self.myWindow setContentSize:windowSize];
    }

    // Make a default focus
    self->_selectedView = myLeftView;
    // Set the Left view as first responder
    [myLeftView focusOnFirstView];
    [self adjustSideInformation:myLeftView];

    //[self.myWindowView needsDisplay];
    

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
                                      myLeftView, kDFOFromViewKey,
                                      [NSNumber numberWithInteger:BViewCatalystMode], kModeKey,
                                      nil];
            TreeScanOperation *Op = [[TreeScanOperation new] initWithInfo: taskInfo];
            treeUpdateOperationID = [Op operationID];
            [operationsQueue addOperation:Op];
            [self Op];
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
                    NSString *pred = [NSString stringWithFormat:@"SELF.exactSize < %d", sz*1000000];
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
        [userPreferenceManager close]; // close the preferences menu when closing main window
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

// Will get this from the NodeViewController
extern EnumContextualMenuItemTags viewMenuFiles[];
extern EnumContextualMenuItemTags viewMenuNoFiles[];

// Make a Full programatic menu
-(void) menuNeedsUpdate:(NSMenu*) menu {
    //NSLog(@"NodeViewController.menuNeedsUpdate");
    // tries a contextual excluding the click in blank space
    [menu removeAllItems];
    NSArray *itemsSelected = [[self selectedView] getSelectedItemsForContextualMenu2];
    if (itemsSelected==nil) {
        itemsSelected = [[self selectedView] getSelectedItemsForContextualMenu1];
        updateContextualMenu(menu, itemsSelected, viewMenuNoFiles);
    }
    else {
        updateContextualMenu(menu, itemsSelected, viewMenuFiles);
    }
}

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
    [myLeftView cleanRefresh];
    if (myRightView!=nil && (application_mode() & ApplicationMode2Views)!=0) {
        [myRightView cleanRefresh];
    }
}



// gets the notifications from important view changes
- (void) viewChangedNotification:(NSNotification*)theNotification {
    NSDictionary *notifInfo = [theNotification userInfo];
    id senderView = [theNotification object];
    
    if ([senderView isKindOfClass:[BrowserController class]]) {
        if ([notifInfo[kViewChangedWhatKey] isEqualToString:kViewChanged_TreeCollapsed]) {
            if ((applicationMode & ApplicationModeDupBrowser)!=0) {
                if (senderView == myRightView) {
                    [self statusUpdate:nil];
                }
                else if (senderView==myLeftView) {
                    [myLeftView removeAll];
                    [myLeftView refresh];
                    if ([myLeftView treeViewCollapsed]) {
                        // Activate the Flat View
                        [myLeftView setDrillDepth:NSIntegerMax];
                        // TODO:1.4 This should be retrieved from the default settings
                        NSArray *dupColumns = [NSArray arrayWithObjects:@"COL_PATH", @"COL_SIZE", @"COL_DATE_MODIFIED", nil];
                        [myLeftView.detailedViewController setupColumns:dupColumns];
                        [myLeftView.detailedViewController makeGroupingOnFieldID:@"COL_DUP_GROUP" ascending:YES];
                        [myLeftView addTreeRoot:duplicateController.unifiedDuplicatesRoot];
                        [myLeftView selectFirstRoot];
                        
                    }
                    else {
                        
                        // Deactivate the Flat View
                        [myLeftView setDrillDepth:0];
                        NSArray *dupColumns = [NSArray arrayWithObjects:@"COL_DUP_GROUP", @"COL_NAME", @"COL_SIZE", @"COL_DATE_MODIFIED", nil];
                        [myLeftView.detailedViewController setupColumns:dupColumns];
                        // Group by Location
                        [myLeftView.detailedViewController makeSortOnFieldID:@"COL_NAME" ascending:YES];
                        [myLeftView setRoots:duplicateController.rootsWithDuplicates.roots];
                        [myLeftView selectFirstRoot]; // This has to be done at the end since it triggers the statusUpdate:
                    }
                }
            }
        }
    }
}

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
//        BrowserController *BView =[notifData valueForKey: kDFOFromViewKey];
//        id sender = [note object];
//        assert(BView!=sender); // check if the kDFOFromViewKey can't be deleted
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

-(BOOL) checkAppInDuplicateBlocking {
    if (applicationMode & ApplicationModeDupBrowser) {
        if ([userPreferenceManager duplicatesAuthorized]==NO) {
            NSAlert *buyAppInInfo = [[NSAlert alloc] init];
            [buyAppInInfo addButtonWithTitle:@"OK"];
            // TODO:1.4 Buy Button to open direcly the referred window
            [buyAppInInfo setMessageText:@"Locked Feature"];
            [buyAppInInfo setInformativeText:@"App-In 'Duplicates Manager' needed to proceed.\nThis App-In can be bought direcly on menu Caravelle-Preferences... App-Ins section"];
            [buyAppInInfo setAlertStyle:NSWarningAlertStyle];
            [buyAppInInfo beginSheetModalForWindow:[self myWindow] completionHandler:nil ];
            return NO;
        }
    }
    return YES;
}

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
            id item = [(TreeManager*)appTreeManager addTreeItemWithURL:url askIfNeeded:YES];
            if (item != nil) {
                // Add to the Browser View
                [(BrowserController*)view removeAll];
                [(BrowserController*)view refresh];
                [(BrowserController*)view startAllBusyAnimations];
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
    // Checking first if the operation is not blocked.
    if ([self checkAppInDuplicateBlocking]==NO) return;
    

    NSUInteger numberOfFiles = [selectedFiles count];
    // TODO:1.4 Option for the rename, on the table or on a dedicated dialog
    if (numberOfFiles == 1) {
        TreeItem *selectedFile = [selectedFiles firstObject];
        if (1) { // Rename done in place // TODO:1.4 Put this is a USer Configuration
            [[self selectedView] startEditItemName:selectedFile];
        }
        // Using a dialog Box
        else {
            NSString *oldFilename = [selectedFile name];
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
        // TODO:1.4 Implement the multi-rename
        // If more than one file, will invoke the multi-rename dialog
        // For the time being this is an invalid condition. Need to notify user.
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        // TODO:1.4 Buy Button to open direcly the referred window
        [alert setMessageText:@"Multiple Files Selected"];
        [alert setInformativeText:@"Rename of multiple files will be available in a future version."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[self myWindow] completionHandler:^(NSModalResponse returnCode) {}];

    }
}

-(BOOL) startFileOperation:(NSDictionary *) operationInfo {
    FileOperation *operation = [[FileOperation alloc] initWithInfo:operationInfo];
    [self _startOperationBusyIndication: operation];
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
    
    id node = nil;
    
    if ([self selectedView] == myLeftView) {
        node = [myRightView treeNodeSelected];
    }
    else if ([self selectedView] == myRightView) {
        node = [myLeftView treeNodeSelected];
    }
    
    if (node!=nil && [node isKindOfClass:[TreeBranch class]]) {
        [self copyItems:selectedFiles toBranch: node];
    }
    else {
        NSLog(@"AppDelegate.executeCopyTo: Received wrong object. Expected TreeBranch received %@", [node className]);
    }
}

-(void) executeMoveTo:(NSArray*) selectedFiles {
    
    // Checking first if the operation is not blocked.
    if ([self checkAppInDuplicateBlocking]==NO) return;
    id node = nil;
    
    if ([self selectedView] == myLeftView) {
        node = [myRightView treeNodeSelected];
    }
    else if ([self selectedView] == myRightView) {
        node = [myLeftView treeNodeSelected];
    }
    
    if (node!=nil && [node isKindOfClass:[TreeBranch class]]) {
        [self moveItems:selectedFiles toBranch: node];
    }
    else {
        NSLog(@"AppDelegate.executeMoveTo: Received wrong object. Expected TreeBranch received %@", [node className]);
    }
}

-(void) executeOpen:(NSArray*) selectedFiles {
    for (TreeItem *item in selectedFiles) {
        [[NSWorkspace sharedWorkspace] openFile:[item path]];
    }
}

- (void) executeNewFolder:(TreeBranch*)selectedBranch {
    // Safety check : This should have been already blocked in the validation of the menu
    if (applicationMode & ApplicationModeDupBrowser) return;
    
    NSURL *newURL = [[selectedBranch url] URLByAppendingPathComponent:@"New Folder"];
    TreeBranch *newFolder = [[TreeBranch alloc] initWithURL:newURL parent:selectedBranch];
    [newFolder setTag:tagTreeItemNew];
    [newFolder resetTag:tagTreeItemReadOnly];
    [[self selectedView] insertItem:newFolder];
    [[self selectedView] startEditItemName:newFolder];
}


- (void)executeCut:(NSArray*) selectedFiles {
    // Checking first if the operation is not blocked.
    if ([self checkAppInDuplicateBlocking]==NO) return;

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
    // TODO:1.4.1 multi copy, where an additional copy will append items to the pasteboard
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
    
    if (onlyNames==YES) {
        [clipboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil]
                          owner:nil];

        NSArray* str_representation = [selectedFiles valueForKeyPath:@"@unionOfObjects.name"];
        // Join the paths, one name per line
        NSString* pathPerLine = [str_representation componentsJoinedByString:@"\n"];
        //Now add the pathsPerLine as a string
        [clipboard setString:pathPerLine forType:NSStringPboardType];
    }
    // if only names are copied, the urls are not
    else {
        [clipboard declareTypes:[NSArray arrayWithObjects:
                                 NSURLPboardType,
                                 NSFilenamesPboardType,
                                 // NSFileContentsPboardType, not passing file contents
                                 NSStringPboardType, nil]
                          owner:nil];

        NSArray* str_representation = [selectedFiles valueForKeyPath:@"@unionOfObjects.path"];
        // Join the paths, one name per line
        NSString* pathPerLine = [str_representation componentsJoinedByString:@"\n"];
        //Now add the pathsPerLine as a string
        [clipboard setString:pathPerLine forType:NSStringPboardType];

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
    // Safety check : This should have already been blocked in the menu validation
    if (applicationMode & ApplicationModeDupBrowser) return;

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
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Can't complete the Cut operation !"];
                [alert addButtonWithTitle:@"OK"];
                [alert setInformativeText:@"Another application changed the System Clipboard."];
                [alert beginSheetModalForWindow:[self myWindow] completionHandler:nil];
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
    // Checking first if the operation is not blocked.
    if ([self checkAppInDuplicateBlocking]==NO) return;

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

-(IBAction)contextualAction:(id)sender {
    NSLog(@"menu Action");
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

-(IBAction)contextualOpenWith:(id)sender {
    NSArray *selectedFiles = [[self contextualFocus] getSelectedItemsForContextualMenu2];
    NSURL *app = [sender representedObject];
    for (TreeItem *item in selectedFiles) {
        [[NSWorkspace sharedWorkspace] openFile:[item path] withApplication:[app lastPathComponent]];
    }
}


- (IBAction)toolbarNewFolder:(id)sender {
    NSArray *selectedItems = [[self selectedView] getSelectedItems];
    NSInteger selectionCount = [selectedItems count];
    if (selectionCount!=0) {
        // TODO:1.5 Ask whether to move the files into the new created Folder
    }
    id node = [[self selectedView] treeNodeSelected];
    if ([node isKindOfClass:[TreeBranch class]]) {
        [self executeNewFolder: node];
    }
    else {
        NSLog(@"AppDelegate.toolbarNewFolder: Received wrong object. Expected TreeBranch received %@", [node className]);
    }
}

- (IBAction)contextualNewFolder:(id)sender {
    // The last item is forcefully a Branch since it was checked in the validateUserIterfaceItem
    [self executeNewFolder:(TreeBranch*)[[self selectedView] getLastClickedItem]];
}

- (IBAction)toolbarRefresh:(id)sender {
    [self refreshAllViews:nil];
}

- (IBAction)toolbarGotoFolder:(id)sender {
    [self executeOpenFolderInView:[self selectedView] withTitle:@"Select a Folder"];
}

- (IBAction)contextualGotoFolder:(id)sender {
    [self executeOpenFolderInView:sender withTitle:@"Select a Folder"];
}

- (IBAction) contextualAddFavorite:(id)sender {
    NSArray *itemsSelected = [[self contextualFocus] getSelectedItemsForContextualMenu1];
    
    if ([itemsSelected count]==1) {
        NSArray *currentFavorites = [[NSUserDefaults standardUserDefaults] arrayForKey:USER_DEF_FAVORITES];
        NSString *pathToAdd = [(TreeItem*)[itemsSelected firstObject] path];
        
        NSArray *newArray;
        if (currentFavorites==nil) {
            newArray = [NSArray arrayWithObject:pathToAdd];
            [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:USER_DEF_FAVORITES];
        }
        else {
            // Only if is not inserted yet
            if (![currentFavorites containsObject:pathToAdd]) {
                NSArray *newArray = [currentFavorites arrayByAddingObject:pathToAdd];
                [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:USER_DEF_FAVORITES];
            }
        }
    }
}


- (IBAction)toolbarSearch:(id)sender {
    // TODO:1.5 Search Mode : Similar files Same Size, Same Kind, Same Date, ..., or Directory Search
    //- (BOOL)showSearchResultsForQueryString:(NSString *)queryString
}

- (IBAction)toolbarHome:(id)sender {
    if ([sender isKindOfClass:[BrowserController class]]) {
        [self goHome:[self selectedView]];
        [(BrowserController*)[self selectedView] selectFirstRoot];
        [(BrowserController*)[self selectedView] refresh];
    }
}

-(void) setDisplayFunctionKeys:(BOOL)setting {
    CGFloat constant;
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
    [[self myWindowView] setNeedsDisplay:YES];
    // Reposition the value in the user defaults
}

-(void) setDisplaySideBar:(BOOL)setting {
    if (setting) {
        // Sidebar is visible
        NSInteger width = [[NSUserDefaults standardUserDefaults] integerForKey:USER_DEF_LEFT_PANEL_SIZE];
        [self.ContentSplitView setPosition:width ofDividerAtIndex:0];
    }
    else {
        // Save width in preferences @"TreeWidth"
        NSInteger width = NSWidth([(NSView*)[[self.ContentSplitView subviews] objectAtIndex:0] bounds]);
        [[NSUserDefaults standardUserDefaults] setInteger:width forKey:USER_DEF_LEFT_PANEL_SIZE];
        [self.ContentSplitView setPosition:0 ofDividerAtIndex:0];
    }
    [self.ContentSplitView setNeedsDisplay:YES];
    [self.myWindowView displayIfNeeded];
}

- (IBAction)toolbarToggleFunctionKeys:(id)sender { // TODO:??? Replace this with bindings to User Defaults
    NSInteger selectedSegment = [sender selectedSegment];
    
    BOOL setting = [sender isSelectedForSegment:selectedSegment];
    
    if (selectedSegment==MAIN_VIEW_OPTION_VISIBLE_FUNCTIONS) { // The Function Keys
        [self setDisplayFunctionKeys:setting];
        [[NSUserDefaults standardUserDefaults] setBool:setting forKey:USER_DEF_APP_DISPLAY_FUNCTION_BAR];
    }
    if (selectedSegment == MAIN_VIEW_OPTION_VISIBLE_SIDEBAR) {
        [self setDisplaySideBar:setting];
        [[NSUserDefaults standardUserDefaults] setBool:setting forKey:USER_DEF_LEFT_PANEL_VISIBLE];
    }
}


-(IBAction)orderStartupScreen:(id)sender {
    StartupScreenController *startupScreenCtrl = [[StartupScreenController alloc] initWithWindowNibName:@"StartupScreen"];
    [startupScreenCtrl hideDontShowThisAgainButton];
    [NSApp runModalForWindow:startupScreenCtrl.window];
}

- (IBAction)orderWebsite:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.nunobrum.com/roadmap.html"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)orderSendFeedback:(id)sender {
    NSURL *url = [NSURL URLWithString:@"mailto:caravelle@nunobrum.com"];
    // ?subject=Feedback on Caravelle 1v3&body=Hi Nuno,\n\n<put your recommendations or complains here>
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)orderPreferencePanel:(id)sender {
    [userPreferenceManager showWindow:self];
}

- (IBAction)showHelp:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.nunobrum.com/help.html"];
    [[NSWorkspace sharedWorkspace] openURL:url];
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
    id  destinationBranch = [[self selectedView] treeNodeSelected];
    if ([destinationBranch isKindOfClass:[TreeBranch class]]) {
        [self executePaste:destinationBranch];
    }
    else {
        NSLog(@"AppDelegate.paste: Received wrong object. Expected TreeBranch received %@", [destinationBranch className]);
    }
}

- (IBAction)contextualPaste:(id)sender {
    // the validateMenuItems insures that node is Branch
    NSArray *items = [[self contextualFocus] getSelectedItemsForContextualMenu1];
    if ([items count]==1) { // Can only paste on one item. TODO:3.0 In the future can paste to many
        TreeItem *item = [items firstObject];
        // TODO:1.5 need to test if its an application,
        //if ([item isKindOfClass:[TreePackage class]]) {
            // and if it is will simply use it to open the items on the clipboard.

        //}
        if ([item isLeaf]) { // If its a leaf, will use the parent instead
            item = [item parent];
        }
        [self executePaste:(TreeBranch*)item];
    }
    else
        NSLog(@"AppDelegate.contextualPaste: Can't paste in many files");
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

-(void) setApplicationMode:(EnumApplicationMode) newMode {
    [self willChangeValueForKey:BOOL_DUPLICATE_MODE];
    _application_mode = newMode;
    [self didChangeValueForKey:BOOL_DUPLICATE_MODE];
}

-(void) setApplicationModeEnum:(EnumApplicationMode) newMode {
    EnumApplicationMode old_mode = applicationMode;
    [self willChangeValueForKey:BOOL_DUPLICATE_MODE];
    [self willChangeValueForKey:BOOL_ALLOW_DUPLICATE];
    _application_mode = newMode;
    
    if (newMode == ApplicationMode1View) {
        [self makeView1:@"Single" view2:nil];
        [myLeftView setViewMode:BViewBrowserMode];
        self->_selectedView = myLeftView; // Force select to the left side
        [myLeftView refresh];  // Needs to force a refresh since the preferences were updated
    }
    else if (newMode == ApplicationMode2Views) {
        [self makeView1:@"Left" view2:@"Right"];
        [myLeftView  setViewMode:BViewBrowserMode];
        [myRightView setViewMode:BViewBrowserMode];
        [myLeftView  refresh];  // Needs to always refresh the left view since preferences may have changed
        [myRightView refresh];
    }
    else if (newMode == ApplicationModePreview) {
        // TODO:1.4 Preview Mode
        NSLog(@"AppDelegate.appModeChanged: Preview Mode");
        // Now displaying an NSAlert with the information that this will be available in a next version
        NSAlert *notAvailableAlert =  [[NSAlert alloc] init];
        [notAvailableAlert setMessageText:@"Preview Pane"];
        [notAvailableAlert addButtonWithTitle:@"OK"];
        [notAvailableAlert setInformativeText:@"This feature will be implemented in a future version. For more information consult the Caravelle Roadmap.  www.nunobrum.com/roadmap"];
        [notAvailableAlert setAlertStyle:NSInformationalAlertStyle];
        [notAvailableAlert beginSheetModalForWindow:[self myWindow] completionHandler:nil];
        // Reposition last mode
        _application_mode = old_mode;
    }
    else if (newMode == ApplicationModeSync) {
        // TODO:1.4 Sync Mode
        NSLog(@"AppDelegate.appModeChanged: Sync Mode");
        // Now displaying an NSAlert with the information that this will be available in a next version
        NSAlert *notAvailableAlert =  [[NSAlert alloc] init];
        [notAvailableAlert setMessageText:@"Directory Compare & Synchronization"];
        [notAvailableAlert addButtonWithTitle:@"OK"];
        [notAvailableAlert setInformativeText:@"This feature will be implemented in a future version. For more information consult the Caravelle Roadmap.  www.nunobrum.com/roadmap"];
        [notAvailableAlert setAlertStyle:NSInformationalAlertStyle];
        [notAvailableAlert beginSheetModalForWindow:[self myWindow] completionHandler:nil];
        // Reposition last mode
        _application_mode = old_mode;
    }
    else if (newMode == ApplicationModeDupSingle) {
        [myLeftView removeAll];
        [myLeftView refresh];
        [self makeView1:@"DuplicateSingle" view2:nil];
        [myLeftView setViewMode:BViewDuplicateMode];
        [myLeftView setViewType:BViewTypeTable];
        [myLeftView setTreeViewCollapsed:YES];
        // Activate the Flat View
        [myLeftView setDrillDepth:NSIntegerMax];
        // TODO:1.3.3 This should be retrieved from Default Settings
        NSArray *dupColumns = [NSArray arrayWithObjects:@"COL_PATH", @"COL_SIZE", @"COL_DATE_MODIFIED", nil];
        [myLeftView.detailedViewController setupColumns:dupColumns];
        // Group by Location
        [myLeftView.detailedViewController makeGroupingOnFieldID:@"COL_DUP_GROUP" ascending:YES];
        // ___________________________
        // Setting the duplicate Files
        // ---------------------------
        [myLeftView addTreeRoot:duplicateController.unifiedDuplicatesRoot];
        [myLeftView stopBusyAnimations];
        [self focusOnView:myLeftView];
        [myLeftView selectFirstRoot]; // This has to be done at the end since it triggers the statusUpdate:
         self.appInImage = [NSImage imageNamed:@"PRO"];
    }
    else if (newMode == ApplicationModeDupDual) {
        [self makeView1:@"DuplicateMaster" view2:@"DuplicateDetail"];
        
        [myLeftView setViewMode:BViewDuplicateMode];
        [myLeftView setViewType:BViewTypeTable];
        // Activate the Tree View on the Left
        [myLeftView setTreeViewCollapsed:NO];
        // Make the FlatView and Group by Location
        [myLeftView setDrillDepth:NSIntegerMax];
        
        // TODO:1.3.3 This should be retrieved from Default Settings
        NSArray *dupColumns = [NSArray arrayWithObjects:@"COL_DUP_GROUP", @"COL_NAME", @"COL_SIZE", nil];
        [myLeftView.detailedViewController setupColumns:dupColumns];
        [myLeftView.detailedViewController makeGroupingOnFieldID:@"COL_LOCATION" ascending:YES];
        
        [myRightView setViewMode:BViewDuplicateMode];
        [myRightView setViewType:BViewTypeTable];
        // Deactivate the Tree View on the Left
        [myRightView setTreeViewCollapsed:YES]; // This is the default.
        
        [myRightView setDrillDepth:NSIntegerMax];
        [myRightView.detailedViewController setupColumns:dupColumns];
        // Group by Location
        [myRightView.detailedViewController makeGroupingOnFieldID:@"COL_LOCATION" ascending:YES];
        // Activate the Flat View
        
        // ___________________________
        // Setting the duplicate Files
        // ---------------------------
        
        [myLeftView setRoots:duplicateController.rootsWithDuplicates.roots];
        [myLeftView stopBusyAnimations];
        [self focusOnView:myLeftView]; // Changing selected
        [myLeftView selectFirstRoot]; // This has to be done at the end since it triggers the statusUpdate:
         self.appInImage = [NSImage imageNamed:@"PRO"];
    }
    [self.toolbarAppModeSelect setSelectedSegment: segmentForApplicationMode(applicationMode)];
    
    // Undo things that are not needed depending on the old mode
    if (old_mode != applicationMode) {
        if (((old_mode & ApplicationModeDupBrowser) != 0) &&  // Moving out of Duplicate Mode
            (( newMode & ApplicationModeDupBrowser) == 0)) {
            // removing observings on treeManager
            [duplicateController deinit];
        }
    }
    
    // Views that Disable the Icon View
    BOOL iconViewEn = ((applicationMode & ApplicationModeDupBrowser)==0);
    [self.toolbarViewTypeSelect setEnabled:iconViewEn forSegment:BViewTypeIcon];
    [self adjustSideInformation: self.selectedView];
    [self.ContentSplitView displayIfNeeded];
    [self didChangeValueForKey:BOOL_DUPLICATE_MODE]; // This is needed to inform of the change.
    [self didChangeValueForKey:BOOL_ALLOW_DUPLICATE];
}

- (IBAction)viewModeChanged:(id)sender {
    NSInteger segment = [(NSSegmentedControl*)sender selectedSegment];
    EnumApplicationMode newMode = applicationModeForSegment(segment);
    
    if (newMode != applicationMode) {
        [self setApplicationModeEnum:newMode];
    }
}

- (IBAction)viewTypeChanged:(id)sender {
    if ([self.selectedView isKindOfClass:[BrowserController class]]) {
        NSInteger newType = [(NSSegmentedControl*)sender selectedSegment ];
        [(BrowserController*)self.selectedView setViewType:newType];
    }
}


- (IBAction)exitButton:(id)sender {
    if (applicationMode & (ApplicationModeDupBrowser|ApplicationModeDupStarted)) {
        [self exitDuplicateMode];
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
    
    // Actions that are restricted on the operation Mode
    if (applicationMode & ApplicationModeDupBrowser) {
        if (theAction == @selector(toolbarNewFolder:) ||
            theAction == @selector(contextualNewFolder:) ||
            theAction == @selector(paste:) ||
            theAction == @selector(contextualPaste:)) {
            return NO;
        }
        else if (theAction == @selector(toolbarDelete:) ||
                 theAction == @selector(contextualDelete:) ||
                 theAction == @selector(delete:) ||
                 
                 theAction == @selector(toolbarRename:) ||
                 theAction == @selector(contextualRename:) ||
                 
                 theAction == @selector(toolbarMoveTo:) ||
                 theAction == @selector(contextualMoveTo:) ||
                 
                 theAction == @selector(contextualCut:) ||
                 theAction == @selector(cut:)
                 ) {
            if ([userPreferenceManager duplicatesAuthorized]==NO) return NO;
        }
    }

    // Actions that can always be done
    if (theAction == @selector(toolbarHome:) ||
        theAction == @selector(toolbarRefresh:) ||
        theAction == @selector(toolbarSearch:) ||
        theAction == @selector(toolbarGotoFolder:) ||
        theAction == @selector(orderPreferencePanel:)
        ) {
        return YES;
    }

    // Actions that require a contextual selection including the current Node
    if (theAction == @selector(contextualInformation:) ||
        theAction == @selector(contextualNewFolder:) ||
        theAction == @selector(contextualPaste:) ||
        theAction == @selector(contextualAddFavorite:)
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
            else if (theAction == @selector(contextualAddFavorite:)) {
                allow = YES;
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
            // Action that requires a Folder
            else if (theAction == @selector(contextualAddFavorite:)) {
                allow = [item isFolder];
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
                if (![item isFolder]) {
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
                if (![item isFolder]) {
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

#pragma mark - NSSplitViewDelegate methods
#define kMinConstraintValue 100.0f
#define kMaxConstraintValue 350.0f

// -------------------------------------------------------------------------------
//	awakeFromNib:
//
//	This delegate allows the collapsing of the first and last subview.
// -------------------------------------------------------------------------------
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    BOOL canCollapseSubview = NO;
    
    NSArray *splitViewSubviews = [splitView subviews];
    if  (splitViewSubviews != nil && [splitViewSubviews count]>0)
    {
        if ((splitView == self.ContentSplitView) && (subview == [splitViewSubviews objectAtIndex:0]))
        {
            canCollapseSubview = YES; //[self.toolbarFunctionBarSelect isSelectedForSegment:MAIN_VIEW_OPTION_VISIBLE_SIDEBAR] == NO;
        }
    }
    return canCollapseSubview;
}

// -------------------------------------------------------------------------------
//	shouldCollapseSubview:subView:dividerIndex
//
//	This delegate allows the collapsing of the first and last subview.
// -------------------------------------------------------------------------------
- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
    // yes, if you can collapse you should collapse it
    if (splitView == self.ContentSplitView) {
        return YES;
    }
    return NO;
}

// -------------------------------------------------------------------------------
//	constrainMinCoordinate:proposedCoordinate:index
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(NSInteger)index
{
    CGFloat constrainedCoordinate = proposedCoordinate;
    if ((splitView == self.ContentSplitView) && (index == 0))
    {
        constrainedCoordinate = proposedCoordinate + kMinConstraintValue;
    }
    //NSLog(@"constrainMinCoordinate: Index: %ld proposed %f MinCoordinate: %f", (long)index, proposedCoordinate, constrainedCoordinate);
    return constrainedCoordinate;
}

// -------------------------------------------------------------------------------
//	constrainMaxCoordinate:proposedCoordinate:proposedCoordinate:index
// -------------------------------------------------------------------------------

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(NSInteger)index
{
    CGFloat constrainedCoordinate = proposedCoordinate;
    if ((splitView == self.ContentSplitView) && (index == 0)) {
        if (proposedCoordinate < 0) { // Happens at startup
            //constrainedCoordinate = [[NSUserDefaults standardUserDefaults] integerForKey:USER_DEF_LEFT_PANEL_SIZE];
            constrainedCoordinate = proposedCoordinate;
        }
        else {
            //CGFloat detailedWidth = [[[splitView subviews] objectAtIndex:0] frame].size.width;
            constrainedCoordinate = kMaxConstraintValue;
        }
    }
    //NSLog(@"constrainMaxCoordinate: Index: %ld proposed: %f MaxCoordinate: %f", (long)index, proposedCoordinate, constrainedCoordinate);
    return constrainedCoordinate;
}

- (BOOL)splitMView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    NSLog(@"AppDelegate.shouldAdjustSizeOfSubview");
    if (subview == [[self.ContentSplitView subviews] objectAtIndex:0]) {
        return NO;
    }
    return YES;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
    // Use this notfication to set the select state of the button
    NSSplitView *splitView = [aNotification object];
    NSArray *subViews = [splitView subviews];
    if  (subViews != nil && [subViews count]>0)
    {
        if (splitView == self.ContentSplitView) {
            BOOL sideCollapsed = [self.ContentSplitView isSubviewCollapsed: [subViews objectAtIndex:0]] ;
            [self.toolbarFunctionBarSelect setSelected:!sideCollapsed forSegment:MAIN_VIEW_OPTION_VISIBLE_SIDEBAR];
            //NSLog(@"splitViewDidResizeSubviews colapsed:%hhd", sideCollapsed);

        }
    }
}


#pragma mark - Parent Protocol

- (void)focusOnNextView:(id)sender {
    id<MYViewProtocol> focused_view;
    if (sender == myLeftView) {
        if (applicationMode &
            (ApplicationMode2Views |
             ApplicationModePreview )) {
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
        if (applicationMode &
            (ApplicationMode2Views |
             ApplicationModePreview)) {
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

-(void) focusOnView:(BrowserController*)view {
    _selectedView = view;
    [view focusOnFirstView];
    [self adjustSideInformation:view];
}


#pragma mark - Operations Handling
/* Called for the notificationDoFileOperation notification 
 This routine is called by the views to initiate opeations, such as 
 the case of the edit of the file name or the drag/drop operations */
-(void) startOperationHandler: (NSNotification*) note {

    NSString *operation = [[note userInfo] objectForKey:kDFOOperationKey];
    if ([operation isEqualTo:opChangeMode]) {
        // message that probably came from the side bar. Will need to switch mode.
        // at this time I know that it must be from Duplicate Finder Mode.
        // Later this may come from other modes. At that point will have to
        // add another parameter to the dictionary to inform what mode to target
        [self setBoolDuplicateModeActive:@0];
        operation = (NSString*)opOpenOperation; // This will make the folder to open
    }
    
    if ([operation isEqualTo:opOpenOperation]) {
        NSArray *receivedItems = [[note userInfo] objectForKey:kDFOFilesKey];
        BOOL oneFolder=YES;
        for (TreeItem *node in receivedItems) {
            /* Do something here */
            if ([node isLeaf]) { // It is a file : Open the File
                [node openFile]; // TODO:1.4 Register this folder as one of the MRU
            }
            else if ([node isFolder] && oneFolder==YES) { // It is a directory
                // Going to open the Select That directory on the Outline View
                /* This also sets the node for Table Display and path bar */
                
                TreeItem *root = [[(BrowserController*)self.selectedView baseDirectories] getRootWithNode:node];
                if (root) {
                    // the folder already exist so, only needs to be selected
                    [(BrowserController*)self.selectedView selectFolderByItem:node]; // URL is preferred so that the climb to parent folder works
                }
                else {
                    // It does not exist on the Outline View, will get the folder from the TreeManager
                    TreeItem *root = [appTreeManager addTreeItemWithURL:node.url askIfNeeded:YES];
                    if (root!=nil) {
                        [(BrowserController*)self.selectedView setRoots:[NSArray arrayWithObject:root]];
                        [(BrowserController*)self.selectedView selectFirstRoot];
                    }
                }
                oneFolder = NO; /* Only the first Folder will be Opened */
            }
            else
                NSLog(@"AppDelegate.startOperationHandler: - Unknown Class '%@'", [node className]);

        }
        [self statusUpdate:note]; // Forwards the message to the status update so that status can be updated in open
    }
    else if ([operation isEqualTo:opFlatOperation]) {
        ExpandFolders * op = [[ExpandFolders alloc] initWithInfo:[note userInfo]];
        //[op setQueuePriority:NSOperationQueuePriorityNormal];
        //[op setQualityOfService:NSQualityOfServiceBackground]; //This is now handled on the
        [self _startOperationBusyIndication: op];
        putInQueue(op);
    }
    else {
        // All others are redirected all to file operation
        [self startFileOperation:[note userInfo]];
    }
}

-(void) _startOperationBusyIndication:(AppOperation*) appOperation {
    // Displays the first status message
    NSString *operationStatus = [appOperation statusText];
    
    //NSLog(operationStatus);
    [self.statusProgressIndicator setHidden:NO];
    [self.statusProgressIndicator startAnimation:self];
    [self.statusProgressLabel setHidden:NO];
    if (operationStatus==nil)  {
        [self.statusProgressLabel setTextColor:[NSColor redColor]];
        [self.statusProgressLabel setStringValue: @"Internal Error"];
    }
    else {
        [self.statusProgressLabel setTextColor:[NSColor blueColor]];
        [self.statusProgressLabel setStringValue: operationStatus];
    }
    [self.statusCancelButton setHidden:NO];
    statusTimeoutCounter = 0;
    _operationInfoTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_operationsInfoFired:) userInfo:nil repeats:YES];
    
}

- (void)_operationsInfoFired:(NSTimer *)timer {
    if ([operationsQueue operationCount]==0) {

        if ([pendingStatusMessages count]>=1) { // This was called from the notifications finished, and there is only one message pending
            // Make Status Update here
            
            NSDictionary *info = [pendingStatusMessages firstObject];
            [pendingStatusMessages removeObjectAtIndex:0];
            //NSUInteger num_files = [[info objectForKey:kDFOFilesKey] count];
            
            BOOL OK = [[info objectForKey:kDFOOkKey] boolValue];
            NSString *statusText = [info objectForKey:kDFOStatusKey];

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
        NSArray *operations = [operationsQueue operations];
        NSOperation *currOperation = operations[0];
        NSString *status = [(AppOperation*)currOperation statusText];
        
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
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Error creating Folder" ];
            [alert addButtonWithTitle:@"OK"];
            [alert setInformativeText:@"Possible Causes:\nFile already exists or write is restricted"];
            [alert beginSheetModalForWindow:[self myWindow] completionHandler:nil];
        }
        else if ([operation isEqualTo:opFlatOperation]) {
            // Cancel the Flat View
            BrowserController *selView = [info objectForKey:kDFOFromViewKey];
            [selView setDrillDepth:0];
            [selView refresh];
        }
        else {
            TreeBranch *dest = [info objectForKey:kDFODestinationKey];
            if (dest) {// a URL arrived here in one of the tests. Placing here an assertion to trap it if it happens again
                NSAssert([dest isKindOfClass:[TreeBranch class]], @"ERROR. Received an object that isn't a TreeBranch");
                [dest setTag:tagTreeItemDirty];
                [dest refresh];
            }
            NSError *error = [info objectForKey:kDFOErrorKey];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError:error];
                if (alert) {
                    // TODO:1.3.3 extend this to consider the "Ignore" and "Continue" buttons
                    //[alert addButtonWithTitle:@"Stop"];
                    //[alert addButtonWithTitle:@"Abort"];
                    //[alert addButtonWithTitle:@"Continue"];
                    NSString *infoMessage = [alert informativeText];
                    NSString *message = [alert messageText];
                    NSLog(@"AppDelegate.mainThread_operationFinished: ERROR: %@ Information: %@", message, infoMessage);
                    [alert beginSheetModalForWindow:[self myWindow] completionHandler:^(NSModalResponse returnCode) {
                        //NSLog(@"Alert return code :%ld", (long)returnCode);
                    }];
                }
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
    [self statusUpdate:theNotification];
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
        case ApplicationModeDupSingle:
        case ApplicationModeDupDual:
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

    if (applicationMode == ApplicationModeDupDual) {
        id selView = [theNotification object];
        //Check first if the object sending the
        if (selView==nil) { // Sent by Operation Finished
            // Tries to retrieve the object from "FromObjectKey"
            selView = [[theNotification userInfo] objectForKey:kDFOFromViewKey];
            if (selView==nil || NO==[selView isKindOfClass:[BrowserController class]]) {
                //Defaults to the selectedView
                selView = self.selectedView;
            }
        }
        if (selView==myLeftView || selView ==myLeftView.detailedViewController) {
            selectedFiles = [selView getSelectedItems];
            dupShow++;
            
            /* will now populate the Right View with Duplicates*/
            [myRightView removeAll];
            [myRightView refresh];
            [myRightView startAllBusyAnimations];
            
            FileCollection *collectedDuplicates = [FileCollection duplicatesOfFiles:selectedFiles dCounter:dupShow];
            
            if ([myRightView treeViewCollapsed]) {
                /* Whether it will present one flat view */
                TreeRoot *selectedDuplicatesRoot = [[TreeRoot alloc] init];
                [selectedDuplicatesRoot setName:@"Duplicates"];
                [selectedDuplicatesRoot setFileCollection:collectedDuplicates];
                [myRightView setRoots:[NSArray arrayWithObject:selectedDuplicatesRoot]];
            }
            else {
                /* Whether it will present a treeView */
                for (TreeBranch *r in duplicateController.rootsWithDuplicates.roots) {
                    [myRightView addTreeRoot:[[TreeBranchCatalyst alloc] initWithURL:r.url parent:nil]];
                }
                [myRightView addFileCollection: collectedDuplicates];
            }
            [myRightView selectFirstRoot];
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
            statusText = @"No Files Selected";
        }
        else if ([selectedFiles count] == 1) {
            TreeItem *item = [selectedFiles objectAtIndex:0];
            NSNumber *nsize = [item exactSize];
            NSString *sizeText = @"";
            if (nsize != nil) {
                long long size = [nsize longLongValue];
                if (size != -1) {
                    sizeText = [NSString stringWithFormat: @" Size:%@",[NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile]];
                }
            }
            NSString *type;
            ItemType iType = [item itemType];
            if (iType >= ItemTypeLeaf) {
                type = @"File";
            }
            else if (iType < ItemTypeLeaf){ // It's a folder
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
                NSNumber *nssize = item.exactSize;
                long long int lsize = [nssize longLongValue];
                if ([item isLeaf]) {
                    num_files++;
                    files_size += lsize;
                }
                else if ([item isFolder]) {
                    num_directories++;
                    folders_size += lsize;
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
        [_StatusBar setTitle: @"No File Selected"];
    }

}


#pragma mark Find Duplicates

/*
 * methods for Interface Binding
 */

-(NSNumber*) boolDuplicateModeActive {
    return [NSNumber numberWithBool:(applicationMode & (ApplicationModeDupBrowser))];
}

-(void) setBoolDuplicateModeActive:(NSNumber*) mode {
    if ([mode boolValue]) {
        // Going to Duplicate Mode
        if (duplicateSettingsWindow==nil)
            duplicateSettingsWindow =[[DuplicateFindSettingsViewController alloc] initWithWindowNibName:@"DuplicatesFindSettings"];
        
        // Setting the current node in the list
        NSString *leftpath = [myLeftView homePath];
        if (leftpath) {
            NSMutableArray *selectedNodes;
            selectedNodes = [NSMutableArray arrayWithObject:leftpath]; // Prefering this form since the url can be nil
            
            if (applicationMode == ApplicationMode2Views) {
                NSString *rightpath = [myRightView homePath];
                if (rightpath!=nil && path_relation([myLeftView homePath],rightpath) == pathsHaveNoRelation)
                    [selectedNodes addObject:rightpath];
            }
            [duplicateSettingsWindow showWindow:self];
            [self->duplicateSettingsWindow setPaths:selectedNodes];
        }
        [self setApplicationMode: (applicationMode|ApplicationModeDupStarted)];
    }
    else {
        // Already in Duplicate Mode, resume to Browser Mode
        [self exitDuplicateMode];
    }
}

-(NSNumber*) boolAllowDelete {
    return [NSNumber numberWithBool: ! (((applicationMode & ApplicationModeDupBrowser)!=0) && ([userPreferenceManager duplicatesAuthorized]==NO))];
}

/* invoked by Find Duplicates Dialog on OK Button */
- (void) startDuplicateFind:(NSNotification*)theNotification {
    // First check if is not a cancel
    // If there isn't an UserInfo Dictionary then its a cancel
    NSDictionary *notifInfo = [theNotification userInfo];
    if (notifInfo==nil) {
        // Reverts back to the previous view . Nothing is changed
        [self.toolbarAppModeSelect setSelected:YES forSegment:segmentForApplicationMode(applicationMode)];
    }
    else {
        
        NSDictionary *notifInfo = [theNotification userInfo];
        duplicateController = [[DuplicateDelegate alloc] initWithInfo:notifInfo app:self];
        
        // start the GetPathsOperation with the root path to start the search
        DuplicateFindOperation *dupFindOp = [[DuplicateFindOperation alloc] initWithInfo:notifInfo];
        [operationsQueue addOperation:dupFindOp];	// this will start the "GetPathsOperation"
        [self _startOperationBusyIndication:dupFindOp];
        
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

-(void) exitDuplicateMode {
    if (applicationMode & ApplicationModeDupStarted) {
        // Close the Start Window
        [self closeDuplicatesStartUpWindow];
        
        // Close the settings window
        if (self->duplicateSettingsWindow) {
            [self->duplicateSettingsWindow close];
        }
        
        // Cancel Operation
        for (NSOperation *op in [operationsQueue operations]) {
            if ([op isKindOfClass:[DuplicateFindOperation class]]) {
                [op cancel];
            }
        }
    }
    if (applicationMode & ApplicationModeDupBrowser) {
        EnumApplicationMode newMode;
        switch (applicationMode) {
            case ApplicationModeDupDual:
                newMode = ApplicationMode2Views;
                break;
            case ApplicationModeDupSingle:
                newMode = ApplicationMode1View;
                break;
            default:
                newMode = applicationMode;
        }
        self.appInImage = nil;
        [self setApplicationModeEnum:newMode];
        [self goHome:myLeftView];
        if (myRightView)
            [self goHome:myRightView];
        
    }
}

- (void) mainThread_duplicateFindFinish:(NSNotification*)theNotification {
    BOOL use_classic_view = NO;
    NSDictionary *info = [theNotification userInfo];
    BOOL OK = [[info objectForKey:kDFOOkKey] boolValue];
    
    NSArray *duplicatedFileArray = [info objectForKey:kDuplicateList];
    
    [self setApplicationMode: (applicationMode & (~ApplicationModeDupStarted))];
    
    // Check if operation was not aborted
    if (!OK || ([duplicatedFileArray count]==0)) {
        // Reverts back to the previous view . Nothing is changed
        [self.toolbarAppModeSelect setSelected:YES forSegment:segmentForApplicationMode(applicationMode)];
        [myLeftView stopBusyAnimations];
        [myRightView stopBusyAnimations];
        
        if (OK) { // The operation was not cancelled.
            // closing the window if it was opened
            if (self->duplicateStartupScreenCtrl!=nil) {
                [self->duplicateStartupScreenCtrl setWarningMessage:@"No duplicate files were found. Auto closing..."];
                [self performSelector:@selector(closeDuplicatesStartUpWindow) withObject:nil afterDelay:5.0];
            }
            else {
                // Display information that no duplicates were found
                // Inform User
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Congratulations !"];
                [alert addButtonWithTitle:@"OK"];
                [alert setInformativeText:@"No duplicate files were found"];
                [alert setAlertStyle:NSInformationalAlertStyle];
                [alert beginSheetModalForWindow:[self myWindow] completionHandler:nil];
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
    [self savePreferences]; // Saving preferences so that the views are correctly recovered
    
    // Set the Duplicate Controller that will monitor the updates.
    [duplicateController setDuplicateInfo:info];

    
    // ___________________________________
    // Prepare the view for Duplicate View
    // -----------------------------------
    if (use_classic_view) {
        [self setApplicationModeEnum:ApplicationModeDupSingle];
    }
    else {
        [self setApplicationModeEnum:ApplicationModeDupDual];
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
        //TODO:2.0 This can be dangerous with Localizations
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
            id destination =nil;
            NSURL *destURL = [destinationURL URLByDeletingLastPathComponent];
            if (destURL!=nil) {
                TreeItem *destinationItem = [appTreeManager getNodeWithURL:destURL];
                if (destinationItem!=nil) {
                    destination = destinationItem;
                }
                else {
                    destination = destURL;
                }
            }
            NSAssert(destination!=nil, @"AppDelegate.processNextError: Oops Something funky here. The destination is nil");
            NSArray *items = [NSArray arrayWithObject:sourceURL];
            NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      op, kDFOOperationKey,
                                      items, kDFOFilesKey,
                                      destination, kDFODestinationKey,
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
                // If the paths are the same, i.e. the same file, just offer to rename
                // TODO:!!!! This needs to be moved out of here. This is just an informative window. It can be shown when the problem happens. Can bypass the error processing queue.
                if ([sourceItem relationTo: destItem]==pathIsSame) {
                    NSAlert *alert = [[NSAlert alloc] init ];
                    [alert setMessageText:@"Ooops!"];
                    [alert addButtonWithTitle:@"OK"];
                    [alert setInformativeText:@"Target and selected file is the same. Ignoring command"];
                    [alert setAlertStyle:NSInformationalAlertStyle];
                    [alert beginSheetModalForWindow:[self myWindow] completionHandler:nil];
                    [pendingOperationErrors removeObjectAtIndex:0];
                }
                else {
                    if (fileExistsWindow==nil) {
                        fileExistsWindow = [[FileExistsChoice alloc] initWithWindowNibName:@"FileExistsChoice"];
                        [fileExistsWindow loadWindow]; //This is needed to load the window
                    }
                    BOOL OK = [fileExistsWindow makeTableWithSource:sourceItem andDestination:destItem];
                    if (OK) {
                        [fileExistsWindow displayWindow:self];
                    }
                }
            }
            else {
                // Failed to created either the source or the destination. Not likely to happen but...
                // Messagebox with alert
                NSAlert *alert = [[NSAlert alloc] init ];
                [alert setMessageText:@"Can't complete the operation !"];
                [alert addButtonWithTitle:@"OK"];
                [alert setInformativeText:@"Failed to allocate memory."];
                [alert beginSheetModalForWindow:[self myWindow] completionHandler:nil];
                
            }
        }
        else {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert beginSheetModalForWindow:[self myWindow] completionHandler:^(NSModalResponse returnCode) {
                
            }];

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
    // TODO:? Only add errors that can be treated.
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

- (BOOL)fileManager:(NSFileManager *)fileManager
shouldCopyItemAtURL:(NSURL *)srcURL
              toURL:(NSURL *)dstURL {
    enumPathCompare comp = url_relation(srcURL, dstURL);
    if (comp==pathIsParent || comp == pathIsChild) {
        // If the path is contained or contains the operation cannot be completed
        //TODO:1.5 create an error subclass
        return NO;
    }
    //NSLog(@"should copy item\n%@ to\n%@", srcURL, dstURL);
    return YES;
}

- (BOOL)fileManager:(NSFileManager *)fileManager
shouldMoveItemAtURL:(NSURL *)srcURL
              toURL:(NSURL *)dstURL {
    enumPathCompare comp = url_relation(srcURL, dstURL);
    if (comp==pathIsParent || comp == pathIsChild) {
        // If the path is contained or contains the operation cannot be completed
        //TODO:1.5 create an error subclass
        return NO;
    }
    //NSLog(@"should move item\n%@ to\n%@", srcURL, dstURL);
    return YES;
}

-(BOOL) fileManager:(NSFileManager *)fileManager
shouldRemoveItemAtURL:(NSURL *)URL {
    //NSLog(@"should remove item\n%@", URL);
    return YES;
}

@end
