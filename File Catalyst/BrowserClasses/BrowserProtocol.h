//
//  BrowserProtocol.h
//  Caravelle
//
//  Created by Nuno on 29/11/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#ifndef Caravelle_BrowserProtocol_h
#define Caravelle_BrowserProtocol_h

#import <Foundation/Foundation.h>

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
    tagTreeItemAll       = NSUIntegerMax
};

#define BrowserItemPointer   NSObject<BrowserProtocol>*
#define BrowserFolderPointer NSObject<FolderProtocol>*


@protocol BrowserProtocol <NSObject>


-(id) parent;

-(BOOL) needsRefresh;
-(void)refresh;

-(NSString*)name;
-(void) setName:(NSString*)newName;
-(NSImage*)image;
-(NSString*)hint;

-(TreeItemTagEnum)tag;
-(void)    setTag:(TreeItemTagEnum)tags;
-(void)  resetTag:(TreeItemTagEnum)tags;
-(BOOL)   hasTags:(TreeItemTagEnum)tags;
-(void) toggleTag:(TreeItemTagEnum)tags;


-(BOOL) isExpandable;
-(BOOL) needsSizeCalculation;
-(BOOL) isGroup;
-(BOOL) isFolder; // has visible folders
-(BOOL) hasChildren; // has physical children but does not display as folders.
-(BOOL) isLeaf;  // convinient selector which translates to NOT isFolder
-(id)   hashObject; // Used for maintaining selections

// Copy and paste support
-(NSDragOperation) supportedDragOperations:(id<NSDraggingInfo>) info;
-(NSArray*) acceptDropped:(id<NSDraggingInfo>)info operation:(NSDragOperation)operation sender:(id)fromObject;


@end


@protocol FolderProtocol <BrowserProtocol>

-(NSInteger)numberOfItemsInNode; // TODO:!!!! rename to itemCount
-(BrowserItemPointer)itemAtIndex:(NSUInteger)index;
-(NSMutableArray*) itemsInNode;
//-(NSInteger) numberOfItemsInBranch;
-(NSMutableArray*) itemsInBranchTillDepth:(NSInteger)depth;
-(NSMutableArray*) itemsInNodeWithPredicate:(NSPredicate*)filter;
-(NSMutableArray*) itemsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth;

-(NSInteger)numberOfBranchesInNode; // TODO:!!!! rename to branchCount
-(BrowserItemPointer)branchAtIndex:(NSUInteger)index;
-(NSMutableArray*) branchesInNode;

-(NSInteger)numberOfLeafsInNode;
-(BrowserItemPointer)leafAtIndex:(NSUInteger)index;
-(NSMutableArray*) leafsInNode;
-(NSInteger) numberOfLeafsInBranch;
-(NSMutableArray*) leafsInBranchTillDepth:(NSInteger)depth;
-(NSMutableArray*) leafsInNodeWithPredicate:(NSPredicate*)filter;
-(NSMutableArray*) leafsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth;

-(NSMutableArray*) children; // The difference between this and the itemsInNode is that the second one returns a copy
-(BOOL) canContain:(id<BrowserProtocol>)obj;

@end


#endif
