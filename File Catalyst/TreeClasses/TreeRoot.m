//
//  TreeRoot.m
//  Caravelle
//
//  Created by Nuno Brum on 1/16/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeRoot.h"
#import "TreeBranch_TreeBranchPrivate.h"

@implementation TreeRoot

-(void) setName:(NSString*)name {
    self->_name = name;
}

-(NSString*) name {
    return self->_name;
}

-(void) setFileCollection:(FileCollection*)collection {
    _children = collection.fileArray;
}

- (void) refreshContents {
    NSLog(@"TreeRoot.refreshContents:(%@)", [self name]);
    if ([self needsRefresh]) {
        [self setTag: tagTreeItemUpdating];
        [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
        
        @synchronized(self) {
            // Set all items as candidates for release
            NSUInteger index = 0 ;
            while ( index < [_children count]) {
                TreeItem *item = self->_children[index];
                if ([item hasTags:tagTreeItemRelease]!=0)
                    [self->_children removeObjectAtIndex:index];
                     // at this point the files should be marked as released
                else if (fileExistsOnPath([item path])==NO) // Safefy check
                    [self->_children removeObjectAtIndex:index];
                else
                    index++;
            }
            self->size_files = -1; // Invalidates the previous calculated size
            
            
            // Now going to release the disappeard items
            [self resetTag:(tagTreeItemUpdating+tagTreeItemDirty) ]; // Resets updating and dirty
            [self setTag: tagTreeItemScanned];
            
            // Change the bit to be consistent with the mode. Like the TreeBranch does.
            if ([[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_SEE_HIDDEN_FILES])
                [self setTag:tagTreeHiddenPresent];
            else
                [self resetTag:tagTreeHiddenPresent];
            
        } // synchronized
        [self notifyDidChangeTreeBranchPropertyChildren];   // This will inform the observer about change
        
    }
}

@end
