//
//  NodeViewController.m
//  Caravelle
//
//  Created by Nuno Brum on 04/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "NodeViewController.h"
#import "PasteboardUtils.h"
#import "CustomTableHeaderView.h"


@interface NodeViewController () {
    TreeBranch *_currentNode;
    NSMutableArray *_observedVisibleItems;
}

@end

@implementation NodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

}

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    
}

-(void) setName:(NSString*)viewName twinName:(NSString*)twinName {
    [self setViewName:viewName];
    self->_twinName = twinName;
}

- (void) initController {
    self->_extendToSubdirectories = NO;
    self->_foldersInTable = YES;
    self->_currentNode = nil;
    self->_observedVisibleItems = [[NSMutableArray new] init];
    self.sortAndGroupDescriptors = nil;
    [self startBusyAnimations];
}

- (void)dealloc {
    //  Stop any observations that we may have
    [self unobserveAll];
    //    [super dealloc];
}

-(void) updateFocus:(id)sender {
    [[self parentController] updateFocus:self];
}

-(void) contextualFocus:(id)sender {
    [[self parentController] contextualFocus:self];
}

- (NSView*) containerView {
    NSAssert(NO,@"Assert Error. This is a virtual method");
    return nil;
}

- (void) setCurrentNode:(TreeBranch*)branch {
    [self unobserveItem:self.currentNode];
    self->_currentNode = branch;
    if (branch!=nil)
        [self observeItem:self.currentNode];
}

- (TreeBranch*) currentNode {
    return self->_currentNode;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kvoTreeBranchPropertyChildren]) {
        // Find the row and reload it.
        // Note that KVO notifications may be sent from a background thread (in this case, we know they will be)
        // We should only update the UI on the main thread, and in addition, we use NSRunLoopCommonModes to make sure the UI updates when a modal window is up.
        [self performSelectorOnMainThread:@selector(reloadItem:) withObject:object waitUntilDone:NO modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }
    else if ([keyPath isEqualToString:kvoTreeBranchPropertySize]) {
        [self performSelectorOnMainThread:@selector(reloadSize:) withObject:object waitUntilDone:NO modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }
}

-(void) observeItem:(TreeItem*)item {
    // Use KVO to observe for changes of its children Array
    if (item !=nil && ![_observedVisibleItems containsObject:item]) {
        [item addObserver:self forKeyPath:kvoTreeBranchPropertyChildren options:0 context:NULL];
        [_observedVisibleItems addObject:item];
    }
}

-(void) unobserveItem:(TreeItem*)item {
    // Use KVO to observe for changes of its children Array
    if (item!=nil && [_observedVisibleItems containsObject:item]) {
        [item removeObserver:self forKeyPath:kvoTreeBranchPropertyChildren];
        [_observedVisibleItems removeObject:item];
    }
}

-(void) unobserveAll {
    for (TreeBranch* item in _observedVisibleItems) {
        [item removeObserver:self forKeyPath:kvoTreeBranchPropertyChildren];
    }
    [_observedVisibleItems removeAllObjects];
}

-(void) reloadItem:(id)object {
    NSAssert(NO, @"NodeViewController.reloadItem: This method needs to be overriden");
}

-(void) reloadSize:(id)object {
    NSAssert(NO, @"NodeViewController.reloadSize: This method needs to be overriden");
}

-(BOOL) startEditItemName:(TreeItem*)item {
    NSLog(@"NodeViewController.startEditItemName: This method needs to be overriden");
    return NO;
}

-(void) insertItem:(id)item {
    NSAssert(NO, @"NodeViewController.insertItem: This method should be overriden");
}
- (void) orderOperation:(NSString*)operation onItems:(NSArray*)orderedItems;
 {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              orderedItems, kDFOFilesKey,
                              operation, kDFOOperationKey,
                              self.currentNode, kDFODestinationKey,
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:userInfo];
}

- (void) refresh {
    NSAssert(NO, @"NodeViewController.refresh: This method needs to be overriden");
}

-(void) refreshKeepingSelections {
    NSAssert(NO, @"NodeViewController.refreshKeepingSelections: This method needs to be overriden");
}

- (void) registerDraggedTypes {
    [[(id<NodeViewProtocol>)self containerView] registerForDraggedTypes: supportedPasteboardTypes()];

}

- (void) unregisterDraggedTypes {
    [[(id<NodeViewProtocol>)self containerView] unregisterDraggedTypes];

}

/* The menu handling is forwarded to the Delegate.
 For the contextual Menus the selection is different, than for the application */
- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType
{
    return [(id<MYViewProtocol>)[self parentController] validRequestorForSendType:sendType returnType:returnType];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types
{
    NSArray *selectedFiles = [self getSelectedItemsForContextMenu];
    return writeItemsToPasteboard(selectedFiles, pboard, types);

}

- (void)cancelOperation:(id)sender {
    // clean the filter
    [[self parentController] performSelector:@selector(cancelOperation:) withObject:self];
    // and pass the cancel operation upwards anyway
}

- (void) focusOnFirstView {
    NSLog(@"NodeViewController.focusOnFirstView: should be overriden");
    [self.view.window makeFirstResponder:self.containerView];
}

- (void) focusOnLastView {
    NSLog(@"NodeViewController.focusOnLastView: should be overriden");
    [self.view.window makeFirstResponder:self.containerView];
}

- (NSView*) focusedView {
    //NSLog(@"NodeViewController.focusedView: should be overriden");
    static NSView *lastFocus=nil;
    id control = [[[self containerView] window] firstResponder];
    if ([control isKindOfClass:[NSView class]]) {
        lastFocus = control;
    }
    return lastFocus;
}

-(NSInteger) insertGroups:(NSMutableArray*)items start:(NSUInteger)start stop:(NSUInteger)stop descriptorIndex:(NSUInteger)descIndex {
    // Verify in no more descriptors to process
    NSInteger inserted = 0;
    if (descIndex < [self.sortAndGroupDescriptors count]) {
        NodeSortDescriptor *sortDesc = [self.sortAndGroupDescriptors objectAtIndex:descIndex];

        if (sortDesc.isGrouping) { // Grouping is needed for this descriptor
            NSUInteger i = start;
            NSArray *groups = nil;
            while (i < (stop+inserted)) {
                groups = [sortDesc groupItemsForObject: items[i]];
                if (groups!=nil) {
                    for (GroupItem *GI in groups) {
                        [items insertObject:GI atIndex:i - GI.nElements];
                        i++;
                        //NSInteger nInserted = [self insertGroups:items start:i - GI.nElements stop:i descriptorIndex:descIndex+1];
                        //NSLog(@"Inserted %@ at %ld, nElements %ld", GI.title, i - GI.nElements - nInserted, GI.nElements);
                        inserted += 1; // + nInserted;
                        //i += nInserted;
                    }
                }
                i++;
            }
            groups = [sortDesc flushGroups];
            if (groups!=nil) {
                i--; // Needs to be in the last position
                for (GroupItem *GI in groups) {
                    [items insertObject:GI atIndex:i - GI.nElements];
                    i++;
                    //NSInteger nInserted = [self insertGroups:items start:i - GI.nElements stop:i descriptorIndex:descIndex+1];
                    inserted += 1 ;// + nInserted;
                    //i += nInserted;
                }
            }
        }
    }
    return inserted;
}

-(NSMutableArray*) itemsToDisplay {
    NSMutableArray *tableData = nil;
    /* Always uses the self.currentNode property to manage the Table View */
    // Get the depth configuration
    NSInteger iDepth = NSIntegerMax;

    if ([self.currentNode itemType] == ItemTypeBranch){
        /* if the filter is empty, doesn't filter anything */
        if (_filterText!=nil && [_filterText length]!=0) {
            NSPredicate *predicate;
            NSCharacterSet *specialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"*=~|&<>"];
            if ([self.filterText rangeOfCharacterFromSet:specialCharacters].location!=NSNotFound) {
                // TODO:!!! Tokenize the filter field to make inteligent searches
                @try {
                    predicate = [NSPredicate predicateWithFormat:self.filterText];
                }
                @catch (NSException *exception) {
                    predicate = nil;
                }
                /*@finally {}*/
            }
            else {
                NSString *attributeName  = @"name";
                NSString *attributeValue = [NSString stringWithFormat:@"*%@*", self.filterText];
                predicate   = [NSPredicate predicateWithFormat:@"%K like[cd] %@",
                               attributeName, attributeValue];
            }
            if (self.filesInSubdirsDisplayed==YES && self.foldersInTable==YES) {
                tableData = [self.currentNode itemsInBranchWithPredicate:predicate depth:iDepth];
            }
            else if (self.filesInSubdirsDisplayed==YES && self.foldersInTable==NO) {
                tableData = [self.currentNode leafsInBranchWithPredicate:predicate depth:iDepth];
            }
            else if (self.filesInSubdirsDisplayed==NO && self.foldersInTable==YES) {
                tableData = [self.currentNode itemsInNodeWithPredicate:predicate];
            }
            else if (self.filesInSubdirsDisplayed==NO && self.foldersInTable==NO) {
                tableData = [self.currentNode leafsInNodeWithPredicate:predicate];
            }
        }
        else {
            if (self.filesInSubdirsDisplayed==YES && self.foldersInTable==YES) {
                tableData = [self.currentNode itemsInBranchTillDepth:iDepth];
            }
            else if (self.filesInSubdirsDisplayed==YES && self.foldersInTable==NO) {
                tableData = [self.currentNode leafsInBranchTillDepth:iDepth];
            }
            else if (self.filesInSubdirsDisplayed==NO && self.foldersInTable==YES) {
                tableData = [self.currentNode itemsInNode];
            }
            else if (self.filesInSubdirsDisplayed==NO && self.foldersInTable==NO) {
                tableData = [self.currentNode leafsInNode];
            }
        }

        // Sort Data
        if (self.sortAndGroupDescriptors!=nil) {
            NSArray *sortedArray = [tableData sortedArrayUsingDescriptors:self.sortAndGroupDescriptors];
            tableData = [NSMutableArray arrayWithArray:sortedArray];

            // Insert Groupings if needed
            if ([(NodeSortDescriptor*)[self.sortAndGroupDescriptors firstObject] isGrouping]) {
                // Since the sort groupings are always the first elements on the table
                // it sufices to test the first element to know if a grouping is needed

                // Need to restart all the descriptors
                for (NodeSortDescriptor *sortDesc in self.sortAndGroupDescriptors) {
                    if ([sortDesc isGrouping])
                        [sortDesc reset];
                    else
                        break;
                }
                [self insertGroups:tableData start:0 stop:[tableData count] descriptorIndex:0];
            }
        }
    }
    return tableData;
}

- (void) removeSortKey:(NSString*)key {
    for (NodeSortDescriptor *i in self.sortAndGroupDescriptors) {
        if ([i.key isEqualToString:key] ) {
            [self.sortAndGroupDescriptors removeObject:i];
            return;
        }
    }
}

-(NodeSortDescriptor*) sortDescriptorForColID:(NSString*)colID {
    NSString * key = keyForColID(colID);
    for (NodeSortDescriptor* desc in self.sortAndGroupDescriptors) {
        if ([desc.key isEqualToString:key]) {
            return desc;
        }
    }
    return nil;
}

- (void) makeSortOnColID:(NSString*)colID ascending:(BOOL)ascending grouping:(BOOL)grouping {
    if (self.sortAndGroupDescriptors==nil) {
        self.sortAndGroupDescriptors = [NSMutableArray arrayWithCapacity:1];
    }

    NSString * key = keyForColID(colID);

    NodeSortDescriptor *sortDesc = [[NodeSortDescriptor alloc] initWithKey:key ascending:ascending];
    if (grouping==YES) {
        NSString *groupingSelector =[[columnInfo() objectForKey:colID] objectForKey:COL_GROUPING_KEY];
        if (groupingSelector==nil) {
            // Try to get a selector from the transformer
            groupingSelector =[[columnInfo() objectForKey:colID] objectForKey:COL_TRANS_KEY];
        }
        if (groupingSelector!=nil) {
            [sortDesc setGrouping:grouping using:groupingSelector];
        }
    }
    // Removes the key if it was already existing in the remaining of the array
    [self removeSortKey:key];

    NSInteger i=0;
    if (grouping==NO) {
        // Will insert after the first non grouping descriptor
        while (i < [self.sortAndGroupDescriptors count]) {
            if (![(NodeSortDescriptor*)self.sortAndGroupDescriptors[i] isGrouping])
                break;
            i++;
        }
    }
    else {
        // First Remove all  groupings
        while ([self.sortAndGroupDescriptors count]!=0) {
            if ([(NodeSortDescriptor*)self.sortAndGroupDescriptors[i] isGrouping])
                [self.sortAndGroupDescriptors removeObjectAtIndex:0];
            else
                break;
        }
        // i = 0 => will insert on the first element of the array
    }
    [self.sortAndGroupDescriptors insertObject:sortDesc atIndex:i];
}


-(NSArray*) getTableViewSelectedURLs {
   NSLog(@"NodeViewController.getTableViewSelectedURLs: should be overriden");
    return nil;
}

-(void) setTableViewSelectedURLs:(NSArray*) urls {
   NSLog(@"NodeViewController.setTableViewSelectedURLs: should be overriden");
}

-(NSArray*) getSelectedItems {
    NSLog(@"NodeViewController.getSelectedItems: should be overriden");
    return nil;
}

- (NSArray*)getSelectedItemsForContextMenu {
    NSLog(@"NodeViewController.getSelectedItemsForContextMenu: should be overriden");
    return nil;
}

-(TreeItem*) getLastClickedItem {
    NSLog(@"NodeViewController.getLastClickedItem: should be overriden");
    return nil;
}

-(void) startBusyAnimations {
    // TODO:!!!! Put a timer of 500ms to delay the animations
    // If animations are stopped before 500ms the animations aren't done.
    NSLog(@"NodeViewController.startBusyAnimations: should be overriden");
}
-(void) stopBusyAnimations {
    NSLog(@"NodeViewController.stopBusyAnimations: should be overriden");
}
@end
