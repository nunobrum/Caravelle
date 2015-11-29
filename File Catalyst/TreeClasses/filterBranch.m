//
//  filterBranch.m
//  File Catalyst
//
//  Created by Nuno Brum on 12/10/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "filterBranch.h"

@implementation filterBranch

#pragma mark Initializers

-(ItemType) itemType {
    return ItemTypeFilter;
}

-(filterBranch*) initWithFilter:(NSPredicate*)filt  name:(NSString*)name  parent:(TreeBranch*)parent {
    // self = [super initWithURL:nil parent:parent]; Now a nil can't be passed to the initWithURL
    self->_children = nil;
    [self setParent:parent];    // This routine also sets url to be the same of the parent.
                                // This is needed for compatibility with other methods
                                // such as childContainingURL. The filter is supposed to be used on
                                // filters on the contents of a parent.
    self->_filter = filt;
    self->_branchName = name;
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

-(NSString*) name {
    return _branchName;
}

-(NSImage*) image {
    return [NSImage imageNamed:@"SearchFolder"];
}

-(NSDate*) date_modified {
    return nil;
}

-(NSString*) fileKind {
    return @"Search Folder";
}

-(void) setParent:(TreeItem *)parent {
    self->_parent = parent;
    [self setUrl:[parent url]]; // This is needed for compatibility with other methods
    // such as childContainingURL. The filter is supposed to be used on
    // filters on the contents of a parent.
}

-(NSString*) branchName {
    return self->_branchName;
}

#pragma mark -
#pragma mark Refreshing contents
- (void)refreshContents {
    // This method is overriden to do nothing. The filterBranch has no implementation for this method.
    // It has no URL
}


#pragma mark Tree Access
/*
 * All these methods must be changed for recursive in order to support the searchBranches
 */

-(BOOL) canContainTreeItem:(TreeItem *)treeItem {
    return (self->_filter ==nil || [self->_filter evaluateWithObject:treeItem]);

}

-(BOOL) addTreeItem:(TreeItem*)treeItem {
    if ([self canContainTreeItem:treeItem]) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                if ([item itemType ] == ItemTypeFilter) {
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

-(NSInteger) addItemArray:(NSArray*) items {
    NSInteger counter = 0;
    @synchronized(self) {
        [self willChangeValueForKey:kvoTreeBranchPropertyChildren];
        if (self->_filter==nil) {
            if (self->_children==nil) {
                self->_children = [[NSMutableArray alloc] initWithArray:items copyItems:NO];
            }
            else {
                // Will just add the Items
                [self->_children addObjectsFromArray:items];
            }
            counter = [items count];
        }
        else {
            if (self->_children==nil) {
                self->_children = [[NSMutableArray alloc] initWithCapacity:[items count]];
            }
            for (TreeItem* item in items) {
                BOOL inserted = NO;
                if ([self canContainTreeItem:item]) {
                    for (TreeItem *filter in self->_children) {
                        if ([filter itemType] == ItemTypeFilter) {
                            if ([(filterBranch*)filter addTreeItem:item]) {
                                inserted = YES;
                                break;
                            }
                        }
                        else {
                            // This is possible optimization if the system ensures that filters are sorted to be the first elements
                            break;
                        }
                    }
                    if (inserted == NO) {
                        // Didn't fit in any subfolders. Need to add it to self.
                        [self->_children addObject:item];
                    }
                    counter++;
                }
            }
        }
        [self didChangeValueForKey:kvoTreeBranchPropertyChildren];
    }
    return counter;
}

-(TreeItem*) addURL:(NSURL*)theURL {
    TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:self];
    if ([self addTreeItem:newObj])
        return newObj;
    else
        return nil;
}

-(BOOL) canContainURL:(NSURL *)url {
    TreeItem *testObj = [TreeItem treeItemForURL:url parent:nil];
    return [self canContainTreeItem:testObj];
}

-(TreeItem*) addMDItem:(NSMetadataItem*)mdItem {
    TreeItem *newObj = [TreeItem treeItemForMDItem:mdItem parent:self];
    if ([self addTreeItem:newObj])
        return newObj;
    else
        return nil;
}

-(BOOL) canContainMDItem:(NSMetadataItem *)mdItem {
    TreeItem *testObj = [TreeItem treeItemForMDItem:mdItem parent:nil];
    return [self canContainTreeItem:testObj];
}

/* Redefining this method just for optimization as each
 * iteration will create a test object */
-(TreeItem*) childContainingURL:(NSURL*) aURL {
    TreeItem *testObj = [TreeItem treeItemForURL:aURL parent:nil];
    if ([self canContainTreeItem:testObj]) {
        @synchronized(self) {
            for (TreeItem *item in self->_children) {
                if ([item itemType ] == ItemTypeFilter) {
                    if ([(filterBranch*)item canContainTreeItem:testObj])
                        return item;
                }
                else if ([item canContainURL:aURL]) {
                    return item;
                }
            }
        }
    }
    return nil;
}

#pragma mark -
#pragma mask KVO Validation
-(BOOL)validateBranchName:(id *)ioValue error:(NSError * __autoreleasing *)outError {
    // The name must not be nil, and must be at least 1 characters long.
    if ((*ioValue == nil) || ([(NSString *)*ioValue length] < 1)) {
        if (outError != NULL) {
            //NSString *errorString = NSLocalizedString(
            //                                          @"A Person's name must be at least two characters long",
            //                                          @"validation: Person, too short name error");
            //NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
            *outError = [[NSError alloc] initWithDomain:@"FilterBranch Errors"
                                                   code:01
                                               userInfo:nil ]; //userInfoDict];
        }
        return NO;
    }
    return YES;}


@end
