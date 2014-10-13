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

+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
    TreeBranch *tree = [TreeBranch alloc];
    return [tree initFromEnumerator:dirEnum URL:rootURL parent:parent cancelBlock:cancelBlock];
}

-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
    self = [self initWithURL:rootURL parent:parent];
    /* Since the instance is created now, there is no problem with thread synchronization */
    for (NSURL *theURL in dirEnum) {
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

-(BOOL) removeItem:(TreeItem*)item {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self) {
        [self->_children removeObject:item];
    }
    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    return YES;
}

-(BOOL) addItem:(TreeItem*)item {
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

-(BOOL) moveItem:(TreeItem*)item {
    TreeBranch *old_parent = (TreeBranch*)[item parent];
    [self addItem:item];
    if (old_parent) { // Remove from old parent
        [old_parent removeItem:item];
    }
    return YES;
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
            if ([self isEqual:aURL]) {
                return item;
            }
        }
    }
    return nil;
}

-(TreeItem*) childContainingURL:(NSURL*) aURL {
    NSRange result;
    NSString *path = [aURL path];
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            NSString *ipath = [item path];
            result = [path rangeOfString:ipath];
            // The URL must contain the total length of 
            if (0==result.location && result.length == [ipath length]) {
                if ([item isBranch] || [aURL isEqual:[item url]]) {
                    return item;
                }
            }
        }
    }
    return nil;
}


/*
 * Deprecated Method 
 */
//
///* This is not to be used with Catalyst Mode */
//-(NSMutableArray*) childrenRefreshed {
//    NSMutableArray *newChildren = [[NSMutableArray new] init];
//
//    //NSLog(@"Scanning directory %@", self.path);
//    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:self->_url WithMode:BViewBrowserMode];
//
//    for (NSURL *theURL in dirEnumerator) {
//        TreeItem *item = [self childWithURL:theURL]; /* Retrieves existing Element */
//        if (item==nil) { /* If not found creates a new one */
//            item = [TreeItem treeItemForURL:theURL parent:self];
//        }
//        else {
//            [item resetTag:tagTreeItemAll];
//        }
//        [newChildren addObject:item];
//
//    } // for
//    return newChildren;
//}
//
#pragma mark -
#pragma mark Refreshing contents
- (void)refreshContentsOnQueue: (NSOperationQueue *) queue {
    @synchronized (self) {
        if (_tag & tagTreeItemUpdating) {
            // If its already updating.... do nothing exit here.
        }
        else { // else make the update
        _tag |= tagTreeItemUpdating;
        [queue addOperationWithBlock:^(void) {  // !!! Consider using localOperationsQueue as defined above
            NSMutableArray *newChildren = [[NSMutableArray new] init];
            BOOL new_files=NO;

            NSLog(@"Scanning directory %@", self.path);
            MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:self->_url WithMode:BViewBrowserMode];

            for (NSURL *theURL in dirEnumerator) {
                TreeItem *item = [self childContainingURL:theURL]; /* Retrieves existing Element */
                if (item==nil) { /* If not found creates a new one */
                    item = [TreeItem treeItemForURL:theURL parent:self];
                    new_files = YES;
                }
                else {
                    [item resetTag:tagTreeItemAll];
                }
                [newChildren addObject:item];

            } // for
            if (new_files==YES || // There are new Files OR
                [newChildren count] < [self->_children count]) { // There are deletions
                [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
                // We synchronize access to the image/imageLoading pair of variables
                @synchronized (self) {
                    self->_children = newChildren;
                    _tag &= ~(tagTreeItemUpdating+tagTreeItemDirty); // Resets updating and dirty
                }
                [self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about change
            }
            
        }];
    }
    }
}

#pragma mark -
#pragma mark Tree Access
/*
 * All these methods must be changed for recursive in order to support the searchBranches
 */

-(TreeItem*) treeItemWithURL:(NSURL*)url {
    id child = [self childContainingURL:url];
    if (child!=nil) {
        if ([child isKindOfClass:[TreeBranch class]]) {
            return [(TreeBranch*)child treeItemWithURL:url];
        }
    }
    return child;
}

-(TreeItem*) addURL:(NSURL*)theURL {
    id child = [self childContainingURL:theURL];
    if (child!=nil) {
        if ([child isKindOfClass:[TreeBranch class]]) {
            return [(TreeBranch*)child addURL:theURL];
        }
        else {
            if ([theURL isEqual:[self url]]) {
                return self; // The URL already exists
            }
            NSLog(@"Agony!!! Something went wrong");
        }
    }
    @synchronized(self) {
        if (self->_children == nil)
            self->_children = [[NSMutableArray alloc] init];
        [self setTag:tagTreeItemDirty];
    }
    NSArray *pcomps = [theURL pathComponents];
    unsigned long level = [[_url pathComponents] count];
    unsigned long leaf_level = [pcomps count]-1;
    if (level < leaf_level) {
        NSURL *pathURL = [self.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
        child = [[TreeBranch new] initWithURL:pathURL parent:self];
        [self addItem:child];
        return [(TreeBranch*)child addURL:theURL];
    }
    else if (level == leaf_level) {
        TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:self];
        [self addItem:newObj];
        return newObj; /* Stops here Nothing More to Add */
    }
    NSLog(@"Ai Caramba!!! This Item can't contain this URL !!! ");
    return nil; // Ai Caramba !!!
}


/* Private Method : This is so that we don't have Manual KVO clauses inside. All calling methods should have it */
-(TreeItem*) _addURLnoRecurr:(NSURL*)theURL {
    /* Check first if base path is common */
    //NSRange result;
    if (theURL==nil) {
        NSLog(@"OOOOPSS! Something went deadly wrong here.\nThe URL is null");
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
        [self setTag:tagTreeItemDirty];
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
            child = [[TreeBranch new] initWithURL:pathURL parent:cursor];
            @synchronized(cursor) {
                [cursor->_children addObject:child];
                [cursor setTag:tagTreeItemDirty];
            }
        }
        cursor = (TreeBranch*)child;
        if (cursor->_children==nil) {
            cursor->_children = [[NSMutableArray alloc] init];
            [cursor setTag:tagTreeItemDirty];
        }
        level++;
    }
    // Checks if it exists ; The base class is provided TreeItem so that it can match anything
    TreeItem *newObj = [cursor childWithName:[pcomps objectAtIndex:level] class:[TreeItem class]];
    if  (newObj==nil) {
        newObj = [TreeItem treeItemForURL:theURL parent:cursor];
        @synchronized(cursor) {
            [cursor->_children addObject:newObj];
            [cursor setTag:tagTreeItemDirty];
        }
    }
    return newObj; /* Stops here Nothing More to Add */
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
-(long long) filesize {
    long long total=0;
    @synchronized(self) {
        if (self->_children!=nil) {
            for (TreeItem *item in self->_children) {
                total+= [item filesize];
            }
        }
        //    NSNumber *amountSum = [self->children valueForKeyPath:@"@sum.filesize"];
        //    if (total != [amountSum longLongValue])
        //        NSLog(@"comparing two calculations %lld == %@", total, amountSum);
    }
    return total;
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
