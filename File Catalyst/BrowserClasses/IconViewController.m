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

-(void) refresh {
    self.icons = [self itemsToDisplay];

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

-(void) refreshKeepingSelections {
    // TODO: !!!! Keep the selections
    //Store selection
    [self refresh];
    // Reposition Selections
}

-(void) reloadItem:(id)object {
    [self refreshKeepingSelections];
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


@end
