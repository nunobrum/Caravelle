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
extern NSString *kSourceViewKey;


extern NSString *opCopyOperation;
extern NSString *opMoveOperation;
extern NSString *opEraseOperation;
extern NSString *opNewFolder;
extern NSString *opRename;
extern NSString *opSendRecycleBinOperation;


//#define USE_UTI
#ifdef USE_UTI
/*Used for the internal Pasteboard*/
extern const CFStringRef kTreeItemDropUTI;
#define OwnUTITypes  (__bridge id)kTreeItemDropUTI,
#else
#define OwnUTITypes
#endif


#define APP_IS_SANDBOXED 1


//#define COL_ID_KEY @"ID"
#define COL_ACCESSOR_KEY @"accessor"
#define COL_TITLE_KEY @"title"
#define COL_TRANS_KEY @"transformer" 


// Used to check where is the focus of the window for the contextual selection
// This is a terrible workaround because I didn't find a clear and neat way
// to get the window focus. The cocoa base classes only work with Windows and do not
// seem to work with Views.
// -2 to differentiate from the -1 Not found.
#define BROWSER_TABLE_VIEW_INVALIDATED_ROW -2


extern NSFileManager *appFileManager;
extern NSOperationQueue *operationsQueue;
extern id appTreeManager;

typedef NS_ENUM(NSInteger, BViewMode) {
    BViewModeVoid = 0,
    BViewBrowserMode = 1,
    BViewCatalystMode,
    BViewDuplicateMode
};

typedef NS_ENUM(NSInteger, ApplicationwMode) {
    ApplicationwMode2Views = 0, /* Each View is independent of the other */
    ApplicationwModeDuplicate,
    ApplicationwModePreview
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
extern NSString *kOptionsKey;

@protocol MYViewProtocol <NSObject>

-(NSString*) title;

// Service Handling needs to be forwarded to the delegate for the contextual menus

- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType;

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types;

- (void) refresh;

@end

#endif
