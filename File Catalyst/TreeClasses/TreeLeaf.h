//
//  TreeLeaf.h
//  Caravelle
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"

@interface TreeLeaf : TreeItem <TreeProtocol> {
    NSMutableDictionary *_store;
}

-(TreeLeaf*) initWithURL:(NSURL*)url parent:(id)parent;

/*
 * Dupplicate Support
 */
-(BOOL) compareMD5checksum: (TreeLeaf*)otherFile;

-(BOOL) addDuplicate:(TreeLeaf*) duplicateFile group:(NSUInteger)group;
-(TreeLeaf*) nextDuplicate;
-(NSUInteger) duplicateCount;
-(NSMutableArray*) duplicateList;
-(void) removeFromDuplicateRing;
-(void) resetDuplicates;
-(void) setDuplicateRefreshCount:(NSInteger)count;
-(NSInteger) duplicateRefreshCount;
-(BOOL) hasDuplicates;


@end
