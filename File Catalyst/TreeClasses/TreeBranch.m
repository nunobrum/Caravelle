//
//  TreeBranch.m
//  FileCatalyst1
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"
#import "TreeBranch_TreeBranchPrivate.h"
#import "TreeLeaf.h"
#import "MyDirectoryEnumerator.h"

#import "definitions.h"
#include "FileUtils.h"

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

NSMutableArray *folderContentsFromURL(NSURL *url, TreeBranch* parent) {
    NSMutableArray *children = [[NSMutableArray alloc] init];
    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:url WithMode:BViewBrowserMode];

    for (NSURL *theURL in dirEnumerator) {
        TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:parent];
        [children addObject:newObj];
    }
    return children;
}

/* Computes the common path between all paths in the array */
NSString* commonPathFromItems(NSArray* itemArray) {
    NSArray *common_path = nil;
    NSArray *file_path;
    NSInteger ci=0;
    for (TreeItem *item in itemArray) {
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


@implementation TreeBranch

-(ItemType) itemType {
    return ItemTypeBranch;
}


#pragma mark Initializers
-(TreeBranch*) initWithURL:(NSURL*)url parent:(TreeBranch*)parent {
    self = [super initWithURL:url parent:parent];
    self->_children = nil;
    self->allocated_size = -1; // Attribute used to store the value of the computed folder size
    return self;
}

-(TreeBranch*) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent {
    self = [super initWithMDItem:mdItem parent:parent];
    self->_children = nil;
    return self;
}

// TODO:!!!!!!??? Maybe this method is not really needed, since ARC handles this.
// Think this is even causing problems
-(void) releaseChildren {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self ) {
        for (TreeItem *item in _children) {
            // NOTE: isKindOfClass is preferred over itemType.
            if ([item isKindOfClass:[TreeBranch class]]) {
                [(TreeBranch*)item releaseChildren];
            }
        }
        _children=nil;
    }
    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about c
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

-(void) _setChildren:(NSMutableArray*) children {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self) {
        self->_children = children;
    }
    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change

}

-(BOOL) removeChild:(TreeItem*)item {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self) {
        // Leaving this code here as it may come later to clean up the class
        //if ([item itemType] == ItemTypeBranch) {
        //    [item dealloc];
        //}
        [self->_children removeObject:item];
    }
    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
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
    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    return YES;
}

-(BOOL) moveChild:(TreeItem*)item {
    TreeBranch *old_parent = (TreeBranch*)[item parent];
    [self addChild:item];
    if (old_parent) { // Remove from old parent
        [old_parent removeChild:item];
    }
    return YES;
}

// TODO:??? Maybe this method is not really needed, since ARC handles this
-(void) _releaseReleasedChildren {
    //[self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    //@synchronized(self) {
        NSUInteger index = 0;
        while (index < [_children count]) {
            TreeItem *item = [_children objectAtIndex:index];
            if ([item hasTags:tagTreeItemRelease]) {
                // NOTE: isKindOfClass is preferred over itemType.
                if ([item isKindOfClass:[TreeBranch class]]) {
                    [(TreeBranch*)item releaseChildren];
                }
                //NSLog(@"Removing %@", [item path]);
                [_children removeObjectAtIndex:index];
            }
            else
                index++;
        }
    //}
    //[self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about change
}

#pragma mark -
#pragma mark chidren access

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


-(TreeItem*) childWithURL:(NSURL*) aURL {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([[self url] isEqual:aURL]) {
                return item;
            }
        }
    }
    return nil;
}

-(TreeItem*) childContainingURL:(NSURL*) aURL {
    @synchronized(self) {
        if ([self canContainURL:aURL]) {
            for (TreeItem *item in self->_children) {
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
            for (TreeItem *item in self->_children) {
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

-(BOOL) needsRefresh {
    BOOL answer;
    TreeItemTagEnum tag;
    // TODO:? Verify Atomicity and get rid of synchronized clause if OK
    @synchronized(self) {
         tag = [self tag];
    }
    answer = (((tag & tagTreeItemUpdating)==0) &&
             (((tag & tagTreeItemDirty   )!=0) || (tag & tagTreeItemScanned)==0));

    return answer;
}

- (void) refreshContents {
    //NSLog(@"TreeBranch.refreshContentsOnQueue:(%@)", [self path]);
    if ([self needsRefresh]) {
        [self setTag: tagTreeItemUpdating];
        [browserQueue addOperationWithBlock:^(void) {  // CONSIDER:?? Consider using localOperationsQueue as defined above
            // Using a new ChildrenPointer so that the accesses to the _children are minimized

            MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:[self url] WithMode:BViewBrowserMode];

            [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
            @synchronized(self) {
                // Set all items as candidates for release
                for (TreeItem *item in _children) {
                    [item setTag:tagTreeItemRelease];
                }
                self->allocated_size = -1; // Invalidates the previous calculated size

                for (NSURL *theURL in dirEnumerator) {
                    bool found=NO;
                    /* Retrieves existing Element */
                    for (TreeItem *it in self->_children) {
                        if ([[it path] isEqualToString:[theURL path]]) { // Comparing paths as comparing URLs is dangerous
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
                                ((TreeBranch*)item)->allocated_size = -1;
                            }
                            if (self->_children==nil)
                                self->_children = [[NSMutableArray alloc] init];
                            [self->_children addObject:item];
                            [item setParent:self];
                        }
                        else {
                            NSLog(@"Failed to create item for URL %@", theURL);
                        }
                    }
                } // for

                // Now going to release the disappeard items
                [self _releaseReleasedChildren];
                [self resetTag:(tagTreeItemUpdating+tagTreeItemDirty) ]; // Resets updating and dirty
                [self setTag: tagTreeItemScanned];
            } // synchronized
            [self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about change
        }];
    }
}

-(void) _performSelectorInUndeveloppedBranches:(SEL)selector {
    if (self->_children!= nil) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                // NOTE: isKindOfClass is preferred over itemType.
                if ([item isKindOfClass:[TreeBranch class]]) {
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

-(void) _propagateSize {
    BOOL all_sizes_available = YES; // Starts with an invalidated number
    if (self->_children!=nil) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                // NOTE: isKindOfClass is preferred over itemType.
                if ([item isKindOfClass:[TreeBranch class]] &&
                     ((TreeBranch*)item)->allocated_size == -1) {
                    all_sizes_available = NO;
                    break;
                }
            }
        }
    }
    if (all_sizes_available) { // Will update
        [self willChangeValueForKey:kvoTreeBranchPropertySize];
        [self didChangeValueForKey:kvoTreeBranchPropertySize];
        // and propagates to parent
        if (self->_parent)
            [(TreeBranch*)self->_parent _propagateSize];
    }
}

-(void) _computeAllocatedSize {
    NSBlockOperation * op = [NSBlockOperation blockOperationWithBlock:^(void) {

        NSFileManager *localFileManager = [NSFileManager defaultManager];
        NSArray *fieldsToGet = [NSArray arrayWithObjects:NSURLFileSizeKey, NSURLIsRegularFileKey, nil];
        NSDirectoryEnumerator *treeEnum = [localFileManager enumeratorAtURL:self.url
                                                 includingPropertiesForKeys:fieldsToGet
                                                                    options:0
                                                               errorHandler:nil];
        long long total = 0;
        for (NSURL *theURL in treeEnum) {
            NSError *error;
            NSDictionary *fields = [theURL resourceValuesForKeys:fieldsToGet error:&error];
            if ([fields[NSURLIsRegularFileKey] boolValue]) {
                total += [fields[NSURLFileSizeKey] longLongValue];
            }
        }

        [self willChangeValueForKey:kvoTreeBranchPropertySize];
        self->allocated_size = total;
        [self didChangeValueForKey:kvoTreeBranchPropertySize];
        if (self->_parent) {
            [(TreeBranch*)self->_parent _propagateSize];
            // This will trigger a kvoTreeBranchPropertySize from the parent in case of
            // completion of the directory size computation
        }
    }];
    [op setQueuePriority:NSOperationQueuePriorityVeryLow];
    [op setThreadPriority:0.3];
    [lowPriorityQueue addOperation:op];
}

-(void) calculateSize {
    [self _performSelectorInUndeveloppedBranches:@selector(_computeAllocatedSize)];
}

-(void) _growTree {
    NSBlockOperation * op = [NSBlockOperation blockOperationWithBlock:^(void) {
        MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:[self url] WithMode:BViewCatalystMode];

        [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
        @synchronized(self) {
            self->_children = [[NSMutableArray alloc] init];
            TreeBranch *cursor = self;
            NSMutableArray *cursorComponents = [NSMutableArray arrayWithArray:[[self url] pathComponents]];
            unsigned long current_level = [cursorComponents count]-1;


            for (NSURL *theURL in dirEnumerator) {
                NSArray *newURLComponents = [theURL pathComponents];
                unsigned long target_level = [newURLComponents count]-2;
                while (target_level < current_level) { // Needs to go back if the new URL is at a lower branch
                    cursor = (TreeBranch*) cursor->_parent;
                    current_level--;
                }
                while (target_level != current_level &&
                       [cursorComponents[current_level] isEqualToString:newURLComponents[current_level]]) {
                    // Must navigate into the right folder
                    if (target_level <= current_level) { // The equality is considered because it means that the components at this level are different
                        // steps down in the tree
                        cursor = (TreeBranch*) cursor->_parent;
                        current_level--;
                    }
                    else { // Needs to grow the tree
                        current_level++;
                        NSURL *pathURL = [cursor.url URLByAppendingPathComponent:newURLComponents[current_level] isDirectory:YES];
                        cursorComponents[current_level] = newURLComponents[current_level];
                        TreeItem *child = [TreeItem treeItemForURL:pathURL parent:cursor];
                        if (child!=nil) {
                            [cursor->_children addObject:child];
                            if ([child itemType] == ItemTypeBranch)
                            {
                                cursor = (TreeBranch*)child;
                                cursor->_children = [[NSMutableArray alloc] init];
                            }
                            else {
                                // Will ignore this child and just addd the size to the current node
                                // TODO:!! Once the size is again on the class, update the size here
                                NSAssert(NO, @"TreeBranch.growTree: Error:%@ can't be added to %@", theURL, pathURL);
                            }
                        }
                        else {
                            NSAssert(NO, @"TreeBranch.TreeBranch.growTree: Couldn't create path %@ \nwhile creating %@",pathURL, theURL);
                        }
                    }

                }
                TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:cursor];
                if (newObj!=nil) {
                    [cursor->_children addObject:newObj];
                }
                else {
                    NSLog(@"TreeBranch._addURLnoRecurr: - Couldn't create item %@",theURL);
                }
            }
        }
        [self didChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    }];
    [op setQueuePriority:NSOperationQueuePriorityVeryLow];
    [op setThreadPriority:0.3];
    [lowPriorityQueue addOperation:op];
}

-(void) expandAllBranches {
    [self _performSelectorInUndeveloppedBranches:@selector(_growTree)];
}

#pragma mark -
#pragma mark Tree Access
/*
 * All these methods must be changed for recursive in order to support the searchBranches
 */

-(TreeItem*) getNodeWithURL:(NSURL*)url {
    //NSLog(@"TreeBranch.getNodeWithURL:(%@)", url);
    if ([[self url] isEqual:url])
        return self;
    else {
        id child = [self childContainingURL:url];
        if (child!=nil) {
            if ([child itemType] == ItemTypeBranch) {
                return [(TreeBranch*)child getNodeWithURL:url];
            }
        }
        return child;
    }
}

-(TreeItem*) getNodeWithPath:(NSString*)path {
    //NSLog(@"TreeBranch.getNodeWithURL:(%@)", url);
    if ([[self path] isEqualToString:path])
        return self;
    else {
        id child = [self childContainingPath:path];
        if (child!=nil) {
            if ([child itemType] == ItemTypeBranch) {
                return [(TreeBranch*)child getNodeWithPath:path];
            }
        }
        return child;
    }
}


// TODO: !!! Optimize code
//-(TreeItem*) addURL:(NSURL*)theURL withPathComponents:(NSArray*) pcomps inLevel:(NSUInteger) level {
//    id child = [self childContainingURL:theURL];
//    if (child!=nil) {
//        if ([child itemType] == ItemTypeBranch) {
//            return [(TreeBranch*)child addURL:theURL];
//        }
//        else {
//            NSLog(@"Something went wrong");
//        }
//    }
//    @synchronized(self) {
//        if (self->_children == nil)
//            self->_children = [[NSMutableArray alloc] init];
//        [self setTag:tagTreeItemDirty];
//    }
//    unsigned long leaf_level = [pcomps count]-1;
//    if (level < leaf_level) {
//        NSURL *pathURL = [self.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
//        child = [[TreeBranch new] initWithURL:pathURL parent:self];
//        [self addItem:child];
//        return [(TreeBranch*)child addURL:theURL withPathComponents:pcomps inLevel:level+1];
//    }
//    else if (level == leaf_level) {
//        TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:self];
//        [self addItem:newObj];
//        return newObj; /* Stops here Nothing More to Add */
//    }
//    else if ([[self url] isEqualTo:theURL]) {
//        return self; // This condition is equal to level-1==leaf_level
//    }
//    NSLog(@"Ai Caramba! This Item can't contain this URL ");
//    return nil;
//}

-(TreeItem*) addURL:(NSURL*)theURL {
    id child = [self childContainingURL:theURL];
    if (child!=nil) {

        // If it is still a branch
        if ([child itemType] == ItemTypeBranch) {
            return [(TreeBranch*)child addURL:theURL];
        }
        // if it is a Leaf, it should be it. Test to make sure.
        else if ([[child path] isEqualToString:[theURL path]]) { // Avoiding NSURL isEqualTo: since it can cause problems with bookmarked URLs
            return child;
        }
        else {
            NSLog(@"TreeBranch.addURL: Failed to add URL(%@) to %@",theURL, [self url]);
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
        child = [TreeItem treeItemForURL:theURL parent:self];
        [self addChild:child];
        if ([child itemType] == ItemTypeBranch) {
            return [(TreeBranch*)child addURL:pathURL];
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
    NSLog(@"TreeBranch.addURL: URL(%@) is not added to self(%@)", theURL, self->_url);
    return nil;
}


/* Private Method : This is so that we don't have Manual KVO clauses inside. All calling methods should have it */
-(TreeItem*) _addURLnoRecurr:(NSURL*)theURL {
    /* Check first if base path is common */
    //NSRange result;
    if (theURL==nil) {
        NSLog(@"TreeBranch._addURLnoRecurr: - The received URL is null");
        assert(NO);
        return nil;
    }
   
    @synchronized(self) {
        if (self->_children == nil)
            self->_children = [[NSMutableArray alloc] init];
    }
    TreeBranch *cursor = self;
    NSArray *pcomps = [theURL pathComponents];
    unsigned long level = [[_url pathComponents] count];
    unsigned long leaf_level = [pcomps count]-1;
    while (level < leaf_level) {
        NSURL *pathURL = [cursor.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
        TreeItem *child = [cursor childContainingURL:pathURL];
        if (child==nil) {/* Doesnt exist or if existing is not branch*/
            /* This is a new Branch Item that will contain the URL*/
            child = [TreeItem treeItemForURL:pathURL parent:self];
            if (child!=nil) {
                @synchronized(cursor) {
                    [cursor->_children addObject:child];
                }
            }
            else {
                NSLog(@"TreeBranch._addURLnoRecurr: Couldn't create path %@",pathURL);
            }
        }
        if ([child itemType] == ItemTypeBranch)
        {
            cursor = (TreeBranch*)child;
            if (cursor->_children==nil) {
                cursor->_children = [[NSMutableArray alloc] init];
            }
        }
        else {
            // Will ignore this child and just addd the size to the current node
            // TODO:!! Once the size is again on the class, update the size here
            NSLog(@"TreeBranch._addURLnoRecurr: Error:%@ can't be added to %@", theURL, pathURL);
            return nil;
        }
        level++;
    }
    // Checks if it exists ; The base class is provided TreeItem so that it can match anything
    TreeItem *newObj = [cursor childWithName:[pcomps objectAtIndex:level] class:[TreeItem class]];
    if  (newObj==nil) { // It doesn't exist
        newObj = [TreeItem treeItemForURL:theURL parent:cursor];
        if (newObj!=nil) {
            @synchronized(cursor) {
                [cursor->_children addObject:newObj];
            }
        }
        else {
            NSLog(@"TreeBranch._addURLnoRecurr: - Couldn't create item %@",theURL);
        }
    }
    return newObj; /* Stops here Nothing More to Add */
}

-(BOOL) addTreeItem:(TreeItem*)treeItem {
    assert(NO);
    return NO;
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
                    total+=[item filesize];
                }
            }
        }
    }
    return total;
}

/* Computes the total size of all the files contains in all subdirectories */
/* If one directory is not completed, it will return -1 which invalidates the sum */
-(long long) filesize {
    long long total=0;
    long long size;
    if (self->_children!=nil) {
        size = 0;
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                size = [item filesize];
                if (size>=0)
                    total+= size;
                else {
                    size = -1;
                    break;
                }
            }
        }
    }
    else
        size = -1;
    // if the allocated size is calculated and the size not, use the allocated size
    if (size == -1) {
        if (self->allocated_size != -1)
            total = self->allocated_size;
        else
            total = -1; // Invalidates this
    }
    else { // Successfully found the size of the Folder
        self->allocated_size = total;
    }
    return total;
}

/* Computes the total size of all the files contains in all subdirectories */
/* If one directory is not completed, it will return nil which invalidates the sum */
-(NSNumber*) fileSize {
    long long size = [self filesize];
    if (size==-1)
        return nil;
    return [NSNumber numberWithLongLong: size];
}

-(NSInteger) numberOfLeafsInNode {
    NSInteger total=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                if ([item itemType] == ItemTypeLeaf) {
                    total++;
                }
            }
        }
    }
    return total;
}

-(NSInteger) numberOfBranchesInNode {
    NSInteger total=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                if ([item itemType] == ItemTypeBranch) {
                    total++;
                }
            }
        }
    }
    return total;
}

-(NSInteger) numberOfItemsInNode {
    @synchronized(self) {
        if (self->_children!=nil) {
            return [self->_children count]; /* This is needed to invalidate and re-scan the node */
        }
    }
    return 0;
}

// This returns the number of leafs in a branch
// this function is recursive to all sub branches
-(NSInteger) numberOfLeafsInBranch {
    NSInteger total=0;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item itemType] == ItemTypeBranch) {
                total += [(TreeBranch*)item numberOfLeafsInBranch];
            }
            else
                total++;
        }
    }
    return total;
}

/* Returns if the node is expandable
 Note that if the _children is not populated it is assumed that the
 node is expandable. It is preferable to assume as yes and later correct. */
-(BOOL) isExpandable {
    @synchronized(self) {
        if ((self->_children!=nil) && ([self numberOfBranchesInNode]!=0))
            return YES;
    }
    return NO;
}


//-(NSInteger) numberOfFileDuplicatesInBranch {
//    NSInteger total = 0;
//    for (TreeItem *item in _children) {
//        if ([item itemType] == ItemTypeBranch) {
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
            if ([item itemType] == ItemTypeBranch) {
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
            if ([item itemType] == ItemTypeBranch) {
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
            if ([item itemType] == ItemTypeLeaf) {
                if (i==index)
                    return (TreeLeaf*)item;
                i++;
            }
        }
    }
    return nil;
}

-(NSInteger) indexOfChild:(TreeItem*)item {
    return [_children indexOfObject:item];
}
#pragma mark -
#pragma mark collector methods

-(FileCollection*) filesInNode {
    @synchronized(self) {
        FileCollection *answer = [[FileCollection new] init];
        for (TreeItem *item in self->_children) {
            if ([item itemType] == ItemTypeLeaf) {
                FileInformation *finfo;
                finfo = [FileInformation createWithURL:[(TreeLeaf*)item url]];
                [answer AddFileInformation:finfo];
            }
        }
        return answer;
    }
    return NULL;
}
-(FileCollection*) filesInBranch {
    return nil; // TODO:!! Pending Implementation
}
-(NSMutableArray*) itemsInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        [answer addObjectsFromArray:self->_children];
        return answer;
    }
    return NULL;
}

-(NSMutableArray*) itemsInNodeWithPredicate:(NSPredicate *)filter {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        if (filter==nil)
            [answer addObjectsFromArray:self->_children];
        else
            [answer addObjectsFromArray:[self->_children filteredArrayUsingPredicate:filter]];
        return answer;
    }
    return NULL;
}

-(void) _harvestItemsInBranch:(NSMutableArray*)collector depth:(NSInteger)depth filter:(NSPredicate*)filter {
    @synchronized(self) {
        if (filter!=nil) {
            [collector addObjectsFromArray:[self->_children filteredArrayUsingPredicate:filter]];
        }
        else {
            [collector addObjectsFromArray: self->_children];
        }
        if (depth > 1) {
            for (TreeItem *item in self->_children) {
                if ([item itemType] == ItemTypeBranch) {
                    [(TreeBranch*)item _harvestItemsInBranch: collector depth:depth-1 filter:filter];
                }
            }
        }
    }
}
-(NSMutableArray*) itemsInBranchTillDepth:(NSInteger)depth {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        [self _harvestItemsInBranch:answer depth:depth filter:nil];
        return answer; // Pending Implementation
    }
    return nil;
}

-(NSMutableArray*) itemsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        [self _harvestItemsInBranch:answer depth:depth  filter:filter];
        return answer; // Pending Implementation
    }
    return nil;
}

-(NSMutableArray*) leafsInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        for (TreeItem *item in self->_children) {
            if ([item itemType] == ItemTypeLeaf) {
                [answer addObject:item];
            }
        }
        return answer;
    }
    return nil;
}

-(NSMutableArray*) leafsInNodeWithPredicate:(NSPredicate *)filter {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        for (TreeItem *item in self->_children) {
            if ([item itemType] == ItemTypeLeaf && (filter==nil || [filter evaluateWithObject:item])) {
                [answer addObject:item];
            }
        }
        return answer;
    }
    return nil;
}

-(void) _harvestLeafsInBranch:(NSMutableArray*)collector depth:(NSInteger)depth filter:(NSPredicate*)filter {
    if (depth ==0) return;
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item itemType] == ItemTypeBranch) {
                [(TreeBranch*)item _harvestLeafsInBranch: collector depth:depth-1 filter:filter];
            }
            else if ([item itemType] == ItemTypeLeaf && (filter==nil || [filter evaluateWithObject:item])) {
                [collector addObject:item];
            }
        }
    }
}
-(NSMutableArray*) leafsInBranchTillDepth:(NSInteger)depth {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        [self _harvestLeafsInBranch: answer depth:depth filter:nil];
        return answer; // Pending Implementation
    }
    return nil;
}

-(NSMutableArray*) leafsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        [self _harvestLeafsInBranch: answer depth:depth filter:filter];
        return answer; // Pending Implementation
    }
    return nil;
}

-(NSMutableArray*) branchesInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        for (TreeItem *item in self->_children) {
            if ([item itemType]==ItemTypeBranch) {
                [answer addObject:item];
            }
        }
        return answer;
    }
    return nil;
}

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
            if ([item itemType] == ItemTypeBranch) {
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
            [item setTag:tags];
            if ([item itemType] == ItemTypeBranch) {
                [(TreeBranch*)item resetTagsInBranch:tags];
            }
        }
    }
}

// trying to invalidate all existing tree and lauching a refresh on the views
// TODO:!! Come up with a better way to do this
-(void) forceRefreshOnBranch {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self) {
        [self setTag:tagTreeItemDirty];
        for (TreeItem *item in self->_children) {
            if ([item itemType] == ItemTypeBranch) {
                [(TreeBranch*)item forceRefreshOnBranch];
            }
        }
    }
    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about change
}


//-(void) performSelector:(SEL)selector inTreeItemsWithTag:(TreeItemTagEnum)tags {
//    @synchronized(self) {
//        for (id item in self->_children) {
//            if ([item hasTags:tags] && [item respondsToSelector:selector]) {
//                [item performSelector:selector];
//            }
//            if ([item itemType] == ItemTypeBranch) {
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
//            if ([item itemType] == ItemTypeBranch) {
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
//            else if ([item itemType] == ItemTypeBranch) {
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
//        [self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about change
//    }
//}

//-(FileCollection*) duplicatesInNode {
//    FileCollection *answer = [[FileCollection new] init];
//    for (TreeItem *item in _children) {
//        if ([item itemType] == ItemTypeLeaf) {
//            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
//        }
//    }
//    return answer;
//}
//
//-(FileCollection*) duplicatesInBranch {
//    FileCollection *answer = [[FileCollection new] init];
//    for (TreeItem *item in _children) {
//        if ([item itemType] == ItemTypeBranch) {
//            [answer concatenateFileCollection:[(TreeBranch*)item duplicatesInBranch]];
//        }
//        else if ([item itemType] == ItemTypeLeaf) {
//            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
//        }
//    }
//    return answer;
//}


@end
