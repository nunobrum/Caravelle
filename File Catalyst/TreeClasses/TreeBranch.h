//
//  TreeBranch.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"
#import "TreeLeaf.h"
#import "FileCollection.h"

@interface TreeBranch : TreeItem <TreeProtocol>

@property (retain) NSMutableArray *children;

-(TreeBranch*) init;

-(BOOL)      isBranch;
-(void)      removeBranch;
-(NSInteger) numberOfLeafsInNode;
-(NSInteger) numberOfBranchesInNode;
-(NSInteger) numberOfItemsInNode;

-(NSInteger) numberOfLeafsInBranch;

-(NSInteger) numberOfFileDuplicatesInBranch;

-(TreeBranch*) branchAtIndex:(NSUInteger)index;
-(TreeLeaf*) leafAtIndex:(NSUInteger)index;

-(NSString*) path;

-(FileCollection*) filesInNode;
-(FileCollection*) filesInBranch;
-(NSMutableArray*) itemsInNode;
-(NSMutableArray*) itemsInBranch;
-(NSMutableArray*) leafsInNode;
-(NSMutableArray*) leafsInBranch;
-(NSMutableArray*) branchesInNode;
//-(NSMutableArray*) branchesInBranch;

-(FileCollection*) duplicatesInNode;
-(FileCollection*) duplicatesInBranch;

-(void) refreshTreeFromURLs;

// Private Method
//-(void) _harvestItemsInBranch:(NSMutableArray*)collector;

@end
