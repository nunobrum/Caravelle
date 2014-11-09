//
//  Definitions.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 04/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#ifndef File_Catalyst_Definitions_h
#define File_Catalyst_Definitions_h


/* Used for Drag&Drop notifications */
extern NSString *notificationDoFileOperation;
extern NSString *kDropOperationKey;
extern NSString *kDropDestinationKey;
/* Used for Both Drag&Drop and for Status Notifications */
extern NSString *kDroppedFilesKey;

//#define USE_UTI
#ifdef USE_UTI
/*Used for the internal Pasteboard*/
extern const CFStringRef kTreeItemDropUTI;
#define OwnUTITypes  (__bridge id)kTreeItemDropUTI,
#else
#define OwnUTITypes
#endif

extern NSString *opCopyOperation;
extern NSString *opMoveOperation;
extern NSString *opEraseOperation;
extern NSString *opSendRecycleBinOperation;


#define COL_SELECTED_KEY @"selected"
//#define COL_ID_KEY @"ID"
#define COL_ACCESSOR_KEY @"accessor"
#define COL_TITLE_KEY @"title"
#define COL_TRANS_KEY @"transformer" 

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


#endif
