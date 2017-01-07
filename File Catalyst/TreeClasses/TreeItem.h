//
//  TreeItem.h
//  Caravelle
//
//  Created by Nuno Brum on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Definitions.h"
#import "FileUtils.h"

extern const NSString *keyDuplicateInfo;

typedef NS_OPTIONS(NSUInteger, TreeItemTagEnum) {
    tagTreeItemDirty     = (1UL << 0), // Used to force TreeBranches to make a refresh from disk
    tagTreeItemScanned   = (1UL << 1), // Used to indicate that the directory was already read from the disk
    tagTreeItemMarked    = (1UL << 2),
    tagTreeItemDropped   = (1UL << 3), // Used for drag&drop operations
    tagTreeItemToMove    = (1UL << 4),
    tagTreeItemUpdating  = (1UL << 5),
    tagTreeItemRelease   = (1UL << 6), // Used inform BrowserControllers to remove items from Root
    tagTreeItemReadOnly  = (1UL << 7),
    tagTreeItemNew       = (1UL << 8),
    tagTreeItemHidden    = (1UL << 9),
    tagTreeSizeCalcReq   = (1UL << 10), // Used to avoid multiple orders to size calculation
    tagTreeHiddenPresent = (1UL << 11), // Used to check whether the Branches need update after a hidden configuration changed.
    tagTreeSelectProtect = (1UL << 12),
    tagTreeAuthorized    = (1UL << 13),
    tagTreeItemAll       = NSUIntegerMax
};


typedef NS_ENUM(NSInteger, ItemType) {
    ItemTypeNone = 0,
    ItemTypeBranch,
    ItemTypeFilter,
    ItemTypeDummyBranch, // All items below this one are considered for size calculations (this one excluded)
    //===================== Below this value there are only folders
    ItemTypeLeaf = 10, // All types of files will be above this number
    ItemTypeAudio = 100,
    ItemTypeImage = 200,
    ItemTypeVideo = 300
};


@protocol TreeProtocol <NSObject>

- (ItemType) itemType;

@end

@class TreeBranch;


@interface TreeItem : NSObject <NSPasteboardWriting, NSPasteboardReading> {
    NSURL           *_url;
    TreeItemTagEnum _tag;
    TreeBranch __weak *_parent; /* Declaring the parent as weak will solve the problem of doubled linked objects */
    NSMutableDictionary *_store;
}

@property (weak) TreeBranch           *parent;
@property NSString *nameCache; // This is to lower memory allocation calls, for each name call, a new CFString was being allocated

-(TreeItem*) initWithURL:(NSURL*)url parent:(id)parent;
-(TreeItem*) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent;
-(void) deinit;

-(void) purgeURLCacheResources;

+(id)treeItemForURL:(NSURL *)url parent:(id)parent;
+(id)treeItemForMDItem:(NSMetadataItem *)mdItem parent:(id)parent;
- (TreeItem*) root;

-(void) addToStore:(NSDictionary*) dict;
-(void) removeFromStore:(NSArray<NSString*>*)keys;
-(id) objectWithKey:(NSString*) key;
-(void) store:(id)object withKey:(NSString*)key;

-(void) notifyChange;

-(NSArray *) treeComponents;
-(NSArray *) treeComponentsToParent:(id)parent;


-(NSString*) name;
-(void) setName:(NSString*)newName;
-(NSDate*)   date_modified;
-(NSDate*)   date_accessed;
-(NSDate*)   date_created;
-(NSString*) path ;
-(NSString*) location;
-(NSImage*) image;
-(NSColor*) textColor;
-(NSNumber*) exactSize;
-(NSNumber*) allocatedSize;
-(NSNumber*) totalSize;
-(NSNumber*) totalAllocatedSize;
-(NSString*) fileKind;
-(NSString*) hint;


-(NSString*) fileOwnerName;
-(NSNumber*) fileOwnerID;
-(NSString*) fileGroupName;
-(NSNumber*) fileGroupID;
-(NSString*) filePermissions;

-(void) setUrl:(NSURL*)url;
-(NSURL*) url;

-(void) setTag:(TreeItemTagEnum)tag;
-(void) resetTag:(TreeItemTagEnum)tag;
-(void) toggleTag:(TreeItemTagEnum)tag;

-(TreeItemTagEnum) tag;
-(BOOL) hasTags:(TreeItemTagEnum) tag;
-(void) updateFileTags;

-(id) hashObject;
/*
 * File manipulation methods
 */
-(BOOL) openFile;
-(BOOL) removeItem;

-(NSArray*) openWithApplications;

/*
 * URL Comparison methods
 */
/*
 * Coding Compliant methods
 */
-(void) setValue:(id)value forUndefinedKey:(NSString *)key;

-(BOOL) hasDuplicates;
-(NSNumber*) duplicateGroup;

-(id) parent;

-(BOOL) needsRefresh;
-(void)refresh;


-(ItemType)  itemType;
-(BOOL) isLeaf;
-(BOOL) isFolder;
-(BOOL) isExpandable;
-(BOOL) needsSizeCalculation;
-(BOOL) isGroup;
-(BOOL) hasChildren; // has physical children but does not display as folders.
-(BOOL) isSelectable;
-(BOOL) canBeFlat;


// Tree Integration
-(NSArray*) pathComponents;
-(NSInteger) pathLevel;
-(TreeBranch*) parentAtLevel:(NSInteger)level;
-(enumPathCompare) relationTo:(TreeItem*)other;

// Menu support
-(BOOL) respondsToMenuTag:(EnumContextualMenuItemTags)tag;


// Copy and paste support
-(NSDragOperation) supportedPasteOperations:(id<NSDraggingInfo>) info;
-(NSArray*) acceptDropped:(id<NSDraggingInfo>)info operation:(NSDragOperation)operation sender:(id)fromObject;


/*
 * Debug
 */

-(NSString*) debugDescription;


@end
