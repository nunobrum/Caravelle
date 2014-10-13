//
//  filterBranch.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 12/10/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "filterBranch.h"

@implementation filterBranch

#pragma mark Initializers
-(TreeBranch*) initWithURL:(NSURL*)url parent:(TreeBranch*)parent filter:(NSPredicate*)filt {
    self = [super initWithURL:url parent:parent];
    self->filter = filt;
    return self;
}

//+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
//    searchTree *tree = [searchTree alloc];
//    return [tree initFromEnumerator:dirEnum URL:rootURL parent:parent cancelBlock:cancelBlock];
//}

-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
    self = [self initWithURL:nil parent:parent];
    /* Since the instance is created now, there is no problem with thread synchronization */
    for (NSURL *theURL in dirEnum) {
        [self addURL:theURL];
        if (cancelBlock())
            break;
    }
    return self;
}

#pragma mark -
//#pragma mark Refreshing contents
//- (void)refreshContentsOnQueue: (NSOperationQueue *) queue {
//    @synchronized (self) {
//        if (_tag & tagTreeItemUpdating) {
//            // If its already updating.... do nothing exit here.
//        }
//        else { // else make the update
//            _tag |= tagTreeItemUpdating;
//            [queue addOperationWithBlock:^(void) {  // !!! Consider using localOperationsQueue as defined above
//                NSMutableArray *newChildren = [[NSMutableArray new] init];
//                BOOL new_files=NO;
//
//                NSLog(@"Scanning directory %@", self.path);
//                MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:self->_url WithMode:BViewBrowserMode];
//
//                for (NSURL *theURL in dirEnumerator) {
//                    TreeItem *item = [self childContainingURL:theURL]; /* Retrieves existing Element */
//                    if (item==nil) { /* If not found creates a new one */
//                        item = [TreeItem treeItemForURL:theURL parent:self];
//                        new_files = YES;
//                    }
//                    else {
//                        [item resetTag:tagTreeItemAll];
//                    }
//                    [newChildren addObject:item];
//
//                } // for
//                if (new_files==YES || // There are new Files OR
//                    [newChildren count] < [self->children count]) { // There are deletions
//                    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
//                    // We synchronize access to the image/imageLoading pair of variables
//                    @synchronized (self) {
//                        self->children = newChildren;
//                        _tag &= ~(tagTreeItemUpdating+tagTreeItemDirty); // Resets updating and dirty
//                    }
//                    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about change
//                }
//
//            }];
//        }
//    }
//}
//

#pragma mark Tree Access
/*
 * All these methods must be changed for recursive in order to support the searchBranches
 */

-(TreeItem*) childContainingURL:(NSURL*)url {
    // TODO : !!!
    return [super childWithURL:url];
}

-(TreeItem*) addURL:(NSURL*)theURL {
    TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:self];
    BOOL result = [self->filter evaluateWithObject:self];
    if (result) {
        [self addItem:newObj];
        return  newObj;
    }
    return nil;
}


@end
