//
//  TreeBranch_TreeBranchPrivate.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 30/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"

@interface TreeBranch( PrivateMethods )

-(void) _harvestItemsInBranch:(NSMutableArray*)collector;
-(void) _harvestLeafsInBranch:(NSMutableArray*)collector;
-(TreeItem*) _addURLnoRecurr:(NSURL*)theURL;
-(void) refreshTreeFromURLs;
-(void) _setChildren:(NSMutableArray*) children;

@end


