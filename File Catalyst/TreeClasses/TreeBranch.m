//
//  TreeBranch.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"
#import "TreeLeaf.h"
#import "MyDirectoryEnumerator.h"

#import "definitions.h"
#include "FileUtils.h"

NSString *const kvoTreeBranchPropertyChildren = @"childrenArray";

NSMutableArray *folderContentsFromURL(NSURL *url, TreeBranch* parent) {
    NSMutableArray *children = [[NSMutableArray alloc] init];
    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:url WithMode:BViewBrowserMode];

    for (NSURL *theURL in dirEnumerator) {
        TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:parent];
        [children addObject:newObj];
    }
    return children;
}

@interface TreeBranch( PrivateMethods )

-(void) _harvestItemsInBranch:(NSMutableArray*)collector;
-(void) _harvestLeafsInBranch:(NSMutableArray*)collector;

@end

@implementation TreeBranch

-(BOOL) isBranch {
    return YES;
}

-(TreeBranch*) init {
    self = [super init];
    self->_children = nil;
    self->refreshing = NO;
    return self;
}

-(TreeBranch*) initWithURL:(NSURL*)url parent:(TreeBranch*)parent {
    self = [super initWithURL:url parent:parent];
    self->_children = nil;
    self->_parent = parent;
    self->refreshing = NO;
    return self;
}


-(void) dealloc {
    [self removeBranch];
}


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



-(TreeBranch*) root {
    TreeBranch *cursor = self;
    while (cursor->_parent!=NULL) {
        cursor=cursor->_parent;
    }
    return cursor;
}

-(void) removeBranch {
    if (_children != nil) {
        for (TreeItem *item in _children) {
            if ([item isBranch])
                [(TreeBranch*)item removeBranch];
        }
        [[self children] removeAllObjects];
        //[self setDateModified:nil];
    }
}

/* Computes the total of all the files in the current Branch */
-(long long) sizeOfNode {
    long long total=0;
    if (_children!=nil) {
        for (TreeItem *item in _children) {
            if ([item isKindOfClass:[TreeLeaf class]]==YES) {
                total+=[item filesize];
            }
        }
    }
    return total;
}

/* Computes the total size of all the files contains in all subdirectories */
-(long long) filesize {
    long long total=0;
    if (_children!=nil) {
        for (TreeItem *item in _children) {
            total+= [item filesize];
        }
    }
    return total;
}

-(NSInteger) numberOfLeafsInNode {
    NSInteger total=0;
    if (_children!=nil) {
        for (TreeItem *item in _children) {
            if ([item isKindOfClass:[TreeLeaf class]]==YES) {
                total++;
            }
        }
    }
    return total;
}

-(NSInteger) numberOfBranchesInNode {
    NSInteger total=0;
    if (_children!=nil) {
        for (TreeItem *item in _children) {
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
                total++;
            }
        }
    }
    return total;
}

-(NSInteger) numberOfItemsInNode {
    if (_children==nil)
        return 0; /* This is needed to invalidate and re-scan the node */
    else
        return [_children count];
}

// This returns the number of leafs in a branch
// this function is recursive to all sub branches
-(NSInteger) numberOfLeafsInBranch {
    NSInteger total=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            total += [(TreeBranch*)item numberOfLeafsInBranch];
        }
        else
            total++;
    }
    return total;
}

/* Returns if the node is expandable 
 Note that if the _children is not populated it is assumed that the
 node is expandable. It is preferable to assume as yes and later correct. */
-(BOOL) isExpandable {
    if ((_children!=nil) && ([self numberOfBranchesInNode]!=0))
        return YES;
    else
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


-(TreeBranch*) branchAtIndex:(NSUInteger) index {
    NSInteger i=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            if (i==index)
                return (TreeBranch*)item;
            i++;
        }
    }
    return nil;
}

-(TreeLeaf*) leafAtIndex:(NSUInteger) index {
    NSInteger i=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            if (i==index)
                return (TreeLeaf*)item;
            i++;
        }
    }
    return nil;
}



-(FileCollection*) filesInNode {
    FileCollection *answer = [[FileCollection new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            FileInformation *finfo;
            finfo = [FileInformation createWithURL:[(TreeLeaf*)item url]];
            [answer AddFileInformation:finfo];
        }
    }
    
    return answer; 
}
-(FileCollection*) filesInBranch {
    return nil; // Pending Implementation
}
-(NSMutableArray*) itemsInNode {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [answer addObjectsFromArray:self->_children];
    return answer;
}

-(void) _harvestItemsInBranch:(NSMutableArray*)collector {
    [collector addObjectsFromArray: _children];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            [(TreeBranch*)item _harvestItemsInBranch: collector];
        }
    }
}
-(NSMutableArray*) itemsInBranch {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self _harvestItemsInBranch:answer];
    return answer; // Pending Implementation
}

-(NSMutableArray*) leafsInNode {
    NSMutableArray *answer = [[NSMutableArray new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [answer addObject:item];
        }
    }
    return answer;
}

-(void) _harvestLeafsInBranch:(NSMutableArray*)collector {
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            [(TreeBranch*)item _harvestLeafsInBranch: collector];
        }
        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [collector addObject:item];
        }
    }
}
-(NSMutableArray*) leafsInBranch {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self _harvestLeafsInBranch: answer];
    return answer; // Pending Implementation
}

-(NSMutableArray*) branchesInNode {
    NSMutableArray *answer = [[NSMutableArray new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            [answer addObject:item];
        }
    }
    return answer;

}

-(TreeItem*) itemWithName:(NSString*) name class:(id)cls {
    for (TreeItem *item in _children) {
        if ([[item name] isEqualToString: name] && [item isKindOfClass:cls]) {
            return item;
        }
    }
    return nil;
}

-(TreeItem*) itemWithURL:(NSURL*) aURL {
    for (TreeItem *item in _children) {
        if ([[item url] isEqualTo: aURL]) {
            return item;
        }
    }
    return nil;
}


-(BOOL) addURL:(NSURL*)theURL {
    /* Check first if base path is common */
    NSRange result;
    result = [[theURL path] rangeOfString:[self path]];
    if (NSNotFound==result.location) {
        // The new root is already contained in the existing trees
        return FALSE;
    }
    TreeBranch *cursor = self;
    if (self.children == nil)
        self.children = [[NSMutableArray alloc] init];
    NSArray *pcomps = [theURL pathComponents];
    unsigned long level = [[_url pathComponents] count];
    unsigned long leaf_level = [pcomps count]-1;
    while (level < leaf_level) {
        TreeItem *child = [cursor itemWithName:[pcomps objectAtIndex:level] class:[TreeBranch class]];
        if (child==nil) {/* Doesnt exist or if existing is not branch*/
            /* This is a new Branch Item that will contain the URL*/
            NSURL *pathURL = [cursor.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
            child = [[TreeBranch new] initWithURL:pathURL parent:cursor];
            [cursor.children addObject:child];
        }
        cursor = (TreeBranch*)child;
        if (cursor.children==nil) {
            cursor.children = [[NSMutableArray alloc] init];
        }
        level++;
    }
    TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:cursor];
    [[cursor children] addObject:newObj];
    return TRUE; /* Stops here Nothing More to Add */
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

/* This is not to be used with Catalyst Mode */
-(void) refreshTreeFromURLs {
    if ([self children]==nil)
        [self setChildren: [[NSMutableArray new] init]];
    else {
        /* Tree was already constructed */
        for (TreeItem *item in self.children)
            item.tag |= tagTreeItemDirty; /* Mark all items as dirty so that at the end of the comparison ones dirty are deleted */
    }
    //NSLog(@"Scanning directory %@", self.path);
    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:self->_url WithMode:BViewBrowserMode];

    for (NSURL *theURL in dirEnumerator) {
        TreeItem *item = [self itemWithURL:theURL];
        if (item==nil) {
            [self addURL:theURL];
        }
        else {
            item.tag &= tagTreeItemDirty;
        }
    } // for
    int idx=0;
    while (idx < [self.children count]) {
        if ([[self.children objectAtIndex:idx] tag] & tagTreeItemDirty) {
            [self.children removeObjectAtIndex:idx];
        }
        idx++;
    }

}

-(NSInteger) relationTo:(NSString*) otherPath {
    NSRange result;
    NSInteger answer = pathsHaveNoRelation;
    result = [otherPath rangeOfString:[self path]];
    if (NSNotFound!=result.location) {
        // The new root is already contained in the existing trees
        answer = pathIsChild;
        //NSLog(@"The added path is contained in existing roots.");

    }
    else {
        /* The new contains exiting */
        result = [[self path] rangeOfString:otherPath];
        if (NSNotFound!=result.location) {
            // Will need to replace current position
            answer = pathIsParent;
            //NSLog(@"The added path contains already existing roots, please delete them.");
            //[root removeBranch];
            //fileCollection_inst = [root fileCollection];
        }
    }
    return answer;
}

- (void)refreshContentsOnQueue: (NSOperationQueue *) queue {
    @synchronized (self) {
        if (self.children == nil && !self->refreshing) {
            self->refreshing = YES;
            // We would have to keep track of the block with an NSBlockOperation, if we wanted to later support cancelling operations that have scrolled offscreen and are no longer needed. That will be left as an exercise to the user.
            [queue addOperationWithBlock:^(void) {
                [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
                    // We synchronize access to the image/imageLoading pair of variables
                    @synchronized (self) {
                        [self refreshTreeFromURLs];
                        self->refreshing = NO;
                        //NSLog(@"Modifying Observed Value %@", [self name]);
                    }
                    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about change

            }];
        }
    }
}


@end
