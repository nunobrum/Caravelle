//
//  NodeViewController.m
//  Caravelle
//
//  Created by Viktoryia Labunets on 04/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "NodeViewController.h"

NSDragOperation validateDrop(id<NSDraggingInfo> info,  TreeItem* destItem) {

    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSDragOperation  supportedMask = NSDragOperationNone;
    NSDragOperation validatedOperation;
    NSArray *ptypes;
    NSUInteger modifiers = [NSEvent modifierFlags];

    sourceDragMask = [info draggingSourceOperationMask];
    pboard = [info draggingPasteboard];
    ptypes =[pboard types];

    /* Limit the options in function of the dropped Element */
    // The sourceDragMask should be an or of all the possiblities, and not the only first one.
    if ( [ptypes containsObject:NSFilenamesPboardType] ) {
        supportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
    if ( [ptypes containsObject:(id)NSURLPboardType] ) {
        supportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
    else if ( [ptypes containsObject:(id)kUTTypeFileURL] ) {
        supportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
#ifdef USE_UTI
    else if ( [ptypes containsObject:(id)kTreeItemDropUTI] ) {
        suportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
#endif

    sourceDragMask &= supportedMask; // The offered types and the supported types.


    /* Limit the Operations depending on the Destination Item Class*/
    if ([destItem itemType] == ItemTypeBranch) {
        sourceDragMask &= (NSDragOperationMove + NSDragOperationCopy + NSDragOperationLink);
    }
    else if ([destItem itemType] == ItemTypeLeaf) {
        sourceDragMask &= (NSDragOperationGeneric);
    }
    else {
        sourceDragMask = NSDragOperationNone;
    }

    /* Use the modifiers keys to select */
    //if (modifiers & NSShiftKeyMask) {
    //}
    //TODO:!! Use Space to cycle through the options
    if (modifiers & NSAlternateKeyMask) {
        if (modifiers & NSCommandKeyMask) {
            if      (sourceDragMask & NSDragOperationLink)
                validatedOperation=  NSDragOperationLink;
            else if (sourceDragMask & NSDragOperationGeneric)
                validatedOperation=  NSDragOperationGeneric;
        }
        else {
            if      (sourceDragMask & NSDragOperationCopy)
                validatedOperation=  NSDragOperationCopy;
            else if (sourceDragMask & NSDragOperationMove)
                validatedOperation=  NSDragOperationMove;
            else if (sourceDragMask & NSDragOperationGeneric)
                validatedOperation=  NSDragOperationGeneric;
            else
                validatedOperation= NSDragOperationNone;
        }
        //if (modifiers & NSControlKeyMask) {
    }
    else {
        if      (sourceDragMask & NSDragOperationMove)
            validatedOperation=  NSDragOperationMove;
        else if (sourceDragMask & NSDragOperationCopy)
            validatedOperation=  NSDragOperationCopy;
        else if (sourceDragMask & NSDragOperationLink)
            validatedOperation=  NSDragOperationLink;
        else if (sourceDragMask & NSDragOperationGeneric)
            validatedOperation=  NSDragOperationGeneric;
        else
            validatedOperation= NSDragOperationNone;
    }

    // TODO:!!! Implement the Link Operation
    if (validatedOperation ==  NSDragOperationLink)
        validatedOperation=  NSDragOperationNone;

    return validatedOperation;
}

BOOL acceptDrop(id < NSDraggingInfo > info, TreeItem* destItem, NSDragOperation operation, id fromObject) {
    BOOL fireNotfication = NO;
    NSString *strOperation;
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];

    if ([destItem itemType] == ItemTypeLeaf) {
        // TODO: !! Dropping Application on top of file or File on top of Application
        NSLog(@"BrowserController.acceptDrop: - Not impplemented Drop on Files");
        // TODO:! IDEA Maybe an append/Merge/Compare can be done if overlapping two text files
    }
    else if ([destItem itemType] == ItemTypeBranch) {
        if (operation == NSDragOperationCopy) {
            strOperation = opCopyOperation;
            fireNotfication = YES;
        }
        else if (operation == NSDragOperationMove) {
            strOperation = opMoveOperation;
            fireNotfication = YES;

            // Check whether the destination item is equal to the parent of the item do nothing
            for (NSURL* file in files) {
                NSURL *folder = [file URLByDeletingLastPathComponent];
                if ([[destItem path] isEqualToString:[folder path]]) // Avoiding NSURL isEqualTo: since it can cause problems with bookmarked URLs
                {
                    // If true : abort
                    fireNotfication = NO;
                    return fireNotfication;
                }
            }
        }
        else if (operation == NSDragOperationLink) {
            // TODO: !!! Operation Link
        }
        else {
            // Invalid case
            fireNotfication = NO;
        }

    }
    if (fireNotfication==YES) {
        // The copy and move operations are done in the AppDelegate
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              files, kDFOFilesKey,
                              strOperation, kDFOOperationKey,
                              destItem, kDFODestinationKey,
                              fromObject, kFromObjectKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:fromObject userInfo:info];
    }
    else
        NSLog(@"BrowserController.acceptDrop: - Unsupported Operation %lu", (unsigned long)operation);
        return fireNotfication;
}



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

- (void) initController {
    self->_extendToSubdirectories = NO;
    self->_foldersInTable = YES;
    self->_filterText = nil;
    self->_currentNode = nil;
    self->_observedVisibleItems = [[NSMutableArray new] init];
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

- (NSView*) containerView {
    NSAssert(NO,@"Assert Error. This is a virtual method");
    return nil;
}

- (void) setCurrentNode:(TreeBranch*)branch {
    [self unobserveItem:self.currentNode];
    self->_currentNode = branch;
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
}

-(void) observeItem:(TreeItem*)item {
    // Use KVO to observe for changes of its children Array
    if (![_observedVisibleItems containsObject:item]) {
        [item addObserver:self forKeyPath:kvoTreeBranchPropertyChildren options:0 context:NULL];
        [_observedVisibleItems addObject:item];
    }
}

-(void) unobserveItem:(TreeItem*)item {
    // Use KVO to observe for changes of its children Array
    if ([_observedVisibleItems containsObject:item]) {
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


- (void) orderOperation:(NSString*)operation onItems:(NSArray*)orderedItems;
 {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              orderedItems, kDFOFilesKey,
                              opOpenOperation, kDFOOperationKey,
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
    [[(id<NodeViewProtocol>)self containerView] registerForDraggedTypes:[NSArray arrayWithObjects:
                                           //OwnUTITypes
                                           //(id)kUTTypeFolder,
                                           //(id)kUTTypeFileURL,
                                           NSFilenamesPboardType,
                                           NSURLPboardType,
                                           nil]];

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
    return [(id<MYViewProtocol>)[self parentController] writeSelectionToPasteboard:pboard types:types];
}


- (void) focusOnFirstView {
    //NSLog(@"NodeViewController.focusOnFirstView: should be overriden");
    [self.view.window makeFirstResponder:self.containerView];
}

- (void) focusOnLastView {
    //NSLog(@"NodeViewController.focusOnLastView: should be overriden");
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

-(NSMutableArray*) itemsToDisplay {
    NSMutableArray *tableData;
    NSMutableIndexSet *tohide = [[NSMutableIndexSet new] init];
    /* Always uses the _treeNodeSelected property to manage the Table View */
    if ([self.currentNode itemType] == ItemTypeBranch){
        if (self.filesInSubdirsDisplayed==YES && self.foldersInTable==YES) {
            tableData = [self.currentNode itemsInBranch];
        }
        else if (self.filesInSubdirsDisplayed==YES && self.foldersInTable==NO) {
            tableData = [self.currentNode leafsInBranch];
        }
        else if (self.filesInSubdirsDisplayed==NO && self.foldersInTable==YES) {
            tableData = [self.currentNode itemsInNode];
        }
        else if (self.filesInSubdirsDisplayed==NO && self.foldersInTable==NO) {
            tableData = [self.currentNode leafsInNode];
        }

        /* if the filter is empty, doesn't filter anything */
        if (self.filterText!=nil || [self.filterText length]!=0) {
            /* Create the array of indexes to remove/hide/disable*/
            NSInteger i = 0;
            for (TreeItem *item in tableData){
                NSRange result = [[item name] rangeOfString:_filterText];
                if (NSNotFound==result.location)
                    [tohide addIndex:i];
                i++;
            }
        }
        [tableData removeObjectsAtIndexes: tohide];

    }
    return tableData;
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
