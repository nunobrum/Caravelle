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
    IconCollectionItem * lastRightClick;
    NSMutableIndexSet *extendedSelection;
}

@property (readwrite, strong) NSMutableArray *icons;
@end


@implementation IconViewController

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    //  Set observer for the selection of iconArrayController
    [self.iconArrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:@"Selection Changed"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectedObjects"]) {
        [self updateFocus:self];
        // send a Status Notfication
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationStatusUpdate object:self.parentController userInfo:nil];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


-(NSView*) containerView {
    return self.collectionView;
}


-(IBAction) rightClick:(id)sender {
    [self.parentController contextualFocus:self];
    lastRightClick = sender;
    
}

/* This action is associated manually with the doubleClickTarget in Bindings */
- (IBAction)doubleClick:(id)sender {
    //NSIndexSet *selectedIndexes = [self.iconArrayController selectionIndexes];
    //NSArray *itemsSelected = [self.icons objectsAtIndexes:selectedIndexes];
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

-(void) startBusyAnimations {
    [self.myProgressIndicator setHidden:NO];
    [self.myProgressIndicator startAnimation:self];

}
-(void) stopBusyAnimations {
    [self.myProgressIndicator setHidden:YES];
    [self.myProgressIndicator stopAnimation:self];
}

-(void) refresh {
    self.icons = [self itemsToDisplay];
    //[self.iconArrayController setContent:[self itemsToDisplay]];
    // Refreshing the collection
    [self.collectionView setNeedsDisplay:YES];
}

-(void) refreshKeepingSelections {
    // TODO: !!!! Keep the selections
    //Store selection
    [self refresh];
    // Reposition Selections
}

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

- (NSArray*)getSelectedItemsForContextMenu {
    NSArray *selectedItems = [self getSelectedItems];
    TreeItem *item = [lastRightClick representedObject];
    if ([selectedItems containsObject:item])
        return selectedItems;
    else
        return [NSArray arrayWithObject:item];
}

-(TreeItem*) getLastClickedItem {
    // TODO: !!!!
    return nil;
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
    if ([self->_validatedDropDestination itemType] == ItemTypeBranch) {
        // TODO:!!! Put here a timer for opening the Folder
        // Recording time and first time
        // if not first time and recorded time > 3 seconds => open folder
    }
    self->_validatedDropOperation = validateDrop(draggingInfo, self->_validatedDropDestination);
    return self->_validatedDropOperation;

}

- (BOOL)collectionView:(NSCollectionView *)collectionView
            acceptDrop:(id<NSDraggingInfo>)draggingInfo
                 index:(NSInteger)index
         dropOperation:(NSCollectionViewDropOperation)dropOperation {

    BOOL opDone = acceptDrop(draggingInfo, self->_validatedDropDestination, self->_validatedDropOperation, self);

    if (self->_validatedDropDestination == self.currentNode && opDone==YES) {
        //Inserts the rows using the specified animation.
        if (self->_validatedDropOperation & (NSDragOperationCopy | NSDragOperationMove)) {
            NSPasteboard *pboard = [draggingInfo draggingPasteboard];
            NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];

            int i= 0;
            for (id pastedItem in files) {
                TreeItem *newItem=nil;
                if ([pastedItem isKindOfClass:[NSURL class]]) {
                    //[(TreeBranch*)targetItem addURL:pastedItem]; This will be done on the refresh after copy
                    newItem = [TreeItem treeItemForURL: pastedItem parent:self.currentNode];
                    [newItem setTag:tagTreeItemDropped];
                }
                if (newItem) {
                    //[self.icons insertObject:newItem atIndex:index+i];
                    [self.iconArrayController insertObject:newItem atArrangedObjectIndex:index+i];
                    i++;
                }
            }
        }
    }
    return opDone;
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

- (void)menuDidClose:(NSMenu *)menu {
    // Need to reload the item which highlight was changed
    id itemBox = [lastRightClick view];
    [itemBox setFillColor:[NSColor alternateSelectedControlColor]];
    TreeItem *obj = [lastRightClick representedObject];
    if (NO==[[self getSelectedItems] containsObject:obj])
        [itemBox setTransparent:YES];
    [self reloadItem:obj];
}

#pragma mark - NSControlTextDelegate Protocol

- (void)keyDown:(NSEvent *)theEvent {
    // Get the origin
    NSString *key = [theEvent characters];
    NSString *keyWM = [theEvent charactersIgnoringModifiers];

    NSInteger behave = [[NSUserDefaults standardUserDefaults] integerForKey: USER_DEF_APP_BEHAVOUR] ;

    if (([key isEqualToString:@"\r"] && behave == APP_BEHAVIOUR_MULTIPLATFORM) ||
        ([key isEqualToString:@" "] && behave == APP_BEHAVIOUR_NATIVE))
    {
        // The Return key will open the file
        [self doubleClick:theEvent];
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
            id item = [self.itemsToDisplay objectAtIndex:index];
            if ([item isKindOfClass:[TreeItem class]]) {
                [(TreeItem*)item toggleTag:tagTreeItemMarked];
            }
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
