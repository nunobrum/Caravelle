//
//  TreeBranch.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"
#import "TreeBranch_TreeBranchPrivate.h"
#import "TreeLeaf.h"
#import "MyDirectoryEnumerator.h"

#import "definitions.h"
#include "FileUtils.h"

NSString *const kvoTreeBranchPropertyChildren = @"childrenArray";
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


#pragma mark Initializers
-(TreeBranch*) initWithURL:(NSURL*)url parent:(TreeBranch*)parent {
    self = [super initWithURL:url parent:parent];
    self->_children = nil;
    return self;
}

-(TreeBranch*) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent {
    self = [super initWithMDItem:mdItem parent:parent];
    self->_children = nil;
    return self;
}

// TODO:??? Maybe this method is not really needed, since ARC handles this
-(void) releaseChildren {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self ) {
        for (TreeItem *item in _children) {
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



-(BOOL) isBranch {
    return YES;
}

#pragma mark KVO methods

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {

    BOOL automatic = NO;
    if ([theKey isEqualToString:kvoTreeBranchPropertyChildren]) {
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
        //if ([item isKindOfClass:[TreeBranch class]]) {
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
                if ([item isKindOfClass:[TreeBranch class]]) {
                    [(TreeBranch*)item releaseChildren];
                }
                NSLog(@"Removing %@", [item path]);
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

- (void)refreshContentsOnQueue: (NSOperationQueue *) queue {
    //NSLog(@"Refreshing %@", [self path]);
    if ([self needsRefresh]) {
        [self setTag: tagTreeItemUpdating];
        [queue addOperationWithBlock:^(void) {  // !!! Consider using localOperationsQueue as defined above
            // Using a new ChildrenPointer so that the accesses to the _children are minimized

            MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:[self url] WithMode:BViewBrowserMode];

            [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
            @synchronized(self) {
                // Set all items as candidates for release
                for (TreeItem *item in _children) {
                    [item setTag:tagTreeItemRelease];
                }

                for (NSURL *theURL in dirEnumerator) {
                    bool found=NO;
                    /* Retrieves existing Element */
                    for (TreeItem *it in self->_children) {
                        if ([[it url] isEqual:theURL]) {
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
                        if ([item isKindOfClass:[TreeBranch class]]) {
                            [self setTag: tagTreeItemDirty]; // When it is created it invalidates it
                        }
                        if (self->_children==nil)
                            self->_children = [[NSMutableArray alloc] init];
                        [self->_children addObject:item];
                        [item setParent:self];
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

#pragma mark -
#pragma mark Tree Access
/*
 * All these methods must be changed for recursive in order to support the searchBranches
 */

-(TreeItem*) getNodeWithURL:(NSURL*)url {
    if ([[self url] isEqual:url])
        return self;
    else {
        id child = [self childContainingURL:url];
        if (child!=nil) {
            if ([child isKindOfClass:[TreeBranch class]]) {
                return [(TreeBranch*)child getNodeWithURL:url];
            }
        }
        return child;
    }
}

// TODO: !!! Optimize code
//-(TreeItem*) addURL:(NSURL*)theURL withPathComponents:(NSArray*) pcomps inLevel:(NSUInteger) level {
//    id child = [self childContainingURL:theURL];
//    if (child!=nil) {
//        if ([child isKindOfClass:[TreeBranch class]]) {
//            return [(TreeBranch*)child addURL:theURL];
//        }
//        else {
//            NSLog(@"Agony!!! Something went wrong");
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
//    NSLog(@"Ai Caramba!!! This Item can't contain this URL !!! ");
//    return nil; // Ai Caramba !!!
//}

-(TreeItem*) addURL:(NSURL*)theURL {
    id child = [self childContainingURL:theURL];
    if (child!=nil) {
        if ([child isKindOfClass:[TreeBranch class]]) {
            return [(TreeBranch*)child addURL:theURL];
        }
        else {
            NSLog(@"Agony!!! Something went wrong");
            assert(NO);
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
        if ([child isKindOfClass:[TreeBranch class]]) {
            return [(TreeBranch*)child addURL:pathURL];
        }
    }
    else if (level == leaf_level) {
        TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:self];
        [self addChild:newObj];
        return newObj; /* Stops here Nothing More to Add */
    }
    else if ([[self url] isEqualTo:theURL]) {
        return self; // This condition is equal to level-1==leaf_level
    }
    NSLog(@"%@ is not added to %@", theURL, self->_url);
    return nil; // Ai Caramba !!!
}


/* Private Method : This is so that we don't have Manual KVO clauses inside. All calling methods should have it */
-(TreeItem*) _addURLnoRecurr:(NSURL*)theURL {
    /* Check first if base path is common */
    //NSRange result;
    if (theURL==nil) {
        NSLog(@"OOOOPSS! Something went deadly wrong here.\nThe URL is null");
        assert(NO);
        return nil;
    }
    //    result = [[theURL path] rangeOfString:[self path]];
    //    if (NSNotFound==result.location) {
    //        // The new root is already contained in the existing trees
    //        return nil;
    //    }

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
                NSLog(@"Couldn't create path %@",pathURL);
            }
        }
        if ([child isKindOfClass:[TreeBranch class]])
        {
            cursor = (TreeBranch*)child;
            if (cursor->_children==nil) {
                cursor->_children = [[NSMutableArray alloc] init];
            }
        }
        else {
            // Will ignore this child and just addd the size to the current node
            // !!! TODO: Once the size is again on the class, update the size here
            NSLog(@"%@ is not added to %@", theURL, pathURL);
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
            NSLog(@"Couldn't create item %@",theURL);
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
                if ([item isKindOfClass:[TreeLeaf class]]==YES) {
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
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                long long size = [item filesize];
                if (size>=0)
                    total+= size;
                else {
                    size = -1;
                    break;
                }
            }
        }
    }
    return total;
}

/* Computes the total size of all the files contains in all subdirectories */
/* If one directory is not completed, it will return nil which invalidates the sum */
-(NSNumber*) fileSize {
    long long total=0;
    BOOL invalid = false;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                NSNumber *size = [item fileSize];
                if (size) {
                    total += [size longLongValue];
                }
                else {
                    invalid = true;
                    break;
                }
            }
            //total = [self->_children valueForKeyPath:@"@sum.filesize"];
        }
        else
            invalid = true;
    }
    if (invalid)
        return nil;
    else
        return [NSNumber numberWithLongLong: total];
}

-(NSInteger) numberOfLeafsInNode {
    NSInteger total=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                if ([item isKindOfClass:[TreeLeaf class]]==YES) {
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
                if ([item isKindOfClass:[TreeBranch class]]==YES) {
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
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
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
//        if ([item isKindOfClass:[TreeBranch class]]==YES) {
//            total += [(TreeBranch*)item numberOfFileDuplicatesInBranch];
//        }
//        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
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
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
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
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
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
            if ([item isKindOfClass:[TreeLeaf class]]==YES) {
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
            if ([item isKindOfClass:[TreeLeaf class]]==YES) {
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
    return nil; // Pending Implementation
}
-(NSMutableArray*) itemsInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        [answer addObjectsFromArray:self->_children];
        return answer;
    }
    return NULL;
}

-(void) _harvestItemsInBranch:(NSMutableArray*)collector {
    @synchronized(self) {
        [collector addObjectsFromArray: self->_children];
        for (TreeItem *item in self->_children) {
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
                [(TreeBranch*)item _harvestItemsInBranch: collector];
            }
        }
    }
}
-(NSMutableArray*) itemsInBranch {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        [self _harvestItemsInBranch:answer];
        return answer; // Pending Implementation
    }
    return nil;
}

-(NSMutableArray*) leafsInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        for (TreeItem *item in self->_children) {
            if ([item isKindOfClass:[TreeLeaf class]]==YES) {
                [answer addObject:item];
            }
        }
        return answer;
    }
    return nil;
}

-(void) _harvestLeafsInBranch:(NSMutableArray*)collector {
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
                [(TreeBranch*)item _harvestLeafsInBranch: collector];
            }
            else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
                [collector addObject:item];
            }
        }
    }
}
-(NSMutableArray*) leafsInBranch {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        [self _harvestLeafsInBranch: answer];
        return answer; // Pending Implementation
    }
    return nil;
}

-(NSMutableArray*) branchesInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        for (TreeItem *item in self->_children) {
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
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
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
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
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
                [(TreeBranch*)item resetTagsInBranch:tags];
            }
        }
    }
}

//-(void) performSelector:(SEL)selector inTreeItemsWithTag:(TreeItemTagEnum)tags {
//    @synchronized(self) {
//        for (id item in self->_children) {
//            if ([item hasTags:tags] && [item respondsToSelector:selector]) {
//                [item performSelector:selector];
//            }
//            if ([item isKindOfClass:[TreeBranch class]]==YES) {
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
//            if ([item isKindOfClass:[TreeBranch class]]==YES) {
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
//            else if ([item isKindOfClass:[TreeBranch class]]==YES) {
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
//        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
//            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
//        }
//    }
//    return answer;
//}
//
//-(FileCollection*) duplicatesInBranch {
//    FileCollection *answer = [[FileCollection new] init];
//    for (TreeItem *item in _children) {
//        if ([item isKindOfClass:[TreeBranch class]]==YES) {
//            [answer concatenateFileCollection:[(TreeBranch*)item duplicatesInBranch]];
//        }
//        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
//            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
//        }
//    }
//    return answer;
//}

/*
 * File Manipulation methods
 */
//-(BOOL) sendToRecycleBinItem:(TreeItem*) item {
//    BOOL ok = [appFileManager removeItemAtPath:[self path] error:nil];
//    if (ok) {
//        [self removeItem:item];
//    }
//    return ok;
//}
//
//-(BOOL) eraseItem:(TreeItem*) item {
//    return NO; // !!! TODO
//}
//
//-(BOOL) copyItem:(TreeItem*)item To:(NSString*)path {
//    BOOL ok = [appFileManager copyItemAtPath:[item path] toPath:path error:nil];
//    return ok;
//}
//
//-(BOOL) MoveItem:(TreeItem*)item To:(NSString*)path {
//    BOOL ok = [appFileManager moveItemAtPath:[item path] toPath:path error:nil];
//    if (ok) {
//        [self removeItem:item];
//    }
//    return ok;
//}

@end
