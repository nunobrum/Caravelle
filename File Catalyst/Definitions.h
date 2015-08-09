//
//  Definitions.h
//  File Catalyst
//
//  Created by Nuno Brum on 04/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#ifndef _Definitions_h
#define _Definitions_h


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
extern NSString *kDFOFromViewKey;

extern NSString const *opOpenOperation;
extern NSString const *opCopyOperation;
extern NSString const *opMoveOperation;
extern NSString const *opEraseOperation;
extern NSString const *opReplaceOperation;
extern NSString const *opNewFolder;
extern NSString const *opRename;
extern NSString const *opSendRecycleBinOperation;
extern NSString const *opDuplicateFind;
extern NSString const *opFlatOperation;

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

#define AFTER_POWERBOX_INFORMATION 0
#define BEFORE_POWERBOX_ALERT 1
#else

#define AFTER_POWERBOX_INFORMATION 0
#define BEFORE_POWERBOX_ALERT 0

#endif

#define USE_TREEITEM_PASTEBOARD_WRITING // Controls how paste to board is done


//#define COL_ID_KEY @"ID"
#define COL_ACCESSOR_KEY @"accessor"
#define COL_TITLE_KEY @"title"
#define COL_TRANS_KEY @"transformer" 
#define COL_GROUPING_KEY @"grouping"
#define COL_COL_ID_KEY @"col_id"


// User Definitions
#define USER_DEF_DONT_START_SCREEN @"DontDisplayStartScreen"
#define USER_DEF_DONT_START_DUP_SCREEN @"DontDisplayDupStartScreen"

#define USER_DEF_LEFT_HOME @"BrowserLeftHomeDir"
#define USER_DEF_RIGHT_HOME @"BrowserRightHomeDir"
#define USER_DEF_STORE_BOOKMARKS @"StoreAllowedURLs"
#define USER_DEF_SECURITY_BOOKMARKS @"SecurityScopeBookmarks"
#define USER_DEF_MRU_COUNT @"MostRecentLocationCount" // TODO: !!! This is not being used.
#define USER_DEF_APP_BEHAVIOUR @"ApplicationBehaviour"
#define USER_DEF_APP_VIEW_MODE @"ApplicationViewMode"
#define USER_DEF_APP_DISPLAY_FUNCTION_BAR @"DisplayFunctionBar"

// View Preferences
#define USER_DEF_PANEL_VIEW_TYPE @"ViewType"
#define USER_DEF_TABLE_VIEW_COLUMNS @"TableColumns"
#define USER_DEF_TREE_VISIBLE @"TreeVisible"
#define USER_DEF_TREE_WIDTH   @"TreeWidth"
#define USER_DEF_SORT_KEYS    @"SortKeys"

#define USER_DEF_DUPLICATE_CLASSIC_VIEW @"DuplicateClassicView"

 // Browser Options
#define USER_DEF_BROWSE_APPS @"BrowseAppsAsFolder"
#define USER_DEF_SEE_HIDDEN_FILES @"BrowseHiddenFiles"
#define USER_DEF_CALCULATE_SIZES @"CalculateFolderSizes"
#define USER_DEF_DISPLAY_PARENT_DIRECTORY @"DisplayParentDirectory"
#define USER_DEF_HIDE_FOLDERS_WHEN_TREE @"HideFoldersWhenTreeDisplayed"
#define USER_DEF_DISPLAY_FOLDERS_FIRST @"DisplayFoldersFirst"
#define USER_DEF_TABLE_ALTERNATE_ROW @"TableAlternateRowBackground"


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


typedef NS_ENUM(NSInteger, EnumBrowserViewType) { // Needs to be synchronized with the BrowserView segmentedButton
    BViewTypeInvalid = -2,
    BViewTypeVoid = -1,
    BViewTypeIcon = 0,
    BViewTypeTable = 1,
    BViewTypeBrowser = 2
};

typedef NS_ENUM(NSInteger, EnumBrowserViewMode) {
    BViewModeVoid = 0,
    BViewBrowserMode = 1,
    BViewCatalystMode,
    BViewDuplicateMode
};


typedef NS_ENUM(NSInteger, EnumApplicationMode) {
    ApplicationMode1View = 0,
    ApplicationMode2Views, /* Each View is independent of the other */
    ApplicationModePreview,
    ApplicationModeSync,
    ApplicationModeDuplicate,

};

typedef NS_OPTIONS(NSUInteger, EnumDuplicateOptions) {
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

extern NSFileManager *appFileManager;
extern NSOperationQueue *operationsQueue;
extern NSOperationQueue *browserQueue;
extern NSOperationQueue *lowPriorityQueue;
extern EnumApplicationMode applicationMode;


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
