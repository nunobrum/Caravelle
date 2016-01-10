//
//  DuplicateDelegate.m
//  Caravelle
//
//  Created by Nuno on 10/01/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "DuplicateDelegate.h"
#import "TreeManager.h"
#import "DuplicateFindOperation.h"

@implementation DuplicateDelegate {
    AppDelegate *_application;
}

-(instancetype) initWithInfo:(NSDictionary*) info app:(AppDelegate*)app {
    self = [super init];
    self->_application = app;
    self.unifiedDuplicatesRoot = nil;
    self.rootsWithDuplicates = nil;
    self.duplicates = [[FileCollection alloc] init];
    return self;
}

-(void) setDuplicateInfo:(NSDictionary *)info {
    
    [self.duplicates setFiles: [info objectForKey:kDuplicateList]];
    
    // Dual View
    self.rootsWithDuplicates = [info objectForKey:kRootsList];
    // Single View
    self.unifiedDuplicatesRoot = [info objectForKey:kRootUnified];
    
    [self.rootsWithDuplicates purgeEmptyFolders];
    
    for (TreeBranchCatalyst *root in self.rootsWithDuplicates.itemsInNode)
        [appTreeManager addActivityObserver:self path:root.path];
    
    [self.unifiedDuplicatesRoot addObserver:self forKeyPath:kvoTreeBranchPropertyChildren options:0 context:NULL];
}

-(void) deinit {
    [appTreeManager removeActivityObserver:self];
    [self.unifiedDuplicatesRoot removeObserver:self forKeyPath:kvoTreeBranchPropertyChildren];
    
    self.unifiedDuplicatesRoot = nil;
    self.rootsWithDuplicates = nil;

}

-(void) pathHasChanged:(NSString *)path {
    [self.unifiedDuplicatesRoot setTag:tagTreeItemDirty];
    [self.unifiedDuplicatesRoot refresh];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kvoTreeBranchPropertyChildren]) {
        // If the unified has already changed, will refresh the tree
        [self.rootsWithDuplicates releaseReleasedChildren];
        [self.rootsWithDuplicates purgeEmptyFolders];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationRefreshViews object:self userInfo:nil];
    }
}


@end
