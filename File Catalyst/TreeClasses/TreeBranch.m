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


@implementation TreeBranch

-(BOOL) isBranch {
    return YES;
}


-(TreeBranch*) initWithURL:(NSURL*)url parent:(TreeBranch*)parent {
    self = [super initWithURL:url parent:parent];
    self->children = nil;
    return self;
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


/* Computes the total of all the files in the current Branch */
-(long long) sizeOfNode {
    long long total=0;
    @synchronized(self) {
        if (self->children!=nil) {
            for (TreeItem *item in self->children) {
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
        if (self->children!=nil) {
            for (TreeItem *item in self->children) {
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
        if (self->children!=nil) {
            for (TreeItem *item in self->children) {
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
        if (self->children!=nil) {
            for (TreeItem *item in self->children) {
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
        if (self->children!=nil) {
            return [self->children count]; /* This is needed to invalidate and re-scan the node */
        }
    }
    return 0;
}

// This returns the number of leafs in a branch
// this function is recursive to all sub branches
-(NSInteger) numberOfLeafsInBranch {
    NSInteger total=0;
    @synchronized(self) {
        for (TreeItem *item in self->children) {
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
        if ((self->children!=nil) && ([self numberOfBranchesInNode]!=0))
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


-(TreeBranch*) branchAtIndex:(NSUInteger) index {
    NSInteger i=0;
    @synchronized(self) {
        for (TreeItem *item in self->children) {
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
                if (i==index)
                    return (TreeBranch*)item;
                i++;
            }
        }
    }
    return nil;
}

-(TreeLeaf*) leafAtIndex:(NSUInteger) index {
    NSInteger i=0;
    @synchronized(self) {
        for (TreeItem *item in self->children) {
            if ([item isKindOfClass:[TreeLeaf class]]==YES) {
                if (i==index)
                    return (TreeLeaf*)item;
                i++;
            }
        }
    }
    return nil;
}



-(FileCollection*) filesInNode {
    @synchronized(self) {
        FileCollection *answer = [[FileCollection new] init];
        for (TreeItem *item in self->children) {
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
        [answer addObjectsFromArray:self->children];
        return answer;
    }
    return NULL;
}

-(void) _harvestItemsInBranch:(NSMutableArray*)collector {
    @synchronized(self) {
        [collector addObjectsFromArray: self->children];
        for (TreeItem *item in self->children) {
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
        for (TreeItem *item in self->children) {
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
        for (TreeItem *item in self->children) {
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
        for (TreeItem *item in self->children) {
            if ([item isKindOfClass:[TreeBranch class]]==YES) {
                [answer addObject:item];
            }
        }
        return answer;
    }
    return nil;
}

-(TreeItem*) itemWithName:(NSString*) name class:(id)cls {
    @synchronized(self) {
        for (TreeItem *item in self->children) {
            if ([[item name] isEqualToString: name] && [item isKindOfClass:cls]) {
                return item;
            }
        }
    }
    return nil;
}

-(TreeItem*) itemWithURL:(NSURL*) aURL {
    @synchronized(self) {
        for (TreeItem *item in self->children) {
            if ([[item url] isEqualTo: aURL]) {
                return item;
            }
        }
    }
    return nil;
}


/* Private Method : This is so that we don't have @synchronized clauses inside. All calling methods should have it */
-(BOOL) addURL:(NSURL*)theURL {
    /* Check first if base path is common */
    NSRange result;
    if (theURL==nil) {
        NSLog(@"OOOOPSS! Something went deadly wrong here.\nThe URL is null");
        return FALSE;
    }
    result = [[theURL path] rangeOfString:[self path]];
    if (NSNotFound==result.location) {
        // The new root is already contained in the existing trees
        return FALSE;
    }
    TreeBranch *cursor = self;
    if (self->children == nil)
        self->children = [[NSMutableArray alloc] init];
    NSArray *pcomps = [theURL pathComponents];
    unsigned long level = [[_url pathComponents] count];
    unsigned long leaf_level = [pcomps count]-1;
    while (level < leaf_level) {
        TreeItem *child = [cursor itemWithName:[pcomps objectAtIndex:level] class:[TreeBranch class]];
        if (child==nil) {/* Doesnt exist or if existing is not branch*/
            /* This is a new Branch Item that will contain the URL*/
            NSURL *pathURL = [cursor.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
            child = [[TreeBranch new] initWithURL:pathURL parent:cursor];
            [cursor->children addObject:child];
        }
        cursor = (TreeBranch*)child;
        if (cursor->children==nil) {
            cursor->children = [[NSMutableArray alloc] init];
        }
        level++;
    }
    TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:cursor];
    [cursor->children addObject:newObj];
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

+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
    TreeBranch *tree = [TreeBranch alloc];
    return [tree initFromEnumerator:dirEnum URL:rootURL parent:parent cancelBlock:cancelBlock];
}

-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
    self = [self initWithURL:rootURL parent:parent];
    /* Since the instance is created now, there is no problem with thread synchronization */
    for (NSURL *theURL in dirEnum) {
        [self addURL:theURL];
        if (cancelBlock())
            break;
    }
    return self;
}

/* This is not to be used with Catalyst Mode */
-(NSMutableArray*) childrenRefreshed {
    NSMutableArray *newChildren = [[NSMutableArray new] init];

    //NSLog(@"Scanning directory %@", self.path);
    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:self->_url WithMode:BViewBrowserMode];

    for (NSURL *theURL in dirEnumerator) {
        TreeItem *item = [self itemWithURL:theURL]; /* Retrieves existing Element */
        if (item==nil) { /* If not found creates a new one */
            item = [TreeItem treeItemForURL:theURL parent:self];
        }
        [newChildren addObject:item];

    } // for
    return newChildren;
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

-(BOOL) containsURL:(NSURL*)url {
    NSRange result;
    result = [[url path] rangeOfString:[self path]];
    if (NSNotFound!=result.location) {
        // The new root is already contained in the existing trees
        return YES;
    }
    else {
        return NO;
    }
}


- (void)refreshContentsOnQueue: (NSOperationQueue *) queue {
    @synchronized (self) {
        [queue addOperationWithBlock:^(void) {  // !!! Consider using localOperationsQueue as defined above
            NSMutableArray *newChildren = [self childrenRefreshed];
            [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
            // We synchronize access to the image/imageLoading pair of variables
            @synchronized (self) {
                self->children = newChildren;
            }
            [self didChangeValueForKey:kvoTreeBranchPropertyChildren];   // This will inform the observer about change

        }];
    }
}

-(BOOL) removeItem:(TreeItem*)item {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self) {
        [self->children removeObject:item];
    }
    [self didChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    return YES;
}

-(BOOL) addItem:(TreeItem*)item {
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    @synchronized(self) {
        [self->children addObject:item];
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
