//
//  IconViewController.m
//  Caravelle
//
//  Created by Nuno Brum on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "IconViewController.h"
#import "IconCollectionItem.h"
#import "PasteboardUtils.h"

// key values for the icon view dictionary
NSString *KEY_NAME = @"name";
NSString *KEY_ICON = @"icon";

// notification for indicating file system content has been received
//NSString *kReceivedContentNotification = @"ReceivedContentNotification";



@interface IconViewController () {
    NSMutableIndexSet *extendedSelection;
    IconViewBox* menuTarget;
}

@property (readwrite, strong) NSMutableArray *icons;
@end


@implementation IconViewController

- (void) initController {
    [super initController];
}


// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    //  Set observer for the selection of iconArrayController
    [self.iconArrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:@"Selection Changed"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // Monitors selection change
    if (([keyPath isEqualToString:@"selectedObjects"]) &&
        // And if the view must be Key
        ([[self collectionView] isFirstResponder])) {
        [self updateFocus:self];
        // send a Status Notfication
        [self.parentController selectionDidChangeOn:self]; // Will Trigger the notification to the status bar
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


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
    NSArray *itemsSelected = [self.iconArrayController selectedObjects];
    [self orderOperation:opOpenOperation onItems:itemsSelected];
}


- (void) focusOnFirstView {
    if ([[self.iconArrayController selectedObjects] count]==0) {
        [self.iconArrayController setSelectionIndex:0];
    }
    [self.view.window makeFirstResponder:self.containerView];
}

- (void) focusOnLastView {
    if ([[self.iconArrayController selectedObjects] count]==0) {
        [self.iconArrayController setSelectionIndex:0];
    }
    [self.view.window makeFirstResponder:self.containerView];
}

-(NSArray*) getSelectedItemsHash {
    NSArray *selectedObjects = [self.iconArrayController selectedObjects];
    if ([selectedObjects count]==0)
        return nil;
    else {
        // using collection operator to get the array of the URLs from the selected Items
        return [selectedObjects valueForKeyPath:@"@unionOfObjects.hashObject"];
    }
}

-(void) setSelectionByHashes:(NSArray *)hashes {
    if (hashes!=nil && [hashes count]>0) {
        NSIndexSet *select = [self->_displayedItems indexesOfObjectsPassingTest:^(id item, NSUInteger index, BOOL *stop){
            //NSLog(@"setTableViewSelectedURLs %@ %lu", [item path], index);
            if ([item isKindOfClass:[TreeItem class]] && [hashes containsObject:[(TreeItem*)item hashObject]])
                return YES;
            else
                return NO;
        }];
        [self.iconArrayController  setSelectionIndexes:select];
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
    self.icons = [self itemsToDisplay];
    [self stopBusyAnimations];
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
        NSView *view = [[self collectionView] iconWithItem:object];
        [view setNeedsDisplay:YES];
    //[self refreshKeepingSelections];
    }
}

-(NSArray*) getSelectedItems {
    return [self.iconArrayController selectedObjects];
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
        if ([[self.iconArrayController arrangedObjects] containsObject:item]) {
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
    NSArray *items = [self.icons objectsAtIndexes:indexes];

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
            self->_validatedDropDestination = [self.icons objectAtIndex:*proposedDropIndex];
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

    NSArray *items = [self.icons objectsAtIndexes:indexes];
    return writeItemsToPasteboard(items, pasteboard, supportedPasteboardTypes());
}

#pragma - NS Menu Delegate

- (void)menuWillOpen:(NSMenu *)menu {
    self->menuTarget = [self.collectionView lastClicked];

    [self->menuTarget setFillColor:[NSColor windowBackgroundColor]];
    [self->menuTarget setTransparent:NO];
    [self->menuTarget setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
    // Need to reload the item which highlight was changed
    [self->menuTarget setFillColor:[NSColor alternateSelectedControlColor]];
    TreeItem *obj = [self->menuTarget representedObject];
    if (NO==[[self getSelectedItems] containsObject:obj])
        [self->menuTarget setTransparent:YES];
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
        NSArray *itemsSelected = [self.iconArrayController selectedObjects];
        if (itemsSelected != nil) {
            // TODO:1.4 implement here the option for rename in window
            if ([itemsSelected count] == 1) {
                // if only one object selected
                [self startEditItemName:[itemsSelected firstObject]];
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
        NSIndexSet *indexset = [self.iconArrayController selectionIndexes];
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
    IconViewBox *icon = [[self collectionView] iconWithItem:item];
    // Obtain the NSTextField from the view
    [(IconCollectionItem*)[icon delegate] prepareForEdit];
    NSTextField *textField = [icon name];
    NSAssert(textField!=nil, @"IconViewController.startEditItemName: textField not found!");
    [[icon window] makeFirstResponder:textField];
    // Recuperate the old filename
    NSString *oldFilename = [textField stringValue];
    // Select the part up to the extension
    NSUInteger head_size = [[oldFilename stringByDeletingPathExtension] length];
    NSRange selectRange = {0, head_size};
    [[textField currentEditor] setSelectedRange:selectRange];
    return YES;
}

-(void) insertItem:(id)item  {
    NSIndexSet *selection = [self.iconArrayController selectionIndexes];

    [self.iconArrayController setSelectsInsertedObjects:YES];

    if ([selection count]>0) {
        // Will insert a row on the bottom of the selection.
        NSInteger index = [selection lastIndex] + 1;
        [self.iconArrayController insertObject:item atArrangedObjectIndex:index];
    }
    else {
        [self.iconArrayController addObject:item];
    }
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
