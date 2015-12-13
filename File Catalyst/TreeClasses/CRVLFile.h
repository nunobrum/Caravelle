//
//  TreeLeaf.h
//  Caravelle
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "CRVLItem.h"

@interface CRVLFile : CRVLItem  {
    NSMutableDictionary *_store;
}

-(CRVLFile*) initWithURL:(NSURL*)url parent:(id)parent;

/*
 * Dupplicate Support
 */
-(BOOL) compareMD5checksum: (CRVLFile*)otherFile;

-(BOOL) addDuplicate:(CRVLFile*) duplicateFile group:(NSUInteger)group;
-(CRVLFile*) nextDuplicate;
-(NSUInteger) duplicateCount;
-(NSMutableArray*) duplicateList;
-(void) removeFromDuplicateRing;
-(void) resetDuplicates;
-(void) setDuplicateRefreshCount:(NSInteger)count;
-(NSInteger) duplicateRefreshCount;


@end
