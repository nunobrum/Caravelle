//
//  TreeBranch.m
//  Caravelle
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//
#include "definitions.h"
#include "FileUtils.h"
#import "PasteboardUtils.h"

#import "TreeBranch.h"
#import "TreeBranch_TreeBranchPrivate.h"
#import "TreeLeaf.h"
#import "MyDirectoryEnumerator.h"
#import "TreeManager.h"
#import "CalcFolderSizes.h"



NSString *const kvoTreeBranchPropertyChildren = @"childrenArray";
NSString *const kvoTreeBranchPropertySize     = @"AllocatedSize";
//NSString *const kvoTreeBranchReleased = @"releaseItem";

//static NSOperationQueue *localOperationsQueue() {
//    static NSOperationQueue *queue= nil;
//    if (queue==nil)
//        queue= [[NSOperationQueue alloc] init];
// We limit the concurrency to see things easier for demo purposes. The default value NSOperationQueueDefaultMaxConcurrentOperationCount will yield better results, as it will create more threads, as appropriate for your processor
//[queue setMaxConcurrentOperationCount:2];

//    return queue;
//}

//NSMutableArray *folderContentsFromURL(NSURL *url, TreeBranch* parent) {
//    NSMutableArray *children = [[NSMutableArray alloc] init];
//    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:url WithMode:BViewBrowserMode];
//
//    for (NSURL *theURL in dirEnumerator) {
//        TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:parent];
//        [children addObject:newObj];
//    }
//    return children;
//}

/* Computes the common path between all paths in the array */
NSString* commonPathFromItems(NSArray* itemArray) {
    NSArray *common_path = nil;
    NSArray *file_path;
    NSInteger ci=0;
    for (TreeItem *item in itemArray) {
        if (common_path==nil)
        {
            common_path = [item pathComponents];
            ci = [common_path count]-1; /* This will exclude the file name */
        }
        else
        {
            NSInteger i;
            file_path = [item pathComponents];
            if ([file_path count]<ci)
                ci = [file_path count];
            for (i=0; i< ci; i++) {
                if (NO==[[common_path objectAtIndex:i] isEqualToString:[file_path objectAtIndex:i]]) {
                    ci = i;
                    break;
                }
            }
        }
    }
    if (ci==0) {
        return @"/";
    }
    else {
        NSRange r;
        r.location = 0;
        r.length = 0+ci;
        return  [NSString pathWithComponents:[common_path objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:r]]];
    }

}
//NSArray* treesContaining(NSArray* treeItems) {
//    NSMutableArray *treeRoots = [[NSMutableArray alloc] init];
//    
//    for (TreeItem *item in treeItems) {
//        BOOL found = NO;
//        // Check if existing Tree Roots
//        for (TreeBranch *parent in treeRoots) {
//            if ([parent canContainURL:item.url]) {
//                found = YES;
//                break; // The parent was found, no need to add anything
//            }
//        }
//        // If not found.
//        if (!found) {
//            //Check if there is a parent
//            TreeBranch *newBranch=(TreeBranch*)item.parent;
//            // If not creates it
//            if (newBranch==nil) {
//                NSURL *parentURL = [item.url URLByDeletingLastPathComponent];
//                newBranch = (TreeBranch*)[appTreeManager addTreeItemWithURL:parentURL askIfNeeded:YES];
//                //NSAssert(newBranch!=nil, @"treesContaining. Failed to get the parent");
//                assert(newBranch);
//            }
//            // Now will check it it contains one of the existing
//            NSUInteger i = 0;
//            while (i < [treeRoots count] ) {
//                if ([newBranch canContainURL: [(TreeBranch*)treeRoots[i] url]]) {
//                    [treeRoots removeObjectAtIndex:i];
//                }
//                else
//                    i++;
//            }
//            // Then adds the new root
//            [treeRoots addObject:newBranch];
//        }
//        // If yes, just add it to its children
//        // else ask one from the Tree Manager and add it to the treeRoots
//    }
//    return treeRoots;
//}


@implementation TreeBranch

-(ItemType) itemType {
    return ItemTypeBranch;
}


#pragma mark Initializers
-(instancetype) initWithURL:(NSURL*)url parent:(TreeBranch*)parent {
    self = [super initWithURL:url parent:parent];
    self->_children = nil;
    [self _invalidateSizes]; // Attribute used to store the value of the computed folder size
    
    return self;
}

-(instancetype) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent {
    self = [super initWithMDItem:mdItem parent:parent];
    self->_children = nil;
    [self _invalidateSizes]; // Attribute used to store the value of the computed folder size
    return self;
}

-(void) deinit {
    [self _releaseChildren];
    self->_children = nil;
    [self _invalidateSizes];
    [super deinit];
}

-(void) _releaseChildren {
//    for (TreeItem *item in _children) {
//        // NOTE: isKindOfClass is preferred over itemType.
//        if ([item isKindOfClass:[TreeBranch class]]) {
//            [(TreeBranch*)item _releaseChildren];
//        }
//    }
    [_children removeAllObjects];
}

-(void) releaseChildren {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
//    @synchronized(self ) {
//        for (TreeItem *item in _children) {
//            // NOTE: isKindOfClass is preferred over itemType.
//            if ([item isKindOfClass:[TreeBranch class]]) {
//                [(TreeBranch*)item releaseChildren];
//            }
//        }
//    }
    [_children removeAllObjects];
    
    [self notifyDidChangeTreeBranchPropertyChildren];   // This will inform the observer about change
}


+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
    TreeBranch *tree = [TreeBranch alloc];
    return [tree initFromEnumerator:dirEnum URL:rootURL parent:parent cancelBlock:cancelBlock];
}

-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
    self = [self initWithURL:rootURL parent:parent];
    /* Since the instance is created now, there is no problem with thread synchronization */
    for (NSURL *theURL in dirEnum) {
        //NSLog(@"%@",theURL);
        [self _addURLnoRecurr:theURL];
        if (cancelBlock())
            break;
    }
    return self;
}


#pragma mark - Menu support
-(BOOL) respondsToMenuTag:(EnumContextualMenuItemTags)tag {
    BOOL answer;
    switch (tag) {
            // Enables these ones
        case menuClipPaste:
        case menuNewFolder:
        case menuAddFavorite:
            answer = YES;
            break;
            
        // Invalidates these ones
        case menuView:
            answer = NO;
            break;
            
        default:
            answer = [super respondsToMenuTag:tag];
            break;
    }
    
    return answer;
}


#pragma mark KVO methods

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {

    BOOL automatic = NO;
    if ([theKey isEqualToString:kvoTreeBranchPropertyChildren] ||
        [theKey isEqualToString:kvoTreeBranchPropertySize]) {
        automatic = NO;
    }
    else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}

-(void) notifyDidChangeTreeBranchPropertyChildren {
    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    TreeItem *cursor = self->_parent;
    while (cursor!=nil) {
        [cursor willChangeValueForKey:kvoTreeBranchPropertySize];
        [cursor didChangeValueForKey:kvoTreeBranchPropertySize];  // This will inform the observer about change
        cursor = cursor->_parent;
    }
}

#pragma mark -
#pragma mark Children Manipulation

-(NSMutableArray*) children {
    return self->_children;
}

-(void) initChildren {
    self->_children = [[NSMutableArray alloc] init];
}

-(void) _setChildren:(NSMutableArray*) children {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self) {
        self->_children = children;
    }
    [self notifyDidChangeTreeBranchPropertyChildren];  // This will inform the observer about change

}

-(BOOL) removeChild:(TreeItem*)item {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self) {
        // Leaving this code here as it may come later to clean up the class
        //if ([item isFolder]) {
        //    [item dealloc];
        //}
        [self->_children removeObject:item];
    }
    [self notifyDidChangeTreeBranchPropertyChildren];  // This will inform the observer about change
    return YES;
}

-(BOOL) addChild:(TreeItem*)item {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self) {
        if (self->_children==nil)
            self->_children = [[NSMutableArray alloc] init];
        [self->_children addObject:item];
        [item setParent:self];
    }
    [self notifyDidChangeTreeBranchPropertyChildren];  // This will inform the observer about change
    return YES;
}

-(BOOL) moveChild:(TreeItem*)item {
    TreeBranch *old_parent = [item parent];
    [self addChild:item];
    if (old_parent) { // Remove from old parent
        [old_parent removeChild:item];
    }
    return YES;
}

-(NSInteger) _releaseReleasedChildren {
    NSInteger released = 0;
    NSUInteger index = 0;
    
    // No Synchronized clause here. Its handled in the method calling this one.
    
    while (index < [_children count]) {
        TreeItem *item = [_children objectAtIndex:index];
        if ([item hasTags:tagTreeItemRelease]) {
            // NOTE: isKindOfClass is preferred over itemType.
            if ([item isKindOfClass:[TreeBranch class]]) {
                [(TreeBranch*)item deinit]; // This branch will be completely deleted
            }
            else if ([item isKindOfClass:[TreeLeaf class]]) {
                [(TreeLeaf*)item removeFromDuplicateRing]; // Removing itself from the duplicate lists
            }
            //NSLog(@"Removing %@", [item path]);
            [_children removeObjectAtIndex:index];
            released++;
        }
        else
            index++;
    }
    return released;
}

-(NSInteger) releaseReleasedChildren {
    NSInteger released = 0;
    @synchronized(self) {
        released += [self _releaseReleasedChildren];
    }
    if (released > 0) {
        [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
        [self notifyDidChangeTreeBranchPropertyChildren];   // This will inform the observer about change
    }
    return released;
}

#pragma mark -
#pragma mark chidren access

-(TreeItem*) childWithName:(NSString*) name {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([[item name] isEqualToString: name]) {
                return item;
            }
        }
    }
    return nil;
}

-(TreeItem*) childWithName:(NSString*) name class:(id)cls {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([[item name] isEqualToString: name] && [item isKindOfClass:cls]) {
                return item;
            }
        }
    }
    return nil;
}


//-(TreeItem*) childWithURL:(NSURL*) aURL {
//    @synchronized(self) {
//        for (TreeItem *item in self->_children) {
//            NSURL *itemURL = URL(item);
//            if ([itemURL isEqual:aURL]) {
//                return item;
//            }
//        }
//    }
//    return nil;
//}
//
//-(TreeItem*) childContainingURL:(NSURL*) aURL {
//    @synchronized(self) {
//        if ([self canContainURL:aURL]) {
//            for (TreeItem *item in self->_children) {
//                if ([item.reprObj canContainURL:aURL]) {
//                    return item;
//                }
//            }
//        }
//    }
//    return nil;
//}
//
//-(TreeItem*) childContainingPath:(NSString*) aPath {
//    @synchronized(self) {
//        if ([self canContainPath:aPath]) {
//            for (TreeItem *item in self->_children) {
//                if ([item canContainPath:aPath]) {
//                    return item;
//                }
//            }
//        }
//    }
//    return nil;
//}

-(NSInteger) indexOfItem:(TreeItem*)item {
    return [_children indexOfObject:item];
}

-(TreeItem*) itemAtIndex:(NSUInteger)index {
    return [self->_children objectAtIndex:index];
}

-(BOOL) removeItemAtIndex:(NSUInteger)index {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self) {
        // Leaving this code here as it may come later to clean up the class
        //if ([item isFolder]) {
        //    [item dealloc];
        //}
        [self->_children removeObjectAtIndex:index];
    }
    [self notifyDidChangeTreeBranchPropertyChildren];  // This will inform the observer about change
    return YES;
}

-(BOOL) replaceItem:(TreeItem*)original with:(TreeItem*)replacement {
    NSInteger index = [self->_children indexOfObject:original];
    if (index != NSNotFound) {
        [self->_children setObject:replacement atIndexedSubscript:index];
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark Refreshing contents

-(void) tagRefreshStart {
    [self setTag: tagTreeItemUpdating];
}

-(void) tagRefreshFinished {
    [self resetTag:(tagTreeItemUpdating+tagTreeItemDirty) ]; // Resets updating and dirty
    [self setTag: tagTreeItemScanned];
    
    // Sets the flag accordingly to the status of
    if ([[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_SEE_HIDDEN_FILES])
        [self setTag:tagTreeHiddenPresent];
    else
        [self resetTag:tagTreeHiddenPresent];
}

-(BOOL) needsRefresh {

    TreeItemTagEnum tag;
    // TODO:? Verify Atomicity and get rid of synchronized clause if OK
    @synchronized(self) {
         tag = [self tag];
    }
    
    // If its not already updating or already released
    if ((tag & (tagTreeItemUpdating+tagTreeItemRelease))==0) {
        
        // if was signaled as invalid
        if ((tag & tagTreeItemDirty   )!=0)
            return YES;
    
        // Still will check if display mode was changed
         if ([[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_SEE_HIDDEN_FILES] == ((tag & tagTreeHiddenPresent)==0))
             return YES;
        
        // if it was never scanned at least one time
        if ((tag & tagTreeItemScanned)==0)
            return YES;
    }
    return NO;
}

- (void) refresh {
    if ([self needsRefresh]) {
        [self tagRefreshStart];
        //NSLog(@"TreeBranch.refresh:(%@)", [self path]); //, [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_SEE_HIDDEN_FILES]);
        [browserQueue addOperationWithBlock:^(void) { 
            // Using a new ChildrenPointer so that the accesses to the _children are minimized

            MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:[self url] WithMode:BViewBrowserMode];

            [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
            @synchronized(self) {
                // Set all items as candidates for release
                for (TreeItem *item in _children) {
                    [item setTag:tagTreeItemRelease];
                }
                self->size_files = -1; // Invalidates the previous calculated size
                self->size_total = -1;
                self->size_allocated = -1;
                self->size_total_allocated = -1;

                for (NSURL *theURL in dirEnumerator) {
                    bool found=NO;
                    NSString *urlName = [theURL lastPathComponent];
                    /* Retrieves existing Element */
                    for (TreeItem *it in self->_children) {
                        if ([[it name] isEqualToString:urlName]) { // Comparing paths as comparing URLs is dangerous
                            // Found it
                            // resets the release Flag. Doesn't neet to be deleted
                            [it resetTag:tagTreeItemRelease];
                            [it updateFileTags];
                            found = YES;
                            break;
                        }
                    }
                    if (!found) { /* If not found creates a new one */
                        TreeItem *item = [TreeItem treeItemForURL:theURL parent:self];
                        if  (item != nil) {
                            // NOTE: isKindOfClass is preferred over itemType.
                            if ([item isKindOfClass:[TreeBranch class]]) {
                                [self setTag: tagTreeItemDirty]; // When it is created it invalidates it
                                [((TreeBranch*)item) _invalidateSizes];
                            }
                            if (self->_children==nil)
                                self->_children = [[NSMutableArray alloc] init];
                            [self->_children addObject:item];
                            [item setParent:self];
                        }
                        else {
                            NSLog(@"TreeBranch.refresh: Failed to create item for URL %@", theURL);
                        }
                    }
                } // for

                // Now going to release the disappeard items
                [self _releaseReleasedChildren];
                [self tagRefreshFinished];
            } // synchronized
            [self notifyDidChangeTreeBranchPropertyChildren];   // This will inform the observer about change
        }];
    }
}

/*
-(void) _performSelectorInUndeveloppedBranches:(SEL)selector {
    if (self->_children!= nil) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                if ([item isFolder]) {
                    [(TreeBranch*)item _performSelectorInUndeveloppedBranches:selector];
                }
            }
        }
    }
    else {
        if ([self respondsToSelector:selector]) {
            [self performSelector:selector];
        }
    }
}
*/

#pragma mark - Size related methods.

-(BOOL) needsSizeCalculation {
    return YES;
}

-(void) _invalidateSizes {
    self->size_files = -1;
    self->size_total = -1;
    self->size_allocated = -1;
    self->size_total_allocated = -1;
}

-(void) _propagateSize {
    BOOL all_sizes_available = YES; // Starts with an invalidated number
    if (self->_children!=nil) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                // NOTE: isKindOfClass is preferred over itemType.
                if ([item isKindOfClass:[TreeBranch class]] &&
                     ((TreeBranch*)item)->size_files == -1) { // Only one of the sizes is tested. It's OK
                    all_sizes_available = NO;
                    break;
                }
            }
        }
    }
    if (all_sizes_available) { // Will update
        [self willChangeValueForKey:kvoTreeBranchPropertySize];
        [self resetTag:tagTreeSizeCalcReq];
        [self didChangeValueForKey:kvoTreeBranchPropertySize];
        // and propagates to parent
        if (self->_parent)
            [self->_parent _propagateSize];
    }
}

-(void) setSizes:(long long)files allocated:(long long)allocated total:(long long)total totalAllocated:(long long) totalallocated {
    [self willChangeValueForKey:kvoTreeBranchPropertySize];
    @synchronized(self) {
        self->size_files           = files;
        self->size_allocated       = allocated;
        self->size_total           = total;
        self->size_total_allocated = totalallocated;
        [self resetTag:tagTreeSizeCalcReq];
    }
    [self didChangeValueForKey:kvoTreeBranchPropertySize];
    if (self->_parent) {
        [self->_parent _propagateSize];
        // This will trigger a kvoTreeBranchPropertySize from the parent in case of
        // completion of the directory size computation
    }
}

-(void) sizeCalculationCancelled {
    if ([self hasTags:tagTreeSizeCalcReq]) {
        [self willChangeValueForKey:kvoTreeBranchPropertySize];
        [self _invalidateSizes];
        [self resetTag:tagTreeSizeCalcReq];
        [self didChangeValueForKey:kvoTreeBranchPropertySize];
        // and propagates to parent
        if (self->_parent) {
            [self->_parent sizeCalculationCancelled];
        }
    }
}

-(void) _computeAllocatedSize {
    if ([self hasTags:tagTreeSizeCalcReq]==0) {
        [self setTag:tagTreeSizeCalcReq];
        CalcFolderSizes * op = [[CalcFolderSizes alloc] init];
        [op setItem:self];
        [op setQueuePriority:NSOperationQueuePriorityVeryLow];
        [op setThreadPriority:0.5];
        [lowPriorityQueue addOperation:op];
    }
}

-(void) calculateSize {
    if (self->_children!= nil) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                // NOTE: isKindOfClass is preferred over itemType.
                if ([item isKindOfClass:[TreeBranch class]]) {
                    [(TreeBranch*)item calculateSize];
                }
            }
        }
    }
    else {
        [self _computeAllocatedSize];
    }
}
//
//-(void) _expandTree {
//    //NSLog(@"Expanding path %@", self.path);
//    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:[self url] WithMode:BViewCatalystMode];
//
//    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
//    @synchronized(self) {
//        self->_children = [[NSMutableArray alloc] init];
//        TreeBranch *cursor = self;
//        NSMutableArray *cursorComponents = [NSMutableArray arrayWithArray:[[self url] pathComponents]];
//        unsigned long current_level = [cursorComponents count]-1;
//
//
//        for (NSURL *theURL in dirEnumerator) {
//            BOOL ignoreURL = NO;
//            NSArray *newURLComponents = [theURL pathComponents];
//            unsigned long target_level = [newURLComponents count]-2;
//            while (target_level < current_level) { // Needs to go back if the new URL is at a lower branch
//                cursor = (TreeBranch*) cursor->_parent;
//                current_level--;
//            }
//            while (target_level != current_level &&
//                   [cursorComponents[current_level] isEqualToString:newURLComponents[current_level]]) {
//                // Must navigate into the right folder
//                if (target_level <= current_level) { // The equality is considered because it means that the components at this level are different
//                    // steps down in the tree
//                    cursor = (TreeBranch*) cursor->_parent;
//                    current_level--;
//                }
//                else { // Needs to grow the tree
//                    current_level++;
//                    NSURL *pathURL = [cursor.url URLByAppendingPathComponent:newURLComponents[current_level] isDirectory:YES];
//                    cursorComponents[current_level] = newURLComponents[current_level];
//                    TreeItem *child = [TreeItem treeItemForURL:pathURL parent:cursor];
//                    if (child!=nil) {
//                        if (cursor->_children==nil) {
//                            cursor->_children = [[NSMutableArray alloc] init];
//                        }
//                        [cursor->_children addObject:child];
//                        if ([child isFolder])
//                        {
//                            cursor = (TreeBranch*)child;
//                            cursor->_children = [[NSMutableArray alloc] init];
//                        }
//                        else {
//                            // Will ignore this child and just addd the size to the current node
//                            [dirEnumerator skipDescendents];
//                            // IGNORE URL
//                            ignoreURL = YES;
//                        }
//                    }
//                    else {
//                        NSAssert(NO, @"TreeBranch.TreeBranch._expandTree: Couldn't create path %@ \nwhile creating %@",pathURL, theURL);
//                    }
//                }
//
//            }
//            if (ignoreURL==NO)  {
//                TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:cursor];
//                if (newObj!=nil) {
//                    if (cursor->_children==nil) {
//                        cursor->_children = [[NSMutableArray alloc] init];
//                    }
//                    [cursor->_children addObject:newObj];
//                    // if it's a folder jump into it, so that the next URL can be directly inserted
//                    if ([newObj isKindOfClass:[TreeBranch class]]) {
//                        cursor = (TreeBranch*)newObj;
//                        cursor->_children = [[NSMutableArray alloc] init];
//                        current_level++;
//                        cursorComponents[current_level] = newURLComponents[current_level];
//
//                    }
//                }
//                else {
//                    NSLog(@"TreeBranch._addURLnoRecurr: - Couldn't create item %@",theURL);
//                }
//            }
//        }
//    }
//    [self notifyDidChangeTreeBranchPropertyChildren];  // This will inform the observer about change
//}

#pragma mark - Flat Operation

/* This selector searches for TreeBranches which children have not yet been initialized.
 While doing so, it will return a negative number 
 */
-(NSInteger) _hasUndeveloppedFoldersTillDepth:(NSInteger) depth {
    if (self->_children!= nil) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                if ([item isFolder] && depth > 0) {
                    NSInteger answer = [(TreeBranch*)item _hasUndeveloppedFoldersTillDepth:depth-1];
                    if (answer < 0)
                        return answer;
                }
            }
        }
    }
    else {
        return -depth;
    }
    return depth;
}


-(BOOL) needsFlatScan:(NSInteger)depth {
    return [self _hasUndeveloppedFoldersTillDepth:depth] < 0;
}

-(BOOL) canBeFlat {
    return YES;
}

-(void) harverstUndeveloppedFolders:(NSMutableArray*)collector tillDepth:(NSInteger) depth {
    
    if (self->_children!= nil) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                if ([item isFolder] && depth > 0) {
                    [(TreeBranch*)item harverstUndeveloppedFolders:collector tillDepth:depth-1];
                }
            }
        }
    }
    else {
        [collector addObject:self];
    }
}

-(void) requestFlatForView:(id)view tillDepth:(NSInteger)depth {
    NSInteger needsFlat = [self _hasUndeveloppedFoldersTillDepth:depth];
    if (needsFlat < 0) {
        // Send notification to request Expansion
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              opFlatOperation, kDFOOperationKey,
                              view, kDFOFromViewKey, // The view is sent because the operation can take longer and selected view can change
                              self, kDFODestinationKey, // This has to be placed in last because it can be nil
                              [NSNumber numberWithInteger:depth], kDFODepthKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:view userInfo:info];
    }
}


#pragma mark -
#pragma mark Tree Access
/*
 * All these methods must be changed for recursive in order to support the searchBranches
 */

-(TreeItem*) getNodeWithPathComponents:(NSArray*) pComp {
    //NSLog(@"DEBUG;TreeBranch._getNodeWithPathComponents:(%@)", pComp);
    
    NSArray *cpself = [self pathComponents];
    
    NSUInteger cpsc = [cpself count];
    NSUInteger cpuc = [pComp count];
    if (cpsc> cpuc) // Sanity check, if the given url has less path components that itself, it can't possibly contain it
        return nil;
    
    NSUInteger i;
    for (i = 0 ; i < cpsc ; i++) {
        if (NO == [cpself[i] isEqualToString:pComp[i]]) {
            return nil;
        }
    }
    TreeBranch *cursor = self;
    while (i < cpuc && cursor != nil) {
        cursor = (TreeBranch*)[cursor childWithName:pComp[i++] class:[TreeBranch class]];
    }
    if( i == cpuc-1) // discounts 1 because of tree branch class condition
        return [cursor childWithName:pComp[i]];
    else
        return cursor;
}

-(TreeItem*) _nearestItemWithPathComponents:(NSArray*) pComp {
    //NSLog(@"DEBUG;TreeBranch._huntPathComponents:(%@)", pComp);
    
    NSArray *cpself = [self pathComponents];
    
    NSUInteger cpsc = [cpself count];
    NSUInteger cpuc = [pComp count];
    if (cpsc> cpuc) // Sanity check, if the given url has less path components that itself, it can't possibly contain it
        return nil;
    
    NSUInteger i;
    for (i = 0 ; i < cpsc ; i++) {
        if (NO == [cpself[i] isEqualToString:pComp[i]]) {
            return nil;
        }
    }
    TreeBranch *cursor = self;
    while (i < cpuc) {
        id temp = (TreeBranch*)[cursor childWithName:pComp[i]];
        if (temp==nil) {
            return cursor;
        }
        cursor = temp;
        i++;
    }
    return cursor;
}

-(TreeItem*) getNodeWithURL:(NSURL*)url {
    NSArray *urlComponents = [url pathComponents];
    return [self getNodeWithPathComponents:urlComponents];
    
}

-(TreeItem*) getNodeWithPath:(NSString*)path {
    //NSLog(@"TreeBranch.getNodeWithURL:(%@)", url);
    return [self getNodeWithPathComponents:path.pathComponents];
}


-(TreeItem*) addURL:(NSURL*)theURL {
    NSArray *pcomps = [theURL pathComponents];
    id child = [self _nearestItemWithPathComponents:pcomps];
    if (child == nil) {
        // Can't be added here
        return nil;
    }
    else {
        // if it is a Leaf, it should be it. Test to make sure.
        if ([[child path] isEqualToString:[theURL path]]) { // Avoiding NSURL isEqualTo: since it can cause problems with bookmarked URLs
            return child;
        }
    }
    //NSLog(@"DEBUG %@.addURL %@", self.url, theURL);
    @synchronized(self) {
        if (self->_children == nil)
            self->_children = [[NSMutableArray alloc] init];
    }
    unsigned long level = [[self pathComponents] count];
    unsigned long leaf_level = [pcomps count]-1;
    if (level < leaf_level) {
        NSURL *pathURL = [self.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
        child = [TreeItem treeItemForURL:pathURL parent:self];
        [self addChild:child];
        if ([child isFolder]) {
            return [(TreeBranch*)child addURL:theURL];
        }
    }
    else if (level == leaf_level) {
        TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:self];
        [self addChild:newObj];
        return newObj; /* Stops here Nothing More to Add */
    }
    else if ([[self path] isEqualToString:[theURL path]]) { // Avoiding NSURL isEqualTo: since it can cause problems with bookmarked URLs
            return self; // This condition is equal to level-1==leaf_level
    }
    NSLog(@"TreeBranch.addURL: URL(%@) is not added to self(%@)", theURL, self);
    return nil;
}


/* Private Method : This is so that we don't have Manual KVO clauses inside. All calling methods should have it */
//-(TreeItem*) _addURLnoRecurr:(NSURL*)theURL {
//    /* Check first if base path is common */
//    //NSRange result;
//    if (theURL==nil) {
//        NSLog(@"TreeBranch._addURLnoRecurr: - The received URL is null");
//        assert(NO);
//        return nil;
//    }
//   
//    @synchronized(self) {
//        if (self->_children == nil)
//            self->_children = [[NSMutableArray alloc] init];
//    }
//    TreeBranch *cursor = self;
//    NSArray *pcomps = [theURL pathComponents];
//    unsigned long level = [[_url pathComponents] count];
//    unsigned long leaf_level = [pcomps count]-1;
//    while (level < leaf_level) {
//        NSURL *pathURL = [cursor.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
//        TreeItem *child = [cursor childContainingURL:pathURL];
//        if (child==nil) {/* Doesnt exist or if existing is not branch*/
//            /* This is a new Branch Item that will contain the URL*/
//            child = [TreeItem treeItemForURL:pathURL parent:self];
//            if (child!=nil) {
//                @synchronized(cursor) {
//                    [cursor->_children addObject:child];
//                }
//            }
//            else {
//                NSLog(@"TreeBranch._addURLnoRecurr: Couldn't create path %@",pathURL);
//            }
//        }
//        if ([child isFolder])
//        {
//            cursor = (TreeBranch*)child;
//            if (cursor->_children==nil) {
//                cursor->_children = [[NSMutableArray alloc] init];
//            }
//        }
//        else {
//            // Will ignore this child
//            NSLog(@"TreeBranch._addURLnoRecurr: Error:%@ can't be added to %@", theURL, pathURL);
//            return nil;
//        }
//        level++;
//    }
//    // Checks if it exists ; The base class is provided TreeItem so that it can match anything
//    TreeItem *newObj = [cursor childWithName:[pcomps objectAtIndex:level] class:[TreeItem class]];
//    if  (newObj==nil) { // It doesn't exist
//        newObj = [TreeItem treeItemForURL:theURL parent:cursor];
//        if (newObj!=nil) {
//            @synchronized(cursor) {
//                [cursor->_children addObject:newObj];
//            }
//        }
//        else {
//            NSLog(@"TreeBranch._addURLnoRecurr: - Couldn't create item %@",theURL);
//        }
//    }
//    return newObj; /* Stops here Nothing More to Add */
//}

-(BOOL) addTreeItem:(TreeItem*) newItem {
    NSLog(@"DEBUG TreeBranch.addTreeItem:");
    @synchronized(self) {
        if (self->_children == nil)
            self->_children = [[NSMutableArray alloc] init];
    }
    TreeBranch *cursor = self;
    NSArray *pcomps = [newItem pathComponents];
    unsigned long level = [[self pathComponents] count];
    unsigned long leaf_level = [pcomps count]-1;
    while (level < leaf_level) {
        TreeItem *child = [cursor childWithName:pcomps[level] class:[TreeBranch class]];
        if (child==nil) {/* Doesnt exist or if existing is not branch*/
            /* This is a new Branch Item that will contain the URL*/
            NSURL *pathURL = [cursor.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
            child = [TreeItem treeItemForURL:pathURL parent:cursor];
                
            if (child!=nil) {
                @synchronized(cursor) {
                    [cursor->_children addObject:child];
                }
            }
            else {
                NSLog(@"TreeBranch._addURLnoRecurr: Couldn't create path %@",pathURL);
            }
        }
        if ([child isFolder])
        {
            cursor = (TreeBranch*)child;
            if (cursor->_children==nil) {
                cursor->_children = [[NSMutableArray alloc] init];
            }
        }
        else {
            // Will ignore this child
            NSLog(@"TreeBranch._addURLnoRecurr: Error:%@ can't be added to %@", newItem, cursor);
            return NO;
        }
        level++;
    }
    // Checks if it exists ; The base class is provided TreeItem so that it can match anything
    TreeItem *replacedChild = [cursor childWithName:[newItem name] class:[TreeItem class]];
    @synchronized(cursor) {
        if (replacedChild) {
            if (replacedChild != newItem) {
                // Replaces
                NSInteger idx = [cursor->_children indexOfObject:replacedChild];
                assert(idx != NSNotFound);
                [cursor->_children replaceObjectAtIndex:idx withObject:newItem];
            }
            //else:  is the same, no need to do anything
        }
        else {
            [cursor->_children addObject:newItem];
        }
    }
    [newItem setParent:cursor];
    return YES; /* Stops here Nothing More to Add */
}

#pragma mark -
#pragma mark size getters

/* Computes the total of all the files in the current Branch */
-(long long) sizeOfNode {
    long long total=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                // NOTE: isKindOfClass is preferred over itemType.
                if ([item isKindOfClass:[TreeBranch class]]) {
                    total+=[[item exactSize] longLongValue];
                }
            }
        }
    }
    return total;
}

/* Computes the total size of all the files contains in all subdirectories */
/* If one directory is not completed, it will return nil which invalidates the sum */
-(NSNumber*) exactSize {
    if (self->size_files == -1) {
        long long total=0;
        NSNumber *size;
        if (self->_children!=nil) {
            @synchronized(self) {
                size = @0; // This will make the function return something if the array has no elements
                for (TreeItem *item in self->_children) {
                    size = [item exactSize] ;
                    if (size) {
                        total += [size longLongValue];
                    }
                    else {
                        break;
                    }
                }
            }
        }
        else if (_tag & tagTreeItemScanned)
            size = @0; // Initializing as zero. If the directory is empty
        else
            size = nil;
        // if the allocated size is calculated and the size not, use the allocated size
        if (size != nil) {
            // Successfully found the size of the Folder
            self->size_files = total;
        }
        else {
            self->size_files = -1;
            return nil;
        }
    }
    return [NSNumber numberWithLongLong: self->size_files];
}

-(NSNumber*) allocatedSize {
    if (self->size_allocated==-1) {
        long long total=0;
        NSNumber *size;
        if (self->_children!=nil) {
            @synchronized(self) {
                size = @0; // This will make the function return something if the array has no elements
                for (TreeItem *item in self->_children) {
                    size = [item allocatedSize] ;
                    if (size) {
                        total += [size longLongValue];
                    }
                    else {
                        break;
                    }
                }
            }
        }
        else if (_tag & tagTreeItemScanned)
            size = @0; // Initializing as zero. If the directory is empty
        else
            size = nil;
        
        // if the allocated size is calculated and the size not, use the allocated size
        if (size != nil) {
            // Successfully found the size of the Folder
            self->size_allocated = total;
        }
        else {
            self->size_allocated = -1;
            return nil;
        }
    }
    return [NSNumber numberWithLongLong: self->size_allocated];
}

-(NSNumber*) totalSize {
    if (self->size_total==-1) {
        long long total=0;
        NSNumber *size;
        if (self->_children!=nil) {
            @synchronized(self) {
                size = @0; // This will make the function return something if the array has no elements
                for (TreeItem *item in self->_children) {
                    size = [item totalSize] ;
                    if (size) {
                        total += [size longLongValue];
                    }
                    else {
                        break;
                    }
                }
            }
        }
        else if (_tag & tagTreeItemScanned)
            size = @0; // Initializing as zero. If the directory is empty
        else
            size = nil;
        
        // if the allocated size is calculated and the size not, use the allocated size
        if (size != nil) {
            // Successfully found the size of the Folder
            self->size_total = total;
        }
        else {
            self->size_total = -1;
            return nil;
        }
    }
    return [NSNumber numberWithLongLong: self->size_total];
}

-(NSNumber*) totalAllocatedSize {
    if (self->size_total_allocated==-1) {
        long long total=0;
        NSNumber *size;
        if (self->_children!=nil) {
            @synchronized(self) {
                size = @0; // This will make the function return something if the array has no elements
                for (TreeItem *item in self->_children) {
                    size = [item totalAllocatedSize] ;
                    if (size) {
                        total += [size longLongValue];
                    }
                    else {
                        break;
                    }
                }
            }
        }
        else if (_tag & tagTreeItemScanned)
            size = @0; // Initializing as zero. If the directory is empty
        else
            size = nil;
        
        // if the allocated size is calculated and the size not, use the allocated size
        if (size != nil) {
            // Successfully found the size of the Folder
            self->size_total_allocated = total;
        }
        else {
            self->size_total_allocated = -1;
            return nil;
        }
    }
    return [NSNumber numberWithLongLong: self->size_total_allocated];
}

#pragma mark - number of elements

//-(NSInteger) numberOfLeafsInNode {
//    NSInteger total=0;
//    @synchronized(self) {
//        if (self->_children!=nil) {
//            for (TreeItem *item in self->_children) {
//                if ([item isLeaf]) {
//                    total++;
//                }
//            }
//        }
//    }
//    return total;
//}

-(NSUInteger) numberOfBranchesInNode {
    NSInteger total=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                if ([item isFolder]) {
                    total++;
                }
            }
        }
    }
    return total;
}

-(NSUInteger) numberOfItemsInNode {
    @synchronized(self) {
        if (self->_children!=nil) {
            return [self->_children count]; /* This is needed to invalidate and re-scan the node */
        }
    }
    return 0;
}

// This returns the number of leafs in a branch
// this function is recursive to all sub branches
-(NSUInteger) numberOfLeafsInBranch {
    NSUInteger total=0;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isFolder]) {
                total += [(TreeBranch*)item numberOfLeafsInBranch];
            }
            else
                total++;
        }
    }
    return total;
}

// This returns the number of leafs in a branch
// this function is recursive to a given depth
//-(NSInteger) numberOLeafsInBranchTillDepth:(NSInteger) depth {
//    NSInteger total=0;
//    if (depth > 0) {
//        @synchronized(self) {
//            for (TreeItem *item in self->_children) {
//                if ([item isFolder]) {
//                    total += [(TreeBranch*)item numberOItemsInBranchTillDepth:depth-1];
//                }
//                else
//                    total++;
//            }
//        }
//    }
//    return total;
//}


// This returns the number of items in a branch
// this function is recursive to a given depth
-(NSUInteger) numberOItemsInBranchTillDepth:(NSUInteger) depth {
    NSUInteger total=0;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isFolder] && depth > 0) {
                total += [(TreeBranch*)item numberOItemsInBranchTillDepth:depth-1];
            }
            total++;
        }
    }
    return total;
}

// This returns the number of branches in a branch
// this function is recursive to a given depth
-(NSUInteger) numberOfItemsWithPredicate:(NSPredicate*)filter tillDepth:(NSUInteger) depth {
    NSUInteger total=0;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if (filter==nil || [filter evaluateWithObject:item]==YES)
            {
                if ([item isFolder] && depth > 0) {
                    total += [(TreeBranch*)item numberOfItemsWithPredicate:filter tillDepth:depth-1];
                }
                total++;
            }
        }
    }
    return total;
}

// This returns the number of branches in a branch
// this function is recursive to a given depth
-(NSUInteger) numberOfLeafItemsWithPredicate:(NSPredicate*)filter tillDepth:(NSUInteger) depth {
    NSUInteger total=0;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isFolder] && depth > 0) {
                total += [(TreeBranch*)item numberOfLeafItemsWithPredicate:filter tillDepth:depth-1];
            }
            else {
                if (filter==nil || [filter evaluateWithObject:item]==YES)
                {
                    total++;
                }
            }
        }
    }
    return total;
}

// This returns the number of branches in a branch
// this function is recursive to a given depth
-(NSUInteger) numberOfLeafsWithPredicate:(NSPredicate*)filter tillDepth:(NSUInteger) depth {
    NSUInteger total=0;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isFolder]) {
                if (depth > 0) {
                    total += [(TreeBranch*)item numberOfLeafsWithPredicate:filter tillDepth:depth-1];
                }
            }
            else {
                if (filter==nil || [filter evaluateWithObject:item]==YES)
                {
                    total++;
                }
            }
        }
    }
    return total;
}

-(NSInteger) numberItemsInBranchTill:(NSUInteger)depth
                   withBlock:(BOOL(^)(TreeItem* item, NSUInteger level))filter {
    NSInteger total=0;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            BOOL test = filter(item, depth);
            if (test) total++;
            if ([item isFolder] && depth > 0) {
                [(TreeBranch*)item numberItemsInBranchTill:depth-1
                                              withBlock:filter];
            }
        }
    }
    return total;
}

// This makes the TreeBranch enumeratable, by passing the Fast Enumerating method to the children array
-(NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len {
    return [self.children countByEnumeratingWithState:state
                                              objects:buffer
                                                count:len];
}

/* Returns if the node is expandable
 Note that if the _children is not populated it is assumed that the
 node is expandable. It is preferable to assume as yes and later correct. */
-(BOOL) isExpandable {
    if ((self->_children!=nil) && ([self numberOfBranchesInNode]!=0))
        return YES;
    return NO;
}

-(BOOL) hasChildren {
    if ((self->_children!=nil) && ([self numberOfItemsInNode]!=0))
        return YES;
    return NO;
}


//-(NSInteger) numberOfFileDuplicatesInBranch {
//    NSInteger total = 0;
//    for (TreeItem *item in _children) {
//        if ([item isFolder]) {
//            total += [(TreeBranch*)item numberOfFileDuplicatesInBranch];
//        }
//        else if ([item itemType] == ItemTypeLeaf) {
//            if ([[(TreeLeaf*)item getFileInformation] duplicateCount]!=0)
//                total++;
//        }
//    }
//    return total;
//}

#pragma mark -
#pragma mark Branch access

-(TreeBranch*) branchAtIndex:(NSUInteger) index {
    NSInteger i=0;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isFolder]) {
                if (i==index)
                    return (TreeBranch*)item;
                i++;
            }
        }
    }
    return nil;
}

-(NSIndexSet*) branchIndexes {
    NSMutableIndexSet *answer = [[NSMutableIndexSet alloc] init];
    @synchronized(self) {
        NSUInteger index = 0;
        for (TreeItem *item in self->_children) {
            if ([item isFolder]) {
                [answer addIndex:index];
            }
            index++;
        }
    }
    return answer;
}

-(TreeLeaf*) leafAtIndex:(NSUInteger) index {
    NSInteger i=0;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isLeaf]) {
                if (i==index)
                    return (TreeLeaf*)item;
                i++;
            }
        }
    }
    return nil;
}

#pragma mark -
#pragma mark collector methods

-(NSMutableArray*) itemsInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        [answer addObjectsFromArray:self->_children];
        return answer;
    }
    return NULL;
}

//-(NSMutableArray*) itemsInNodeWithPredicate:(NSPredicate *)filter {
//    @synchronized(self) {
//        NSMutableArray *answer = [[NSMutableArray new] init];
//        if (filter==nil)
//            [answer addObjectsFromArray:self->_children];
//        else
//            [answer addObjectsFromArray:[self->_children filteredArrayUsingPredicate:filter]];
//        return answer;
//    }
//    return NULL;
//}

-(void) harvestItemsInBranch:(NSMutableArray*)collector depth:(NSUInteger)depth filter:(NSPredicate*)filter {
    @synchronized(self) {
        NSArray *itemsToAdd;
        if (filter!=nil) {
            itemsToAdd = [self->_children filteredArrayUsingPredicate:filter];
        }
        else {
            itemsToAdd = self->_children;
        }
        [collector addObjectsFromArray:itemsToAdd];
        if (depth > 0) {
            for (TreeItem *item in itemsToAdd) {
                if ([item isFolder]) {
                    [(TreeBranch*)item harvestItemsInBranch: collector depth:depth-1 filter:filter];
                }
            }
        }
    }
}

/* Difference to previous function is that this one doesn't
 filter the branches */

-(void) harvestLeafItemsInBranch:(NSMutableArray*)collector depth:(NSUInteger)depth filter:(NSPredicate*)filter {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isFolder] && depth > 0) {
                [(TreeBranch*)item harvestLeafItemsInBranch: collector depth:depth-1 filter:filter];
            }
            else {
                if (filter!=nil && [filter evaluateWithObject:item]==YES) {
                    [collector addObject:item];
                }
                else {
                    [collector addObject: item];
                }
            }
        }
    }
}

/* In contrary to the previous function, this one ignores LeafBranches */
-(void) harvestLeafsInBranch:(NSMutableArray*)collector depth:(NSUInteger)depth filter:(NSPredicate*)filter {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isFolder]) {
                if (depth > 0) {
                    [(TreeBranch*)item harvestLeafsInBranch: collector depth:depth-1 filter:filter];
                }
            }
            else {
                if (filter!=nil && [filter evaluateWithObject:item]==YES) {
                    [collector addObject:item];
                }
                else {
                    [collector addObject: item];
                }
            }
        }
    }
}

-(void) harvestItemsInBranch:(NSMutableArray*)collector
                       depth:(NSUInteger)depth
                   withBlock:(BOOL(^)(TreeItem* item, NSUInteger level))filter {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isFolder] && depth > 0) {
                [(TreeBranch*)item harvestItemsInBranch: collector
                                                  depth:depth-1
                                              withBlock:filter];
            }
            else {
                BOOL test = filter(item, depth);
                if (test) [collector addObject:item];
            }
        }
    }
}

-(NSMutableArray*) itemsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self harvestItemsInBranch:answer depth:depth  filter:filter];
    return answer;
}

//-(NSMutableArray*) leafsInNode {
//    @synchronized(self) {
//        NSMutableArray *answer = [[NSMutableArray new] init];
//        for (TreeItem *item in self->_children) {
//            if ([item isLeaf]) {
//                [answer addObject:item];
//            }
//        }
//        return answer;
//    }
//    return nil;
//}

//-(NSMutableArray*) leafsInNodeWithPredicate:(NSPredicate *)filter {
//    @synchronized(self) {
//        NSMutableArray *answer = [[NSMutableArray new] init];
//        for (TreeItem *item in self->_children) {
//            if ([item isLeaf] && (filter==nil || [filter evaluateWithObject:item])) {
//                [answer addObject:item];
//            }
//        }
//        return answer;
//    }
//    return nil;
//}

//-(void) _harvestLeafsInBranch:(NSMutableArray*)collector depth:(NSInteger)depth filter:(NSPredicate*)filter {
//    if (depth ==0) return;
//    @synchronized(self) {
//        for (TreeItem *item in self->_children) {
//            if ([item isFolder] && ((TreeBranch*)item)->_children !=nil) {
//                [(TreeBranch*)item _harvestLeafsInBranch: collector depth:depth-1 filter:filter];
//            }
//            else if (filter==nil || [filter evaluateWithObject:item]) {
//                [collector addObject:item];
//            }
//        }
//    }
//}
//-(NSMutableArray*) leafsInBranchTillDepth:(NSInteger)depth {
//    NSMutableArray *answer = [[NSMutableArray new] init];
//    [self _harvestLeafsInBranch: answer depth:depth filter:nil];
//    return answer;
//}

//-(NSMutableArray*) leafsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth {
//    NSMutableArray *answer = [[NSMutableArray new] init];
//    [self _harvestLeafsInBranch: answer depth:depth filter:filter];
//    return answer;
//}

-(NSMutableArray*) branchesInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        for (TreeItem *item in self->_children) {
            if ([item isFolder]) {
                [answer addObject:item];
            }
        }
        return answer;
    }
    return nil;
}

/* 
 * Duplicate Support
 */
/*#pragma mark - Duplicate support

-(BOOL) hasDuplicates {
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                if ([item hasDuplicates])
                    return YES;
            }
        }
    }
    return NO;
}

-(NSInteger) numberOfDuplicatesInNode {
    NSInteger total=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                if ([item hasDuplicates]) {
                    total++;
                }
            }
        }
    }
    return total;
}

-(TreeLeaf*) duplicateAtIndex:(NSUInteger) index {
    NSInteger i=0;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item hasDuplicates]) {
                if (i==index)
                    return (TreeLeaf*)item;
                i++;
            }
        }
    }
    return nil;
}

-(NSInteger) numberOfDuplicatesInBranch {
    NSInteger total=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                if ([item isKindOfClass:[TreeBranch class]])
                    total += [(TreeBranch*)item numberOfDuplicatesInBranch];
                else if ([item hasDuplicates])
                    total++;
            }
        }
    }
    return total;
}*/

/* Computes the total size of all the duplicate files  in all subdirectories */
/*-(long long) duplicateSize {
    long long total=0;
    if (self->_children!=nil) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                if ([item isKindOfClass:[TreeBranch class]])
                    total += [(TreeBranch*)item duplicateSize];
                else if ([item hasDuplicates])
                    total += [[item exactSize] longLongValue];
            }
        }
    }
    return total;
}

-(NSInteger) numberOfBranchesWithDuplicatesInNode {
    NSInteger total=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                if ([item isKindOfClass:[TreeBranch class]])
                    if ([(TreeBranch*)item hasDuplicates])
                    total++;
            }
        }
    }
    return total;
}
-(TreeBranch*) duplicateBranchAtIndex:(NSUInteger) index {
    NSInteger i=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                if ([item isKindOfClass:[TreeBranch class]]) {
                    if ([(TreeBranch*)item numberOfDuplicatesInBranch]>0) {
                        if (i==index)
                            return (TreeBranch*)item;
                        i++;
                    }
                }
            }
        }
    }
    return nil;
}
*/
/*

-(NSMutableArray*) duplicatesInBranchTillDepth:(NSInteger)depth {
    NSMutableArray *answer = [[NSMutableArray new] init];
    NSPredicate *duplicateFilter = [NSPredicate predicateWithFormat:@"hasDuplicates==YES"];
    [self _harvestLeafsInBranch:answer depth:depth filter:duplicateFilter];
    return answer;
}

-(NSMutableArray*) duplicatesInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth {
    NSMutableArray *answer = [[NSMutableArray new] init];
    NSPredicate *duplicateFilter = [NSPredicate predicateWithFormat:@"hasDuplicates==YES"];
    NSCompoundPredicate *composedFilter = [NSCompoundPredicate andPredicateWithSubpredicates:
                                           [NSArray arrayWithObjects:duplicateFilter, filter, nil]];
    [self _harvestLeafsInBranch:answer depth:depth  filter:composedFilter];
    return answer;
}
*/

/*
-(void) prepareForDuplicates {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item respondsToSelector:@selector(resetDuplicates)]) {
                [(TreeLeaf*)item resetDuplicates];
            }
            else if ([item respondsToSelector:@selector(prepareForDuplicates)]) {
                [(TreeBranch*)item prepareForDuplicates];
            }
        }
    }
}
*/

#pragma mark -
#pragma mark Tag Manipulation

/*
 * Tag manipulation
 */
-(void) setTagsInNode:(TreeItemTagEnum)tags {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            [item setTag:tags];
        }
    }
}
-(void) setTagsInBranch:(TreeItemTagEnum)tags {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            [item setTag:tags];
            if ([item isFolder]) {
                [(TreeBranch*)item setTagsInBranch:tags];
            }
        }
    }
}
-(void) resetTagsInNode:(TreeItemTagEnum)tags {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            [item resetTag:tags];
        }
    }
}
-(void) resetTagsInBranch:(TreeItemTagEnum)tags {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            [item resetTag:tags];
            if ([item isFolder]) {
                [(TreeBranch*)item resetTagsInBranch:tags];
            }
        }
    }
}

// trying to invalidate all existing tree and lauching a refresh on the views
-(void) forceRefreshOnBranch {
    if (self->_children!=nil && [self hasTags:tagTreeItemDirty]==NO) { // Useless to propagate to where is already dirty
        [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
        @synchronized(self) {
            [self setTag:tagTreeItemDirty];
            for (TreeItem *item in self->_children) {
                if ([item isFolder] && [item hasTags:tagTreeItemDirty]==NO) { // Useless to propagate to where is already dirty
                    [(TreeBranch*)item forceRefreshOnBranch];
                }
            }
        }
        [self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about change
    }
}


//-(void) performSelector:(SEL)selector inTreeItemsWithTag:(TreeItemTagEnum)tags {
//    @synchronized(self) {
//        for (id item in self->_children) {
//            if ([item hasTags:tags] && [item respondsToSelector:selector]) {
//                [item performSelector:selector];
//            }
//            if ([item isFolder]) {
//                [(TreeBranch*)item performSelector:selector inTreeItemsWithTag:tags];
//            }
//        }
//    }
//}
//-(void) performSelector:(SEL)selector withObject:(id)param inTreeItemsWithTag:(TreeItemTagEnum)tags {
//    @synchronized(self) {
//        for (id item in self->_children) {
//            if ([item hasTags:tags] && [item respondsToSelector:selector]) {
//                [item performSelector:selector withObject:param];
//            }
//            if ([item isFolder]) {
//                [(TreeBranch*)item performSelector:selector withObject:param inTreeItemsWithTag:tags];
//            }
//        }
//    }
//}
//
//-(void) purgeDirtyItems {
//    NSMutableIndexSet *indexesToDelete = [NSMutableIndexSet indexSet];
//    NSUInteger index = 0;
//    @synchronized (self) {
//        for (id item in self->_children) {
//            if ([item hasTags:tagTreeItemDirty]) {
//                [indexesToDelete addIndex:index];
//            }
//            else if ([item isFolder]) {
//                [(TreeBranch*)item purgeDirtyItems];
//            }
//            index++;
//        }
//    }
//    if ([indexesToDelete count]>0) {
//        [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
//        // We synchronize access to the image/imageLoading pair of variables
//        @synchronized (self) {
//            [_children removeObjectsAtIndexes:indexesToDelete];
//        }
//        [self notifyDidChangeTreeBranchPropertyChildren];   // This will inform the observer about change
//    }
//}

//-(FileCollection*) duplicatesInNode {
//    FileCollection *answer = [[FileCollection new] init];
//    for (TreeItem *item in _children) {
//        if ([item isLeaf]) {
//            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
//        }
//    }
//    return answer;
//}
//
//-(FileCollection*) duplicatesInBranch {
//    FileCollection *answer = [[FileCollection new] init];
//    for (TreeItem *item in _children) {
//        if ([item isFolder]) {
//            [answer concatenateFileCollection:[(TreeBranch*)item duplicatesInBranch]];
//        }
//        else if ([item isLeaf]) {
//            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
//        }
//    }
//    return answer;
//}

// Copy and paste support
-(NSDragOperation) supportedPasteOperations:(id<NSDraggingInfo>) info {
    NSDragOperation sourceDragMask = supportedOperations(info);
    sourceDragMask &= (NSDragOperationMove + NSDragOperationCopy + NSDragOperationLink);
    return sourceDragMask;
}

-(NSArray*) acceptDropped:(id<NSDraggingInfo>)info operation:(NSDragOperation)operation sender:(id)fromObject {
    BOOL fireNotfication = NO;
    NSString const *strOperation;
    NSPasteboard *pboard = [info draggingPasteboard];
    NSLog(@"DEBUG TreeBranch.acceptDropped:operation:sender");
    NSLog(@"treeBranch %@, accept drop", self);
    DebugPBoard(pboard);
    NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];
    
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
            if ([[self path] isEqualToString:[folder path]]) // Avoiding NSURL isEqualTo: since it can cause problems with bookmarked URLs
            {
                // If true : abort
                fireNotfication = NO;
                return nil;
            }
        }
    }
    else if (operation == NSDragOperationLink) {
        // TODO:1.4 Operation Link
    }
    else {
        // Invalid case
        fireNotfication = NO;
    }
    

    if (fireNotfication==YES) {
        // The copy and move operations are done in the AppDelegate
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              files, kDFOFilesKey,
                              strOperation, kDFOOperationKey,
                              self, kDFODestinationKey,
                              fromObject, kDFOFromViewKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:fromObject userInfo:info];
    }
    else
        NSLog(@"BrowserController.acceptDrop: - Unsupported Operation %lu", (unsigned long)operation);
    // TODO:1.4 Return Tree Items, and change calling function to add the items into the window
    return files;
}


/*
 * Debug
 */

-(NSString*) debugDescription {
    return [NSString stringWithFormat: @"|%@|(%ld files)", super.debugDescription, [self->_children count]];
}

@end
