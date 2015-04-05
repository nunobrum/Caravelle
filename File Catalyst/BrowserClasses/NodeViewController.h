//
//  NodeViewController.h
//  Caravelle
//
//  Created by Viktoryia Labunets on 04/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Definitions.h"
#import "TreeBranch.h"



extern NSDragOperation validateDrop(id<NSDraggingInfo> info,  TreeItem* destItem);
extern BOOL acceptDrop(id < NSDraggingInfo > info, TreeItem* destItem, NSDragOperation operation, id fromObject);

@protocol NodeViewProtocol <NSObject, MYViewProtocol>

-(void) reloadItem:(id) object;
-(void) refresh;
-(void) refreshKeepingSelections;
-(NSView*) containerView;

@end


@interface NodeViewController : NSViewController <NodeViewProtocol>

@property (readwrite, weak) id<ParentProtocol> parentController;
@property (readwrite) NSString *filterText;

@property (getter = filesInSubdirsDisplayed, setter = setDisplayFilesInSubdirs:) BOOL extendToSubdirectories;
@property (getter= foldersDisplayed, setter = setFoldersDisplayed:) BOOL foldersInTable;


- (void) initController;
- (void) setCurrentNode:(TreeBranch*)branch;
- (TreeBranch*) currentNode;

- (void) orderOperation:(NSString*)operation onItems:(NSArray*)orderedItems;

- (void) registerDraggedTypes;
- (void) unregisterDraggedTypes;
- (NSView*) containerView;

- (NSMutableArray*) itemsToDisplay;

-(NSArray*) getTableViewSelectedURLs;
-(void) setTableViewSelectedURLs:(NSArray*) urls;
-(NSArray*) getSelectedItems;
-(NSArray*) getSelectedItemsForContextMenu;
-(TreeItem*) getLastClickedItem;

-(void) startBusyAnimations;
-(void) stopBusyAnimations;

@end
