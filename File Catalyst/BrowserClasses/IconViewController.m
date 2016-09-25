//
//  IconViewController.m
//  Caravelle
//
//  Created by Nuno Brum on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "IconViewController.h"
#import "FileCollectionViewItem.h"
#import "PasteboardUtils.h"

// key values for the icon view dictionary
NSString *KEY_NAME = @"name";
NSString *KEY_ICON = @"icon";

NSString *ICON_VIEW_FILE = @"FILE_ICON";

// notification for indicating file system content has been received
//NSString *kReceivedContentNotification = @"ReceivedContentNotification";
#define SECTION_BUFFER_INCREASE 20


@interface IconViewController () {
    NSMutableIndexSet *extendedSelection;
    FileCollectionViewItem* menuTarget;
    NSUInteger* sectionIndexes;
    NSUInteger sectionIndexesSize;
    NSUInteger sectionCount;
    NSCollectionViewFlowLayout *flowLayout;
}

@end


@implementation IconViewController

- (void) initController {
    [super initController];
    self->sectionIndexesSize = SECTION_BUFFER_INCREASE; // Initial size, later it can grow
    self->sectionIndexes = malloc(sizeof(NSUInteger)*(self->sectionIndexesSize));
    //NSNib *IconItemNib = [[NSNib alloc] initWithNibNamed:@"IconViewItem" bundle:nil];
    //[self->_collectionView registerNib:IconItemNib forItemWithIdentifier:ICON_VIEW_FILE];
    //[self->_collectionView setDataSource:self];
}

-(void) viewDidLoad {
    // 1
    self->flowLayout = [[NSCollectionViewFlowLayout alloc] init];
    NSSize IconSize;
    IconSize.width = 64.0;
    IconSize.height = 94.0;
    self->flowLayout.itemSize = IconSize;
    
    NSEdgeInsets sectionInset;
    sectionInset.bottom = 10.0;
    sectionInset.top = 10.0;
    sectionInset.left = 20.0;
    sectionInset.right = 20.0;
    self->flowLayout.sectionInset = sectionInset;
    self->flowLayout.minimumInteritemSpacing = 20.0;
    self->flowLayout.minimumLineSpacing = 20.0;
    [self.collectionView setCollectionViewLayout: flowLayout];
    // 2
    self.view.wantsLayer = YES;
    // 3
    [self.collectionView.layer  setBackgroundColor : (__bridge CGColorRef _Nullable)([NSColor blackColor]) ];
    
}

#pragma mark CollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    NSUInteger idx = 0;
    TreeItem *theFile;
    self->sectionCount = 0;
    
    while (idx < self->_displayedItems.count) {
        theFile = self->_displayedItems[idx];
        if (theFile.isGroup) {
            self->sectionIndexes[self->sectionCount++] = idx;
            // This will scale up the number of groups if needed.
            if (self->sectionCount >= self->sectionIndexesSize) {
                self->sectionIndexesSize += SECTION_BUFFER_INCREASE;
                free(self->sectionIndexes);
                self->sectionIndexes = malloc(sizeof(NSUInteger)*(self->sectionIndexesSize));
                // and restart the process
                // TODO: use a temp buffer to copy the previous results instead of restarting process
                idx = 0;
                self->sectionCount = 0;
            }
            else
                idx++;
        }
        else
            idx++;
    }
    self->sectionIndexes[self->sectionCount++] = self->_displayedItems.count;
    return self->sectionCount;
}

-(NSUInteger) linearIndexForIndexPath:(NSIndexPath*) indexPath {
    if (indexPath.section == 0) {
        return indexPath.item;
    }
    else if (indexPath.section < self->sectionCount) {
        return self->sectionIndexes[indexPath.section-1] + indexPath.item;
    }
    else {
        NSAssert(NO,@"IconViewController.linearIndexForIndexPath: - Error! section number greater than expected");
        return 0;
    }
}

-(NSIndexPath*) indexPathForLinearIndex:(NSUInteger) linearIndex {
    NSUInteger section = 0;
    NSUInteger item;
    while (linearIndex >= self->sectionIndexes[section]) {
        section++;
        if (section > self->sectionCount) {
            NSAssert(NO,@"IconViewController.indexPathForLinearIndex: - Error! section number greater than expected");
            return nil;
        }
    }
    if (section==0) {
        item = linearIndex;
    }
    else {
        item = linearIndex-self->sectionIndexes[section-1];
    }
    return [NSIndexPath indexPathForItem:item inSection:section];
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0)
        return (self->sectionIndexes[0]);
    else if (section < self->sectionCount)
        return (self->sectionIndexes[section]- self->sectionIndexes[section-1]);
    else {
        NSAssert(NO,@"ERROR in collectionView:numberOfItemsInSection:section - Exceeded buffer size");
        return 0; // This is an error
    }
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    FileCollectionViewItem *icon = [collectionView makeItemWithIdentifier:@"FileCollectionViewItem" forIndexPath:indexPath];
    NSAssert(icon!=nil,@"ERROR! IconViewController.collectionView:itemForRepresentedObjectAtIndexPath: Icon View Not Found!");
    TreeItem *theFile;

    theFile = self->_displayedItems[[self linearIndexForIndexPath:indexPath]];
    
    icon.representedObject = theFile; // Store the file for later usage.
    
    [icon.imageView setImage: theFile.image];
    // an alternative: icon.imageView.image = theFile.image;
    
    [icon.textField setStringValue: theFile.name];
    
    // If it's a new file, then assume a default ICON
    
    // Then setup properties on the cellView based on the column
    //[icon setToolTip:[theFile hint]]; //TODO:!!!! Add tool tips lazyly by using view: stringForToolTip: point: userData:
    
    // Setting the color
    [icon.textField setTextColor:[theFile textColor]];
    return icon;
}
#pragma mark CollectionViewDelegate 
//- (NSSet<NSIndexPath *> *)collectionView:(NSCollectionView *)collectionView shouldSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
//    NSLog(@"IconViewController.shouldSelectItemsAtIndexPaths: %@",indexPaths);
//    return indexPaths;
//}
//
//- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
//    NSLog(@"IconViewController.didSelectItemsAtIndexPaths: %@",indexPaths);
//}

//- (NSSet<NSIndexPath *> *)collectionView:(NSCollectionView *)collectionView shouldChangeItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths toHighlightState:(NSCollectionViewItemHighlightState)highlightState {
//    NSLog(@"IconViewController.shouldChangeItemsAtIndexPaths:%@ toHighlightState:%li",indexPaths,(long)highlightState);
//    return indexPaths;
//}



#pragma mark focusRelatedFunctions

-(NSView*) containerView {
    return self.collectionView;
}

-(IBAction) lastRightClick:(id)sender {
    [self.parentController contextualFocus:self];
}

-(IBAction) lastClick:(id)sender {
    [self.parentController updateFocus:self];
}

/* This action is associated manually with the doubleClickTarget in Bindings */
- (IBAction)doubleClick:(id)sender {
    NSArray *itemsSelected = [self getSelectedItems];
    [self orderOperation:opOpenOperation onItems:itemsSelected];
}


- (void) focusOnFirstView {
    if (self.collectionView.selectionIndexPaths.count==0) {
        NSIndexSet *firstIndex = [NSIndexSet indexSetWithIndex:0];
        [self.collectionView setSelectionIndexes:firstIndex];
    }
    [self.view.window makeFirstResponder:self.containerView];
}

- (void) focusOnLastView {
    if (self.collectionView.selectionIndexPaths.count==0) {
        NSIndexSet *firstIndex = [NSIndexSet indexSetWithIndex:0];
        [self.collectionView setSelectionIndexes:firstIndex];
    }
    [self.view.window makeFirstResponder:self.containerView];
}

-(NSArray*) getSelectedItemsHash {
    if (self.collectionView.selectionIndexPaths.count==0)
        return nil;
    else {
        // using collection operator to get the array of the URLs from the selected Items
        NSArray *selectedObjects = [self getSelectedItems];
        return [selectedObjects valueForKeyPath:@"@unionOfObjects.hashObject"];
    }
}

-(void) setSelectionByHashes:(NSArray *)hashes {
    if (hashes!=nil && [hashes count]>0) {
        NSMutableSet<NSIndexPath*> *selectIndexPaths = [[NSMutableSet alloc] initWithCapacity:hashes.count];
        NSUInteger section=0, nItem=0;
        NSUInteger idx=0;
        for (id item in self->_displayedItems ) {
            if ([item isKindOfClass:[TreeItem class]] && [hashes containsObject:[(TreeItem*)item hashObject]]) {
                // Advance to the good section
                while (idx >= self->sectionIndexes[section])
                    section++;
                if (section==0)
                    nItem = idx;
                else
                    nItem = idx - self->sectionIndexes[section-1];
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:nItem inSection:section];
                [selectIndexPaths addObject:indexPath];
            }
            idx++;
        }
        self.collectionView.selectionIndexPaths = selectIndexPaths;
    }
}


-(void) startBusyAnimations {
    [super startBusyAnimations];
    [self.myProgressIndicator setHidden:NO];
    [self.myProgressIndicator startAnimation:self];

}
-(void) stopBusyAnimations {
    [super stopBusyAnimations];
    [self.myProgressIndicator setHidden:YES];
    [self.myProgressIndicator stopAnimation:self];
}

-(void) refresh {
    [self startBusyAnimationsDelayed];
    // Refreshing the collection
    [self itemsToDisplay];
    [self stopBusyAnimations];
    [self.collectionView reloadData];
    [self.collectionView setNeedsDisplay:YES];
}

-(void) refreshKeepingSelections {
    NSArray *selectedOjects = [self getSelectedItemsHash];
    // Refreshing the View
    [self refresh];
    // Reselect stored selections
    [self setSelectionByHashes:selectedOjects];}

-(void) reloadItem:(id)object {
    if (object == self.currentNode) {
        // This is a total refresh
        [self refresh];
    }
    else {
        //FileCollectionViewItem *icon = [[self collectionView] iconWithItem:object];
        //[icon.view setNeedsDisplay:YES];
         //[self refreshKeepingSelections];
        NSInteger idx = [self->_displayedItems indexOfObject:object];
        if (idx != NSNotFound) {
            NSIndexPath *indexPath = [self indexPathForLinearIndex:idx];
            if (indexPath != nil) {
                NSSet <NSIndexPath*> *indexPaths = [NSSet setWithObject:indexPath];
                [self.collectionView reloadItemsAtIndexPaths:indexPaths];
            }
        }
    }
}

-(NSArray*) getSelectedItems {
    NSMutableArray *answer = [NSMutableArray arrayWithCapacity:self.collectionView.selectionIndexPaths.count];
    
    for (NSIndexPath *indexPath in self.collectionView.selectionIndexPaths) {
        NSUInteger idx = [self linearIndexForIndexPath:indexPath];
        [answer addObject:self->_displayedItems[idx] ];
    }
    return answer;
}

// Can select the current Node
- (NSArray*)getSelectedItemsForContextualMenu1 {
    if ([self.collectionView lastClicked] != nil) {
        NSArray *selectedItems = [self getSelectedItems];
        TreeItem *item = [[self.collectionView lastClicked] representedObject];
        if ([selectedItems containsObject:item])
            return selectedItems;
        else
            return [NSArray arrayWithObject:item];
    }
    return [NSArray arrayWithObject: self.currentNode];
}

// Doesn't select the current Node
- (NSArray*)getSelectedItemsForContextualMenu2 {
    if ([self.collectionView lastClicked] != nil) {
        NSArray *selectedItems = [self getSelectedItems];
        TreeItem *item = [[self.collectionView lastClicked] representedObject];
        if ([selectedItems containsObject:item])
            return selectedItems;
        else
            return [NSArray arrayWithObject:item];
    }
    return nil;
}

-(TreeItem*) getLastClickedItem {
    if ([self.collectionView lastClicked] != nil) {
        TreeItem *item = [[self.collectionView lastClicked] representedObject];
        if ([self->_displayedItems containsObject:item]) {
            // Returns the current selected item
            return item;
        }
    }
    return self.currentNode;
}

#pragma - Drag & Drop Support

- (BOOL)collectionView:(NSCollectionView *)collectionView
 canDragItemsAtIndexes:(NSIndexSet *)indexes
             withEvent:(NSEvent *)event {
    NSArray *items = [self->_displayedItems objectsAtIndexes:indexes];

    // Block if there is a read-only file
    for (TreeItem *item in items) {
        if ([item hasTags:tagTreeItemReadOnly])
            return NO;
    }
    return YES;
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView
                     validateDrop:(id<NSDraggingInfo>)draggingInfo
                    proposedIndex:(NSInteger *)proposedDropIndex
                    dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {

    self->_validatedDropDestination = nil;
    if (*proposedDropOperation == NSCollectionViewDropBefore) { // This is on the folder being displayed
        self->_validatedDropDestination = self.currentNode;
    }
    else if (*proposedDropOperation == NSCollectionViewDropOn) {

        @try { // If the row is not valid, it will assume the tree node being displayed.
            self->_validatedDropDestination = [self->_displayedItems objectAtIndex:*proposedDropIndex];
        }
        @catch (NSException *exception) {
            self->_validatedDropDestination = self.currentNode;
        }
        @finally {
            // Go away... nothing to see here
        }
    }

    /* Limit the Operations depending on the Destination Item Class*/
    if ([self->_validatedDropDestination isFolder]) {
        // TODO:1.5 Put here a timer for opening the Folder
        // Recording time and first time
        // if not first time and recorded time > 3 seconds => open folder
    }
    NSDragOperation dragOperations =[self->_validatedDropDestination supportedPasteOperations:draggingInfo];
    self->_validatedDropOperation = selectDropOperation(dragOperations);
    return self->_validatedDropOperation;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView
            acceptDrop:(id<NSDraggingInfo>)draggingInfo
                 index:(NSInteger)index
         dropOperation:(NSCollectionViewDropOperation)dropOperation {
    
    NSArray *filesDropped = [self->_validatedDropDestination acceptDropped:draggingInfo operation:self->_validatedDropOperation sender:self];
    
    // TODO:1.4 Implement code below when acceptDropped returns TreeItems
    /*
    if (self->_validatedDropDestination == self.currentNode && filesDropped!=nil) {
        //Inserts the rows using the specified animation.
        if (self->_validatedDropOperation & (NSDragOperationCopy | NSDragOperationMove)) {
            
            int i= 0;
            for (TreeItem* pastedItem in filesDropped) {
                [pastedItem setTag:tagTreeItemDropped];
                
                //[self.icons insertObject:newItem atIndex:index+i];
                [self.iconArrayController insertObject:pastedItem atArrangedObjectIndex:index+i];
                i++;
            }
        }
    }
     */
    return filesDropped!=nil;
}


// Not implemented for the time being
//- (NSImage *)collectionView:(NSCollectionView *)collectionView
//draggingImageForItemsAtIndexes:(NSIndexSet *)indexes
//                  withEvent:(NSEvent *)event
//                     offset:(NSPointPointer)dragImageOffset {
//
//}

- (NSArray *)collectionView:(NSCollectionView *)collectionView
namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropURL
   forDraggedItemsAtIndexes:(NSIndexSet *)indexes {
    return nil;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView
   writeItemsAtIndexes:(NSIndexSet *)indexes
          toPasteboard:(NSPasteboard *)pasteboard {

    NSArray *items = [self->_displayedItems objectsAtIndexes:indexes];
    return writeItemsToPasteboard(items, pasteboard, supportedPasteboardTypes());
}

#pragma - NS Menu Delegate

- (void)menuWillOpen:(NSMenu *)menu {
    self->menuTarget = [self.collectionView lastClicked];

    [self->menuTarget setHighlightState: NSCollectionViewItemHighlightForDeselection];
    
}

- (void)menuDidClose:(NSMenu *)menu {
    // Need to reload the item which highlight was changed
    [self->menuTarget setHighlightState:NSCollectionViewItemHighlightForSelection];
    
    // TODO:!!!!! Not sure this is needed
    TreeItem *obj = [self->menuTarget representedObject];
    if (NO==[[self getSelectedItems] containsObject:obj])
        [self->menuTarget setHighlightState:YES];
    [self reloadItem:obj];
}

// This selector is implemented in the super class
//-(void) menuNeedsUpdate:(NSMenu*) menu {
//    [super menu:menu updateItem:item atIndex:index shouldCancel:shouldCancel];
//}


#pragma mark - NSControlTextDelegate Protocol

- (void)keyDown:(NSEvent *)theEvent {
    // Get the origin
    NSString *key = [theEvent characters];
    unichar keyCode = [key characterAtIndex:0];
    
    NSString *keyWM = [theEvent charactersIgnoringModifiers];

    NSInteger behave = [[NSUserDefaults standardUserDefaults] integerForKey: USER_DEF_APP_BEHAVIOUR] ;

    if ([theEvent modifierFlags] & NSCommandKeyMask) {
        if (keyCode == KeyCodeDown) {    // will open the subject
            [self doubleClick:theEvent];
        }
        else if (keyCode == KeyCodeUp) {  // the CMD Up will up one directory level
            [[self parentController] upOneLevel];
        }
    }
    else if (([key isEqualToString:@"\r"] && behave == APP_BEHAVIOUR_MULTIPLATFORM) ||
        ([key isEqualToString:@" "] && behave == APP_BEHAVIOUR_NATIVE))
    {
        // The Return key will open the file
        [self doubleClick:theEvent];
    }
    else if ([key isEqualToString:@"\r"] && behave == APP_BEHAVIOUR_NATIVE) {
        // The return Key Edits the Name
        NSIndexSet *itemsSelected = self.collectionView.selectionIndexes;
        if (itemsSelected != nil) {
            // TODO:1.4 implement here the option for rename in window
            if ([itemsSelected count] == 1) {
                // if only one object selected
                TreeItem *firstItem = self->_displayedItems[[itemsSelected firstIndex]];
                [self startEditItemName:firstItem];
            }
            else {
                // Multiple rename
                //[NSApp performSelector:@selector(executeRename:) withObject:itemsSelected];
                // TODO:1.4 implement in future versions
                // For now just displaying an alert
                NSAlert *alert = [NSAlert alertWithMessageText:@"Multiple files selected!"
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"Multi-Rename of files will be enabled in a future version."];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert beginSheetModalForWindow:self.view.window completionHandler:NULL];
            }
        }
    }
    else if ([keyWM isEqualToString:@"\t"]) {
        // the tab key will switch Panes
        [[self parentController] focusOnNextView:self];
    }
    else if ([key isEqualToString:@"\x19"]) {
        [[self parentController] focusOnPreviousView:self];
    }
    else if ([key isEqualToString:@" "] && behave == APP_BEHAVIOUR_MULTIPLATFORM ) {
        // the Space Key will mark the file
        // only works the TableView
        if (self->extendedSelection==nil) {
            self->extendedSelection = [NSMutableIndexSet indexSet];
        }
        NSIndexSet *indexset = [self.collectionView selectionIndexes];
        [indexset enumerateIndexesUsingBlock:^(NSUInteger index, BOOL * stop) {
            TreeItem* item = [self.itemsToDisplay objectAtIndex:index];
            [item toggleTag:tagTreeItemMarked];
            if ([self->extendedSelection containsIndex:index])
                [self->extendedSelection removeIndex:index];
            else
                [self->extendedSelection addIndex:index];
        }];

        [self refreshKeepingSelections];

    }
}


-(BOOL) startEditItemName:(TreeItem*)item  {
    NSInteger index = [self->_displayedItems indexOfObject:item];
    if (index != NSNotFound) {
        NSIndexPath *itemPath = [self indexPathForLinearIndex:index];
        NSCollectionViewItem *icon = [self.collectionView itemAtIndexPath:itemPath];
        NSAssert(icon.representedObject == item, @"ERROR in IconViewController.startEditItemName: Didn't find the correct item");
        // Obtain the NSTextField from the view
        return [self.collectionView startEditInIcon:(FileCollectionViewItem*) icon];
    }
    else
        return NO;
}

-(void) insertItem:(id)item  {
    NSSet<NSIndexPath *> *selection = [self.collectionView selectionIndexPaths];
    NSIndexPath *insertIndexPath;

    if ([selection count]>0) {
        // Will insert a row on the bottom of the selection.
        // Find the last one
        NSUInteger __block lastSection=0, lastItem=0;
        [selection enumerateIndexPathsWithOptions:0 usingBlock:^(NSIndexPath *  indexPath, BOOL * stop) {
            if (lastSection<indexPath.section) {
                lastSection = indexPath.section;
            }
            if (lastSection == indexPath.section && lastItem < indexPath.item) {
                lastItem = indexPath.item;
            }
            
        }];
        lastItem++;
        insertIndexPath = [NSIndexPath indexPathForItem:lastItem inSection:lastSection];
        NSUInteger linearIndex = [self linearIndexForIndexPath:insertIndexPath];
        [self->_displayedItems insertObject:item atIndex:linearIndex];
    }
    else {
        [self->_displayedItems addObject:item];
        insertIndexPath = [self indexPathForLinearIndex:self->_displayedItems.count-1];
        
    }
    NSSet<NSIndexPath*> *insertIndexPathSet = [NSSet setWithCollectionViewIndexPath:insertIndexPath];
    [self.collectionView insertItemsAtIndexPaths:insertIndexPathSet];
    //Selects Inserted
    [self.collectionView setSelectionIndexPaths:insertIndexPathSet];

}

// This selector is invoked when the file was renamed or a New File was created
/************************************************************ 
 * This was replaced by the setName Directly on the TreeItem.
 ************************************************************
 - (IBAction)filenameDidChange:(id)sender {
    TreeItem *item = [sender representedObject];
    NSString *newName = [[(IconViewBox*)[(IconCollectionItem*)sender view] name] stringValue];
    if (item != nil) {
        NSString *operation=nil;
        if ([item hasTags:tagTreeItemNew]) {
            operation = opNewFolder;
        }
        else {
            // If the name didn't change. Do Nothing
            if ([newName isEqualToString:[item name]]) {
                return;
            }
            operation = opRename;
        }
        NSArray *items = [NSArray arrayWithObject:item];

         NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
         items, kDFOFilesKey,
         operation, kDFOOperationKey,
         newName, kDFORenameFileKey,
         self.currentNode, kDFODestinationKey,
         self, kFromObjectKey,
         nil];
         [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];

    }
}
*/
@end
