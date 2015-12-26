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

#import "TreeBranchURL.h"
#import "TreeBranch_TreeBranchPrivate.h"
#import "TreeURL.h"
#import "MyDirectoryEnumerator.h"
#import "TreeManager.h"
#import "CalcFolderSizes.h"



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
    for (TreeURL *item in itemArray) {
        if (common_path==nil)
        {
            common_path = [[item url] pathComponents];
            ci = [common_path count]-1; /* This will exclude the file name */
        }
        else
        {
            NSInteger i;
            file_path = [[item url] pathComponents];
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
//    //TODO:Optimization Create a Class to manage arrays of Branches. This is useful for the Browser Controller
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


@implementation TreeBranchURL

-(ItemType) itemType {
    return ItemTypeBranch;
}


#pragma mark Initializers
-(instancetype) initWithURL:(NSURL*)url parent:(TreeBranch*)parent {
    self = [super initWithParent:parent];
    [self _invalidateSizes]; // Attribute used to store the value of the computed folder size
    return self;
}

-(instancetype) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent {
    self = [super initWithParent:parent];
    self->_children = nil;
    [self _invalidateSizes]; // Attribute used to store the value of the computed folder size
    return self;
}




+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
    TreeBranchURL *tree = [TreeBranchURL alloc];
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



#pragma mark -
#pragma mark Children Manipulation



-(NSInteger) _releaseReleasedChildren {
    NSInteger released = 0;
    NSUInteger index = 0;

    while (index < [_children count]) {
        TreeItem *item = [_children objectAtIndex:index];
        if ([item hasTags:tagTreeItemRelease]) {
            // NOTE: isKindOfClass is preferred over itemType.
            if ([item isKindOfClass:[TreeBranch class]]) {
                [(TreeBranch*)item _releaseChildren]; // This branch will be completely deleted
            }
            else if ([item isKindOfClass:[TreeURL class]]) {
                [(TreeURL*)item removeFromDuplicateRing]; // Removing itself from the duplicate lists
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



#pragma mark -
#pragma mark chidren access





-(TreeItem*) childContainingURL:(NSURL*) aURL {
    @synchronized(self) {
        if ([self canContainURL:aURL]) {
            for (TreeURL *item in self->_children) {
                if ([item canContainURL:aURL]) {
                    return item;
                }
            }
        }
    }
    return nil;
}

-(TreeItem*) childContainingPath:(NSString*) aPath {
    @synchronized(self) {
        if ([self canContainPath:aPath]) {
            for (TreeURL *item in self->_children) {
                if ([item canContainPath:aPath]) {
                    return item;
                }
            }
        }
    }
    return nil;
}

#pragma mark -
#pragma mark Refreshing contents



- (void) refresh {
    if ([self needsRefresh]) {
        [self tagRefreshStart];
        NSLog(@"TreeBranch.refreshContents:(%@)", [self path]); //, [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_SEE_HIDDEN_FILES]);
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
                    for (TreeURL *it in self->_children) {
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
                        TreeItem *item = [TreeURL treeItemForURL:theURL parent:self];
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
                            NSLog(@"TreeBranch.refreshContents: Failed to create item for URL %@", theURL);
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
                if ([item isKindOfClass:[TreeBranchURL class]] &&
                     ((TreeBranchURL*)item)->size_files == -1) { // Only one of the sizes is tested. It's OK
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
            [(TreeBranchURL*)self->_parent _propagateSize];
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
        [(TreeBranchURL*)self->_parent _propagateSize];
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
            [(TreeBranchURL*)self->_parent sizeCalculationCancelled];
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
                if ([item isKindOfClass:[TreeBranchURL class]]) {
                    [(TreeBranchURL*)item calculateSize];
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
//        TreeBranchURL *cursor = self;
//        NSMutableArray *cursorComponents = [NSMutableArray arrayWithArray:[[self url] pathComponents]];
//        unsigned long current_level = [cursorComponents count]-1;
//
//
//        for (NSURL *theURL in dirEnumerator) {
//            BOOL ignoreURL = NO;
//            NSArray *newURLComponents = [theURL pathComponents];
//            unsigned long target_level = [newURLComponents count]-2;
//            while (target_level < current_level) { // Needs to go back if the new URL is at a lower branch
//                cursor = (TreeBranchURL*) cursor->_parent;
//                current_level--;
//            }
//            while (target_level != current_level &&
//                   [cursorComponents[current_level] isEqualToString:newURLComponents[current_level]]) {
//                // Must navigate into the right folder
//                if (target_level <= current_level) { // The equality is considered because it means that the components at this level are different
//                    // steps down in the tree
//                    cursor = (TreeBranchURL*) cursor->_parent;
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
//                            cursor = (TreeBranchURL*)child;
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
//                        NSAssert(NO, @"TreeBranchURL.TreeBranchURL._expandTree: Couldn't create path %@ \nwhile creating %@",pathURL, theURL);
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
//                    if ([newObj isKindOfClass:[TreeBranchURL class]]) {
//                        cursor = (TreeBranchURL*)newObj;
//                        cursor->_children = [[NSMutableArray alloc] init];
//                        current_level++;
//                        cursorComponents[current_level] = newURLComponents[current_level];
//
//                    }
//                }
//                else {
//                    NSLog(@"TreeBranchURL._addURLnoRecurr: - Couldn't create item %@",theURL);
//                }
//            }
//        }
//    }
//    [self notifyDidChangeTreeBranchPropertyChildren];  // This will inform the observer about change
//}

-(void) harverstUndeveloppedFolders:(NSMutableArray*)collector {
    
    if (self->_children!= nil) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                if ([item isFolder]) {
                    [(TreeBranchURL*)item harverstUndeveloppedFolders:collector];
                }
            }
        }
    }
    else {
        [collector addObject:self];
    }
}


#pragma mark -
#pragma mark Tree Access
/*
 * All these methods must be changed for recursive in order to support the searchBranches
 */

-(TreeURL*) getNodeWithURL:(NSURL*)url {
    //NSLog(@"TreeBranchURL.getNodeWithURL:(%@)", url);
    if ([[self url] isEqual:url])
        return self;
    else {
        id child = [self childContainingURL:url];
        if (child!=nil) {
            if ([child isFolder]) {
                return [(TreeBranchURL*)child getNodeWithURL:url];
            }
        }
        return child;
    }
}

-(TreeURL*) getNodeWithPath:(NSString*)path {
    //NSLog(@"TreeBranchURL.getNodeWithURL:(%@)", url);
    if ([[self path] isEqualToString:path])
        return self;
    else {
        id child = [self childContainingPath:path];
        if (child!=nil) {
            if ([child isFolder]) {
                return [(TreeBranchURL*)child getNodeWithPath:path];
            }
        }
        return child;
    }
}


-(TreeURL*) addURL:(NSURL*)theURL {
    id child = [self childContainingURL:theURL];
    if (child!=nil) {

        // If it is still a branch
        if ([child isFolder]) {
            return [(TreeBranchURL*)child addURL:theURL];
        }
        // if it is a Leaf, it should be it. Test to make sure.
        else if ([[child path] isEqualToString:[theURL path]]) { // Avoiding NSURL isEqualTo: since it can cause problems with bookmarked URLs
            return child;
        }
        else {
            NSLog(@"TreeBranchURL.addURL: Failed to add URL(%@) to %@",theURL, [self url]);
            assert(NO);
            return nil;
        }
    }
    @synchronized(self) {
        if (self->_children == nil)
            self->_children = [[NSMutableArray alloc] init];
    }
    NSArray *pcomps = [theURL pathComponents];
    unsigned long level = [[_url pathComponents] count];
    unsigned long leaf_level = [pcomps count]-1;
    if (level < leaf_level) {
        NSURL *pathURL = [self.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
        child = [TreeURL treeItemForURL:pathURL parent:self];
        [self addChild:child];
        if ([child isFolder]) {
            return [(TreeBranchURL*)child addURL:theURL];
        }
    }
    else if (level == leaf_level) {
        TreeURL *newObj = [TreeURL treeItemForURL:theURL parent:self];
        [self addChild:newObj];
        return newObj; /* Stops here Nothing More to Add */
    }
    else if ([[self path] isEqualToString:[theURL path]]) { // Avoiding NSURL isEqualTo: since it can cause problems with bookmarked URLs
        return self; // This condition is equal to level-1==leaf_level
    }
    NSLog(@"TreeBranchURL.addURL: URL(%@) is not added to self(%@)", theURL, self->_url);
    return nil;
}


/* Private Method : This is so that we don't have Manual KVO clauses inside. All calling methods should have it */
//-(TreeItem*) _addURLnoRecurr:(NSURL*)theURL {
//    /* Check first if base path is common */
//    //NSRange result;
//    if (theURL==nil) {
//        NSLog(@"TreeBranchURL._addURLnoRecurr: - The received URL is null");
//        assert(NO);
//        return nil;
//    }
//   
//    @synchronized(self) {
//        if (self->_children == nil)
//            self->_children = [[NSMutableArray alloc] init];
//    }
//    TreeBranchURL *cursor = self;
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
//                NSLog(@"TreeBranchURL._addURLnoRecurr: Couldn't create path %@",pathURL);
//            }
//        }
//        if ([child isFolder])
//        {
//            cursor = (TreeBranchURL*)child;
//            if (cursor->_children==nil) {
//                cursor->_children = [[NSMutableArray alloc] init];
//            }
//        }
//        else {
//            // Will ignore this child
//            NSLog(@"TreeBranchURL._addURLnoRecurr: Error:%@ can't be added to %@", theURL, pathURL);
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
//            NSLog(@"TreeBranchURL._addURLnoRecurr: - Couldn't create item %@",theURL);
//        }
//    }
//    return newObj; /* Stops here Nothing More to Add */
//}

-(BOOL) addTreeItem:(TreeURL*) newItem {
    @synchronized(self) {
        if (self->_children == nil)
            self->_children = [[NSMutableArray alloc] init];
    }
    TreeBranchURL *cursor = self;
    NSArray *pcomps = [newItem.url pathComponents];
    unsigned long level = [[_url pathComponents] count];
    unsigned long leaf_level = [pcomps count]-1;
    while (level < leaf_level) {
        NSURL *pathURL = [cursor.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
        TreeItem *child = [cursor childContainingURL:pathURL];
        if (child==nil) {/* Doesnt exist or if existing is not branch*/
            /* This is a new Branch Item that will contain the URL*/
            child = [TreeItem treeItemForURL:pathURL parent:cursor];
            if (child!=nil) {
                @synchronized(cursor) {
                    [cursor->_children addObject:child];
                }
            }
            else {
                NSLog(@"TreeBranchURL._addURLnoRecurr: Couldn't create path %@",pathURL);
            }
        }
        if ([child isFolder])
        {
            cursor = (TreeBranchURL*)child;
            if (cursor->_children==nil) {
                cursor->_children = [[NSMutableArray alloc] init];
            }
        }
        else {
            // Will ignore this child
            NSLog(@"TreeBranchURL._addURLnoRecurr: Error:%@ can't be added to %@", newItem.url, pathURL);
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
                if ([item isKindOfClass:[TreeBranchURL class]]) {
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



#pragma mark -
#pragma mark Branch access


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
                if ([item isKindOfClass:[TreeBranchURL class]])
                    total += [(TreeBranchURL*)item numberOfDuplicatesInBranch];
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
                if ([item isKindOfClass:[TreeBranchURL class]])
                    total += [(TreeBranchURL*)item duplicateSize];
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
                if ([item isKindOfClass:[TreeBranchURL class]])
                    if ([(TreeBranchURL*)item hasDuplicates])
                    total++;
            }
        }
    }
    return total;
}
-(TreeBranchURL*) duplicateBranchAtIndex:(NSUInteger) index {
    NSInteger i=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                if ([item isKindOfClass:[TreeBranchURL class]]) {
                    if ([(TreeBranchURL*)item numberOfDuplicatesInBranch]>0) {
                        if (i==index)
                            return (TreeBranchURL*)item;
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

// TODO:????? Is this still being used ?
-(void) prepareForDuplicates {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item respondsToSelector:@selector(resetDuplicates)]) {
                [(TreeURL*)item resetDuplicates];
            }
            else if ([item respondsToSelector:@selector(prepareForDuplicates)]) {
                [(TreeBranchURL*)item prepareForDuplicates];
            }
        }
    }
}

#pragma mark -
#pragma mark Tag Manipulation


// trying to invalidate all existing tree and lauching a refresh on the views
-(void) forceRefreshOnBranch {
    if (self->_children!=nil) {
        [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
        @synchronized(self) {
            [self setTag:tagTreeItemDirty];
            for (TreeItem *item in self->_children) {
                if ([item isFolder]) {
                    [(TreeBranch*)item forceRefreshOnBranch];
                }
            }
        }
        [self notifyDidChangeTreeBranchPropertyChildren];   // This will inform the observer about change
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
        // TODO: !!! Operation Link
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
                              //fromObject, kFromObjectKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:fromObject userInfo:info];
    }
    else
        NSLog(@"BrowserController.acceptDrop: - Unsupported Operation %lu", (unsigned long)operation);
    
    return files;
}


/*
 * Debug
 */

-(NSString*) debugDescription {
    return [NSString stringWithFormat: @"|%@|(%ld files)", super.debugDescription, [self->_children count]];
}

@end


