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

-(filterBranch*) initWithFilter:(NSPredicate*)filt  name:(NSString*)name  parent:(TreeBranch*)parent {
    self = [super initWithURL:nil parent:parent];
    self->_url = [parent url]; // This is needed for compatibility with other methods
                                // such as childContainingURL. The filter is supposed to be used on
                                // filters on the contents of a parent.
    self->_filter = filt;
    self->_name = name;
    return self;
}

//+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
//    searchTree *tree = [searchTree alloc];
//    return [tree initFromEnumerator:dirEnum URL:rootURL parent:parent cancelBlock:cancelBlock];
//}
//
//-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
//    self = [self initWithURL:nil parent:parent];
//    /* Since the instance is created now, there is no problem with thread synchronization */
//    for (NSURL *theURL in dirEnum) {
//        [self addURL:theURL];
//        if (cancelBlock())
//            break;
//    }
//    return self;
//}

-(void) setParent:(TreeItem *)parent {
    self->_parent = parent;
    self->_url = [parent url]; // This is needed for compatibility with other methods
    // such as childContainingURL. The filter is supposed to be used on
    // filters on the contents of a parent.
}

-(NSString*) name {
    return self->_name;
}

#pragma mark -
#pragma mark Refreshing contents
- (void)refreshContentsOnQueue: (NSOperationQueue *) queue {
    // This method is overriden to do nothing. The filterBranch has no implementation for this method.
    // It has no URL
}


#pragma mark Tree Access
/*
 * All these methods must be changed for recursive in order to support the searchBranches
 */

-(TreeItem*) childContainingURL:(NSURL*)url {
    /* In contrary to the normal class this will search in all subfolders */
    @synchronized(self) {
        for (TreeItem *item in self->_children) {
            if ([item isKindOfClass:[filterBranch class]]) {
                return [self childContainingURL:url];
            }
            if ([[item url] isEqual:url]) {
                return item;
            }
        }
    }
    return nil;
}

-(BOOL) addTreeItem:(TreeItem*)treeItem {
    if (self->_filter ==nil || [self->_filter evaluateWithObject:treeItem]) {
        NSURL *theURL = [treeItem url];
        @synchronized(self) {
            /* Will also check if exists before adding */
            for (TreeItem *item in self->_children) {
                if ([[item url] isEqual:theURL]) {
                    return YES; // if matches, no need to add just return YES
                }
                else if ([item isKindOfClass:[filterBranch class]]) {
                    if ([(filterBranch*)item addTreeItem:treeItem]) {
                         return YES;
                    }
                }
            } // for
        } // @synchronized
        [self addChild:treeItem];
        return YES;
    }
    return NO;
}

-(TreeItem*) addURL:(NSURL*)theURL {
    TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:self];
    if ([self addTreeItem:newObj])
        return newObj;
    else
        return nil;
}

-(BOOL) containsURL:(NSURL *)url {
    TreeItem *newObj = [TreeItem treeItemForURL:url parent:nil];
    BOOL result = [self->_filter evaluateWithObject:newObj];
    if (result) {
        for (TreeItem *item in _children) {
            if ([[item url] isEqual:url])
                return YES;
        }
    }
    return NO;
}

-(TreeItem*) addMDItem:(NSMetadataItem*)mdItem {
    TreeItem *newObj = [TreeItem treeItemForMDItem:mdItem parent:self];
    if ([self addTreeItem:newObj])
        return newObj;
    else
        return nil;
}

-(BOOL) containsMDItem:(NSMetadataItem *)mdItem {
    /* The URL is created because I consider it safer to compare URLs,
     May revise this premise later on */
    NSString *path = [mdItem valueForAttribute:(id)kMDItemPath];
    NSURL *url = [NSURL fileURLWithPath:path];
    TreeItem *newObj = [TreeItem treeItemForMDItem:mdItem parent:nil];
    BOOL result = [self->_filter evaluateWithObject:newObj];
    if (result) {
        for (TreeItem *item in _children) {
            if ([[item url] isEqual:url])
                return YES;
        }
    }
    return NO;
}


@end
