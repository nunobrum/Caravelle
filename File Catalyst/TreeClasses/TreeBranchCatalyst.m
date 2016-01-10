//
//  TreeBranchCatalyst.m
//  Caravelle
//
//  Created by Nuno on 02/10/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "TreeBranchCatalyst.h"
#import "TreeBranch_TreeBranchPrivate.h"

/* This class is the same as TreeBranch, but the refresh won't be done from the URL.
  refreshContens will only check for released and deleted items */

@implementation TreeBranchCatalyst

-(instancetype) initWithURL:(NSURL*)url parent:(TreeBranch*)parent {
    self = [super initWithURL:url parent:parent];
    self.nameCache = url.lastPathComponent;
    return self;
}

+(id) treeItemForURL:(NSURL *)url parent:(id)parent {
    id answer;
    if (isFolder(url)) {
        answer = [[TreeBranchCatalyst alloc] initWithURL:url parent:parent];
        return answer;
    }
    return [super treeItemForURL:url parent:parent];
}

-(void) setName:(NSString*)name {
    self.nameCache = name;
}

-(NSString*) name {
    if (self.nameCache==nil) {
        if (self.url!=nil) {
            self.nameCache = self.url.lastPathComponent;
        }
        NSLog(@"TreeBranchCatalyst.name WARNING:going to return NULL");
    }
    return self.nameCache;
}

-(BOOL) needsSizeCalculation {
    return NO;
}

-(BOOL) addTreeItem:(TreeItem*) newItem {
    @synchronized(self) {
        if (self->_children == nil)
            self->_children = [[NSMutableArray alloc] init];
    }
    TreeBranchCatalyst *cursor = self;
    NSArray *pcomps = [newItem.url pathComponents];
    unsigned long level = [[_url pathComponents] count];
    unsigned long leaf_level = [pcomps count]-1;
    while (level < leaf_level) {
        NSURL *pathURL = [cursor.url URLByAppendingPathComponent:pcomps[level] isDirectory:YES];
        TreeBranchCatalyst *child = (TreeBranchCatalyst*)[cursor childContainingURL:pathURL];
        if (child==nil) {/* Doesnt exist or if existing is not branch*/
            /* This is a new Branch Item that will contain the URL*/
            child = [[TreeBranchCatalyst alloc] initWithURL:pathURL parent:cursor];
            if (child!=nil) {
                @synchronized(cursor) {
                    [cursor->_children addObject:child];
                }
            }
            else {
                NSLog(@"TreeBranchCatalyst._addURLnoRecurr: Couldn't create path %@",pathURL);
            }
        }
        if ([child isFolder])
        {
            cursor = child;
            if (cursor->_children==nil) {
                cursor->_children = [[NSMutableArray alloc] init];
            }
        }
        else {
            // Will ignore this child
            NSLog(@"TreeBranchCatalyst._addTreeItem: Error:%@ can't be added to %@", newItem.url, pathURL);
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
    if (newItem->_parent==nil) {
        [newItem setParent:cursor];
    }
    return YES; /* Stops here Nothing More to Add */
}

-(BOOL) needsRefresh {
    // Always consider that it was scanned.
    [self setTag:tagTreeItemScanned];
    return [super needsRefresh];
}

-(BOOL) canAndNeedsFlat {
    return NO;
}

-(BOOL) purgeEmptyFolders {
    int purged = 0;
    int elCounter = 0;
    @synchronized(self) {
        while (elCounter < [self.children count]) {
            id elem = [self.children objectAtIndex:elCounter];
            if ([elem respondsToSelector:@selector(purgeEmptyFolders)]) {
                if ([elem purgeEmptyFolders]) {
                    [self.children removeObjectAtIndex:elCounter];
                    [elem setTag:tagTreeItemRelease];
                    purged++;
                }
                else
                    elCounter++;
            }
            else
                elCounter++;
        }
    }
    if (purged>0) {
        [self notifyDidChangeTreeBranchPropertyChildren];
    }
    return (elCounter==0);
}

-(void) refresh {
    if ([self needsRefresh]) {
        [self tagRefreshStart];
        //NSLog(@"TreeBranch.refreshContents:(%@) H:%hhd", [self path], [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_SEE_HIDDEN_FILES]);
        //NSLog(@"TreeBranchCatalyst.refresh (%@)", [self path]);
        
        [browserQueue addOperationWithBlock:^(void) {
            BOOL is_dirty = NO;
            //[self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
            @synchronized(self) {
                // Set all items as candidates for release
                NSUInteger index = 0 ;
                while ( index < [_children count]) {
                    TreeItem *item = self->_children[index];
                    if ([item hasTags:tagTreeItemRelease]!=0) {
                        [item removeItem];  // This assures that its removal from duplicates chains is completed. And also from registered parent
                        [self->_children removeObject:item];
                        is_dirty = YES;
                    }
                    // at this point the files should be marked as released
                    else if (fileExistsOnPath([item path])==NO) { // Safefy check
                        [item removeItem];  // This assures that its removal from duplicates chains is completed. And also from registered parent
                        [self->_children removeObject:item];
                        is_dirty = YES;
                    }
                    else {
                        [item updateFileTags];
                        index++;
                    }
                }
                // If in duplicate Mode, will make another pass to remove files without duplicates
                if ((application_mode() & ApplicationModeDupBrowser)!=0) {
                    if ([self _removeFilesWithoutDuplicates]) is_dirty = YES;
                }
                if (is_dirty) {
                    [self _invalidateSizes]; // Invalidates the previous calculated size
                }
                [self tagRefreshFinished];
                
            } // synchronized
            if (is_dirty)
                [self notifyDidChangeTreeBranchPropertyChildren];   // This will inform the observer about change
         }];
    }
}

-(BOOL) _removeFilesWithoutDuplicates {
    NSInteger index = 0;
    BOOL is_dirty = NO;
    while ( index < [_children count]) {
        TreeItem *item = self->_children[index];
        if ([item isKindOfClass:[TreeLeaf class]] && ([item hasDuplicates]==NO)) {
            [self->_children removeObjectAtIndex:index];
            is_dirty = YES;
        }
        else {
            if ([item isKindOfClass:[TreeBranchCatalyst class]]) {
                [(TreeBranchCatalyst*)item removeFilesWithoutDuplicates];
            }
            index++;
        }
    }
    return is_dirty;
}

-(void) removeFilesWithoutDuplicates {
    BOOL hasChanged = NO;
    @synchronized(self) {
        if ([self _removeFilesWithoutDuplicates]) {
            [self _invalidateSizes];
            hasChanged = YES;
        }
    } // synchronized
    if (hasChanged)
        [self notifyDidChangeTreeBranchPropertyChildren];   // This will inform the observer about change
}

-(void) pathHasChanged:(NSString *)path {
    [self setTag:tagTreeItemDirty];
    [self refresh];
}

-(NSString*) debugDescription {
    return [NSString stringWithFormat:@"%@|name:%@", super.debugDescription, self.nameCache];
}

@end
