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
    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:url WithMode:NO];

    for (NSURL *theURL in dirEnumerator) {
        TreeItem *newObj = [TreeItem treeItemForURL:theURL];
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
    self = [super initWithURL:url];
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
    if ((_children==nil) || ([self numberOfBranchesInNode]!=0))
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

-(BOOL) addURL:(NSURL*)theURL {
    /* Check first if base path is common */
    if ([self relationTo:[theURL path]]!=pathIsChild)
        return FALSE;
    return [self addURL:theURL withPathComponents:[theURL pathComponents] atLevel:[[_url pathComponents] count]];
}

-(BOOL) addURL:(NSURL*)theURL withPathComponents:(NSArray*) pathComponents atLevel:(NSUInteger)level {
    if (_children==nil)
    {
        _children = [[NSMutableArray new] init];
    }

    if ([pathComponents count]==level+1) {
        TreeItem *newObj;
        if (isFolder(theURL)) {
            /* This is a Leaf Item */
            newObj = [[TreeBranch alloc] initWithURL:theURL parent:self];
        }
        else {
            /* This is a Branch Item */
            newObj =[[TreeLeaf alloc] initWithURL:theURL];
        }
        [_children addObject:newObj];
        return TRUE; /* Stops here Nothing More to Add */
    }

    else { /* The Branch exists. Recursive Add into it */
        TreeItem *child = [self itemWithName:[pathComponents objectAtIndex:level] class:[TreeBranch class]];
        if (child==nil) {/* Doesnt exist or if existing is not branch*/

            /* This is a new Branch Item that will contain the URL*/
            child = [[TreeBranch new] initWithURL:theURL parent:self];
        }
        return [(TreeBranch*) child addURL:theURL withPathComponents:pathComponents atLevel:level+1];

    }
    return FALSE;
}

-(TreeItem*) itemWithName:(NSString*) name class:(id)cls {
    for (TreeItem *item in _children) {
        if ([[item name] isEqualToString: name] && [item isKindOfClass:cls]) {
            return item;
        }
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

/* This is not to be used with Catalyst Mode */
-(void) refreshTreeFromURLs {
    // Will get the first level of the tree

    if ([self children]==nil)
        [self setChildren: [[NSMutableArray new] init]];
    else {
        /* Tree was already constructed */
        /// !!! Think about doing an inteligent refresh here now just returning
        return;
        //[self removeBranch];
    }
    NSLog(@"Scanning directory %@", self.path);
    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:self->_url WithMode:NO];

    for (NSURL *theURL in dirEnumerator) {
        [self addURL:theURL];
    } // for

    /* Now will propagate new totals to parent directories */
    /*TreeBranch *currdir = (TreeBranch*)[self parent];
    while (currdir!=nil) {
        currdir.byteSize+= self.byteSize - oldByteSize;
        currdir = (TreeBranch*)[currdir parent];
    }*/
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
                NSMutableArray *updated = folderContentsFromURL(self.url, self);
                if (updated != nil) {
                    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
                    // We synchronize access to the image/imageLoading pair of variables
                    @synchronized (self) {
                        self->refreshing = NO;
                        self.children = updated;
                        //NSLog(@"Modifying Observed Value %@", [self name]);
                    }
                    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about change
                }
                /* We don't need this
                else {
                    @synchronized (self) {
                        self.image = [NSImage imageNamed:NSImageNameTrashFull];
                    }
                }*/
            }];
        }
    }
}


@end
