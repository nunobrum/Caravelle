//
//  LeftDataSource.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/30/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileCollection.h"
#import "TreeRoot.h"

enum enumInRootSet {
    rootCanBeInserted = 1,
    rootAlreadyContained = 0,
    rootContainsExisting = -1
    };

extern NSString *notificationStatusUpdate;

@interface LeftDataSource : NSObject <NSOutlineViewDataSource, NSTableViewDataSource, NSOutlineViewDelegate, NSTableViewDelegate> {
    //TreeItem *_Duplicates;
    //BOOL extendToSubdirectories;
    NSMutableArray *tableData;
    NSOutlineView *_TreeOutlineView;
    NSTableView *_TableView;
    NSSize iconSize;
    NSString *_filterText;
}


@property (getter = filesInSubdirsDisplayed, setter = setDisplayFilesInSubdirs:) BOOL extendToSubdirectories;

@property (getter= foldersDisplayed, setter = setFoldersDisplayed:) BOOL foldersInTable;

@property NSMutableArray *LeftBaseDirectories;

@property (getter =  getCatalystMode, setter = setCatalystMode:) BOOL catalystMode;

@property (setter = setPathBar:) NSPathCell *PathBar;

@property TreeItem *treeNodeSelected;

-(LeftDataSource*) init;


/* 
 * Tree Outline View Data Source Protocol
 */
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item ;
- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item;
//- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;
/*
 * Tree Outline View Data Delegate Protocol
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;

/*
 * Table Data Source Protocol
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
/*
 * Table Data Delegate Protocol
 */

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
/* Binding is done manually in the initialization procedure */
- (IBAction)TableDoubleClickEvent:(id)sender;

/*
 * Parent access routines
 */

-(void)setTreeOutlineView:(NSOutlineView*) outlineView;
-(void)setTableView:(NSTableView*) tableView;
-(NSOutlineView*) treeOutlineView;
-(id) getFileAtIndex:(NSUInteger)index;
-(void) setFilterText:(NSString *) filterText;
-(void) refreshTrees;
-(void) addWithFileCollection:(FileCollection *)fileCollection callback:(void (^)(NSInteger fileno))callbackhandler;
-(void) addWithRootPath:(NSURL*) rootPath;
//-(void) addBaseDirectory:(NSString*)rootpath fileCollection:(FileCollection*)collection callback:(void (^)(NSInteger fileno))callbackhandler;
-(void) removeRootWithIndex:(NSInteger)index;
//-(void) removeRoot: (TreeRoot*) rootPath;
-(NSInteger) canAddRoot: (NSString*) rootPath;
-(FileCollection *) concatenateAllCollections;
-(TreeBranch*) selectFolderByURL:(NSURL*)theURL;



@end
