//
//  NodeViewController.h
//  Caravelle
//
//  Created by Nuno Brum on 04/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Definitions.h"
#import "TreeBranch.h"
#import "NodeSortDescriptor.h"



@protocol NodeViewProtocol <NSObject, MYViewProtocol>

-(void) reloadItem:(id) object;
-(void) refresh;
-(void) refreshKeepingSelections;
-(NSView*) containerView;

- (void) setCurrentNode:(TreeBranch*)branch;
- (TreeBranch*) currentNode;

-(NSArray*) getSelectedItems;
-(NSArray*) getSelectedItemsForContextMenu;
-(TreeItem*) getLastClickedItem;

@end


@interface NodeViewController : NSViewController <MYViewProtocol> {
    TreeItem   *_validatedDropDestination;
    NSDragOperation _validatedDropOperation;
    NSMutableIndexSet *extendedSelection;
    NSMutableArray *_displayedItems;
    NSString * _twinName;
}

@property (readwrite, weak) id<ParentProtocol> parentController;
@property (readwrite, strong) NSString *filterText;

@property (getter = filesInSubdirsDisplayed, setter = setDisplayFilesInSubdirs:) BOOL extendToSubdirectories;
@property (getter= foldersDisplayed, setter = setFoldersDisplayed:) BOOL foldersInTable;

@property (readwrite, strong) NSMutableArray *sortAndGroupDescriptors;
@property NSString *viewName;

- (void) initController;
- (void) setCurrentNode:(TreeBranch*)branch;
- (TreeBranch*) currentNode;
- (void) setName:(NSString*)viewName twinName:(NSString*)twinName;


- (void) updateFocus:(id)sender;
- (void) contextualFocus:(id)sender;
- (void)cancelOperation:(id)sender;

- (void) refresh;
- (void) refreshKeepingSelections;

- (BOOL) startEditItemName:(TreeItem*)item;
- (void) insertItem:(id)item;
- (void) orderOperation:(NSString*)operation onItems:(NSArray*)orderedItems;

- (void) registerDraggedTypes;
- (void) unregisterDraggedTypes;
- (NSView*) containerView;

- (NSMutableArray*) itemsToDisplay;
- (NodeSortDescriptor*) sortDescriptorForColID:(NSString*)colID;
- (void) makeSortOnColID:(NSString*)info ascending:(BOOL)ascending grouping:(BOOL)grouping;
- (void) removeSortKey:(NSString*)key;

-(NSArray*) getTableViewSelectedURLs;
-(void) setTableViewSelectedURLs:(NSArray*) urls;
-(NSArray*) getSelectedItems;
-(NSArray*) getSelectedItemsForContextMenu;
-(TreeItem*) getLastClickedItem;

-(void) startBusyAnimations;
-(void) stopBusyAnimations;

@end
