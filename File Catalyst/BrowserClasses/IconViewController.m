//
//  IconViewController.m
//  Caravelle
//
//  Created by Nuno Brum on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "IconViewController.h"
#import "FileCollectionViewItem.h"
#import "CollectionHeaderView.h"
#import "PasteboardUtils.h"
#import "CollectionViewer.h"

// key values for the icon view dictionary
NSString *KEY_NAME = @"name";
NSString *KEY_ICON = @"icon";

NSString *ICON_VIEW_FILE = @"FILE_ICON";

// notification for indicating file system content has been received
//NSString *kReceivedContentNotification = @"ReceivedContentNotification";



@interface IconViewController () {
    NSMutableSet <NSIndexPath*> *extendedSelection;
    FileCollectionViewItem* menuTarget;
    NSCollectionViewFlowLayout *flowLayout;
}

@end


@implementation IconViewController

- (void) initController {
    [super initController];
    //NSNib *IconItemNib = [[NSNib alloc] initWithNibNamed:@"IconViewItem" bundle:nil];
    //[self->_collectionView registerNib:IconItemNib forItemWithIdentifier:ICON_VIEW_FILE];
    //[self->_collectionView setDataSource:self];
}

-(void) viewDidLoad {
    const float sectionInsetHeight = 10.0;
    // 1
    self->flowLayout = [[NSCollectionViewFlowLayout alloc] init];
    NSSize IconSize;
    IconSize.width = 64.0;
    IconSize.height = 64.0;
    self->flowLayout.itemSize = IconSize;
    
    NSEdgeInsets sectionInset;
    sectionInset.bottom = sectionInsetHeight;
    sectionInset.top = sectionInsetHeight;
    sectionInset.left = 20.0;
    sectionInset.right = 20.0;
    self->flowLayout.sectionInset = sectionInset;
    self->flowLayout.minimumInteritemSpacing = 10.0;
    self->flowLayout.minimumLineSpacing = 10.0;
    [self.collectionView setCollectionViewLayout: flowLayout];
    // 2
    self.view.wantsLayer = YES;
    // 3
    [self.collectionView.layer  setBackgroundColor : (__bridge CGColorRef _Nullable)([NSColor blackColor]) ];
    
}

-(CollectionViewer*) currentViewer {
    if (self->dataViewer == nil) {
        self->dataViewer = [[CollectionViewer alloc] initWithParent:self.currentNode depth:0];
    }
    return (CollectionViewer*)self->dataViewer;
}

#pragma mark CollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return [self.currentViewer sectionCount];
}


- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.currentViewer itemCountAtSection:section];
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    FileCollectionViewItem *icon = [collectionView makeItemWithIdentifier:@"FileCollectionViewItem" forIndexPath:indexPath];
    NSAssert(icon!=nil,@"ERROR! IconViewController.collectionView:itemForRepresentedObjectAtIndexPath: Icon View Not Found!");
    TreeItem *theFile;

    theFile = [self.currentViewer itemAtIndexPath:indexPath];
    
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

// This is used to create the header and footer views
-(NSView*) collectionView:(NSCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    CollectionHeaderView *view = [collectionView makeSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:@"CollectionHeaderView" forIndexPath:indexPath];
    NSAssert(view != nil, @"IconViewController.collectionView:viewForSupplementaryElementOfKind:atIndexPath: Didn't received the View");
    [view.sectionTitle setStringValue:[self.currentViewer titleForGroup:indexPath.section]];
    return view;
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


#pragma mark - NSCollectionViewDelegateFlowLayout

//- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
//- (NSEdgeInsets)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;
//- (CGFloat)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section;
//- (CGFloat)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    NSSize headerSize = {.width = 1000, .height = 24 };
    return self.currentViewer.sectionCount > 1 ? headerSize : NSZeroSize;
}

//- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section;




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
    NSSet <NSIndexPath*> *selectIndexPaths = [self.collectionView indexPathsWithHashes:hashes];
    [self.collectionView setSelectionIndexPaths:selectIndexPaths];
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
    [self collectItems];
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
        NSIndexPath *indexPath = [self.collectionView indexPathForRepresentedObject: object];
        if (indexPath != nil) {
            NSSet <NSIndexPath*> *indexPaths = [NSSet setWithObject:indexPath];
            [self.collectionView reloadItemsAtIndexPaths:indexPaths];
            
        }
    }
}


-(void) setSortDescriptor:(NSSortDescriptor *)sort {
    [self.currentViewer setSortDescriptor:sort];
    if ([self.currentViewer needsRefresh]) {
        [self.collectionView reloadData];
    }
}

-(void) setDepth:(NSInteger)depth {
    [self.currentViewer setDepth:depth];
    if ([self.currentViewer needsRefresh]) {
        [self.collectionView reloadData];
    }
}

-(void) setFilter:(NSPredicate *)filter {
    [self.currentViewer setFilter:filter];
    if ([self.currentViewer needsRefresh]) {
        [self.collectionView reloadData];
    }
}


-(NSArray*) getSelectedItems {
    NSMutableArray *answer = [NSMutableArray arrayWithCapacity:self.collectionView.selectionIndexPaths.count];
    
    for (NSIndexPath *indexPath in self.collectionView.selectionIndexPaths) {
        [answer addObject:[self.collectionView objectValueAtIndexPath: indexPath]];
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
        if ([[self currentNode] relationTo:item]==pathIsChild) {
            // Returns the current selected item
            return item;
        }
    }
    return self.currentNode;
}

#pragma - Drag & Drop Support

-(BOOL)   collectionView:(NSCollectionView *)collectionView
canDragItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
               withEvent:(NSEvent *)event {
    NSArray *items = [self.collectionView objectsAtIndexPathSet:indexPaths];
    
    // Block if there is a read-only file
    for (TreeItem *item in items) {
        if ([item hasTags:tagTreeItemReadOnly])
            return NO;
    }
    return YES;
}


-(NSDragOperation) collectionView:(NSCollectionView *)collectionView
                     validateDrop:(id<NSDraggingInfo>)draggingInfo
                proposedIndexPath:(NSIndexPath *__autoreleasing  _Nonnull *)proposedDropIndexPath
                    dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {

    self->_validatedDropDestination = nil;
    if (*proposedDropOperation == NSCollectionViewDropBefore) { // This is on the folder being displayed
        self->_validatedDropDestination = self.currentNode;
    }
    else if (*proposedDropOperation == NSCollectionViewDropOn) {

        @try { // If the row is not valid, it will assume the tree node being displayed.
            self->_validatedDropDestination = [self.collectionView objectValueAtIndexPath:*proposedDropIndexPath];
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

- (BOOL) collectionView:(NSCollectionView *)collectionView
             acceptDrop:(nonnull id<NSDraggingInfo>)draggingInfo
              indexPath:(nonnull NSIndexPath *)indexPath
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

-(NSArray*) collectionView:(NSCollectionView *) collectionView namesOfPromisedFilesDroppedAtDestination:(nonnull NSURL *)dropURL
forDraggedItemsAtIndexPaths:(nonnull NSSet<NSIndexPath *> *)indexPaths {
    return nil;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView
   writeItemsAtIndexPaths:(nonnull NSSet<NSIndexPath *> *)indexPaths toPasteboard:(nonnull NSPasteboard *)pasteboard {

    NSArray *items = [self.collectionView objectsAtIndexPathSet:indexPaths];
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
        NSSet<NSIndexPath *> *itemsSelected = [self.collectionView selectionIndexPaths];
        if (itemsSelected != nil) {
            // TODO:1.4 implement here the option for rename in window
            if ([itemsSelected count] == 1) {
                // if only one object selected
                TreeItem *firstItem = [self.collectionView objectValueAtIndexPath:[itemsSelected anyObject]];
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
            self->extendedSelection = [NSMutableSet setWithCapacity:1];
        }
        NSSet<NSIndexPath *> *indexset = [self.collectionView selectionIndexPaths];
    
        [indexset enumerateIndexPathsWithOptions:NSEnumerationConcurrent usingBlock:^(NSIndexPath * _Nonnull indexPath, BOOL * _Nonnull stop) {
            TreeItem* item = [self.collectionView objectValueAtIndexPath: indexPath];
            [item toggleTag:tagTreeItemMarked];
            if ([self->extendedSelection containsObject:indexPath])
                [self->extendedSelection removeObject:indexPath];
            else
                [self->extendedSelection addObject:indexPath];
        }];

        [self refreshKeepingSelections];

    }
}


-(BOOL) startEditItemName:(TreeItem*)item  {
    NSIndexPath *itemPath = [self.collectionView indexPathForRepresentedObject: item];
    if (itemPath != nil) {
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
        // TODO:!!!!! Is only working with one object
        NSAssert([selection count]==1,@"IconViewController.insertItem: - Alert!: Received more than one item. Code is taking a random object to proceed.");
        insertIndexPath = [selection anyObject];
        //[self insertedItem:item atIndexPath:insertIndexPath];
    }
    else {
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
        //[self insertedItem:item atTableRow:-1]; // At the last position
    }
    NSLog(@"// TODO:!!!!! IconViewController.insertItem: Need to insert the object into the data source");
    
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
