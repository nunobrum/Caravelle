//
//  IconViewController.m
//  Caravelle
//
//  Created by Nuno Brum on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "IconViewController.h"
#import "IconCollectionItem.h"

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


-(void) refresh {
    self.icons = [self itemsToDisplay];
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
    for (NSView *view in self.collectionView.subviews) {
        if ([[(IconCollectionItem*)view representedObject] isEqual:object])
            [view setNeedsDisplay:YES];
    }
    //[self refreshKeepingSelections];
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

#pragma - Drag & Drop

- (BOOL)collectionView:(NSCollectionView *)collectionView
 canDragItemsAtIndexes:(NSIndexSet *)indexes
             withEvent:(NSEvent *)event {
    return NO;
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView
                     validateDrop:(id<NSDraggingInfo>)draggingInfo
                    proposedIndex:(NSInteger *)proposedDropIndex
                    dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {
    return NSDragOperationNone;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView
            acceptDrop:(id<NSDraggingInfo>)draggingInfo
                 index:(NSInteger)index
         dropOperation:(NSCollectionViewDropOperation)dropOperation {
    return NO;
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
    return NO;
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

        // TODO:!!!! Check what is the preferred method
        [self refreshKeepingSelections];

    }
}


@end
