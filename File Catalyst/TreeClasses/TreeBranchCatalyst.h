//
//  TreeBranchCatalyst.h
//  Caravelle
//
//  Created by Nuno on 02/10/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"
#import "TreeManager.h"

@interface TreeBranchCatalyst : TreeBranch<PathObserverProtocol>

+(id) treeItemForURL:(NSURL *)url parent:(id)parent;

-(void) removeFilesWithoutDuplicates;

@end
