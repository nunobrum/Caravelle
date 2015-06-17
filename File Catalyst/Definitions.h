//
//  Definitions.h
//  File Catalyst
//
//  Created by Nuno Brum on 04/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#ifndef File_Catalyst_Definitions_h
#define File_Catalyst_Definitions_h


/* Used for Drag&Drop notifications */
extern NSString *notificationDoFileOperation;
extern NSString *kDFOOperationKey;
extern NSString *kDFODestinationKey;
extern NSString *kDFORenameFileKey;
/* Used for Both Drag&Drop and for Status Notifications */
extern NSString *kDFOFilesKey;

extern NSString *kDFOErrorKey;
extern NSString *kDFOOkKey;
extern NSString *kDFOOkCountKey;
extern NSString *kDFOStatusCountKey;

//extern NSString *kFromObjectKey;

extern NSString *opOpenOperation;
extern NSString *opCopyOperation;
extern NSString *opMoveOperation;
extern NSString *opEraseOperation;
extern NSString *opReplaceOperation;
extern NSString *opNewFolder;
extern NSString *opRename;
extern NSString *opSendRecycleBinOperation;

extern NSString *notificationStatusUpdate;

//#define USE_UTI
#ifdef USE_UTI
/*Used for the internal Pasteboard*/
extern const CFStringRef kTreeItemDropUTI;
#define OwnUTITypes  (__bridge id)kTreeItemDropUTI,
#else
#define OwnUTITypes
#endif


#define APP_IS_SANDBOXED 1

#if (APP_IS_SANDBOXED==1)

#define AFTER_POWERBOX_INFORMATION 1

#endif

#define USE_TREEITEM_PASTEBOARD_WRITING // Controls how paste to board is done

// Table Column Identifier for File Name
#define COL_FILENAME @"COL_NAME"


//#define COL_ID_KEY @"ID"
#define COL_ACCESSOR_KEY @"accessor"
#define COL_TITLE_KEY @"title"
#define COL_TRANS_KEY @"transformer" 
#define COL_GROUPING_KEY @"grouping"


// User Definitions
#define USER_DEF_LEFT_HOME @"BrowserLeftHomeDir"
#define USER_DEF_RIGHT_HOME @"BrowserRightHomeDir"
#define USER_DEF_STORE_BOOKMARKS @"StoreAllowedURLs"
#define USER_DEF_SECURITY_BOOKMARKS @"SecurityScopeBookmarks"
#define USER_DEF_BROWSE_APPS @"BrowseAppsAsFolder"
#define USER_DEF_SEE_HIDDEN_FILES @"BrowseHiddenFiles"
#define USER_DEF_MRU_COUNT @"MostRecentLocationCount" // TODO: !!! This is not being used.
#define USER_DEF_APP_BEHAVOUR @"ApplicationBehaviour"
#define USER_DEF_APP_VIEW_MODE @"ApplicationViewMode"
#define USER_DEF_APP_DISPLAY_FUNCTION_BAR @"DisplayFunctionBar"
#define USER_DEF_CALCULATE_SIZES @"CalculateFolderSizes"

#define USER_DEF_PANEL_VIEW_TYPE @"ViewType"

#define SHOW_OPTION_HIDDEN_FILES_NO  0
#define SHOW_OPTION_BROWSE_APP_NO   1
#define SHOW_OPTION_FLAT_TREE_NO    2

// These following definitions should be set accordingly to the Radio Buttons
// on the behaviour panel on the User Preferences dialog.
#define APP_BEHAVIOUR_NATIVE        0
#define APP_BEHAVIOUR_MULTIPLATFORM 1


// Used to check where is the focus of the window for the contextual selection
// This is a terrible workaround because I didn't find a clear and neat way
// to get the window focus. The cocoa base classes only work with Windows and do not
// seem to work with Views.
// -2 to differentiate from the -1 Not found.
#define BROWSER_TABLE_VIEW_INVALIDATED_ROW -2


#define BROWSER_VIEW_OPTION_TREE_ENABLE  0
#define BROWSER_VIEW_OPTION_FLAT_SUBDIRS 1

// Animation delay Time in seconds
#define ANIMATION_DELAY 0.5 // set to 500ms of delay

extern NSFileManager *appFileManager;
extern NSOperationQueue *operationsQueue;
extern NSOperationQueue *browserQueue;
extern NSOperationQueue *lowPriorityQueue;

extern id appTreeManager;

typedef NS_ENUM(NSInteger, BViewType) { // Needs to be synchronized with the BrowserView segmentedButton
    BViewTypeInvalid = -2,
    BViewTypeVoid = -1,
    BViewTypeIcon = 0,
    BViewTypeTable = 1,
    BViewTypeBrowser = 2
};

typedef NS_ENUM(NSInteger, BViewMode) {
    BViewModeVoid = 0,
    BViewBrowserMode = 1,
    BViewCatalystMode,
    BViewDuplicateMode
};


typedef NS_ENUM(NSInteger, ApplicationwMode) {
    ApplicationMode1View = 0,
    ApplicationMode2Views, /* Each View is independent of the other */
    ApplicationModePreview,
    ApplicationModeDuplicate,

};

typedef NS_OPTIONS(NSUInteger, DuplicateOptions) {
    DupCompareNone         = 0,
    DupCompareName         = 1 << 0,
    DupCompareSize         = 1 << 1,
    DupCompareDateAdded    = 1 << 2,
    DupCompareDateCreated  = 1 << 3,
    DupCompareDateModified = 1 << 4,
    DupCompareContentsFull = 1 << 5,
    DupCompareContentsMD5  = 1 << 6
};

typedef NS_ENUM(unichar, CommandKeys) {
    KeyCodeUp = 63232,
    KeyCodeDown,
    KeyCodeLeft,
    KeyCodeRight
};
extern NSString *kOptionsKey;

BOOL toggleMenuState(NSMenuItem *menui); // Defined in AppDelegate

@protocol MYViewProtocol <NSObject>

-(NSString*) title;

// Service Handling needs to be forwarded to the delegate for the contextual menus

- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType;

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types;

- (void) refresh;


-(void) focusOnFirstView;
-(void) focusOnLastView;
- (NSView*) focusedView;

@end

@protocol ParentProtocol <NSObject>

- (void) focusOnNextView:(id)sender;
- (void) focusOnPreviousView:(id)sender;
- (void) updateFocus:(id)sender;
- (void) contextualFocus:(id)sender;
- (void) updateStatus:(NSDictionary*)status;

@end

#endif
