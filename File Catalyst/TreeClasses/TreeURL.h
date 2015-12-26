//
//  TreeLeaf.h
//  Caravelle
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"




@interface TreeURL : TreeItem {
    NSURL *_url;
    NSMutableDictionary *_store;
}

+(id)treeItemForURL:(NSURL *)url parent:(id)parent;
+(id)treeItemForMDItem:(NSMetadataItem *)mdItem parent:(id)parent;

-(TreeURL*) initWithURL:(NSURL*)url parent:(id)parent;
-(TreeItem*) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent;

-(void) purgeURLCacheResources;



-(NSDate*)   date_modified;
-(NSDate*)   date_accessed;
-(NSDate*)   date_created;
-(NSString*) path;
-(NSString*) location;
-(NSNumber*) exactSize;
-(NSNumber*) allocatedSize;
-(NSNumber*) totalSize;
-(NSNumber*) totalAllocatedSize;
-(NSString*) fileKind;


-(void) setUrl:(NSURL*)url;
-(NSURL*) url;

-(void) updateFileTags;

/*
 * File manipulation methods
 */
-(BOOL) openFile;
-(BOOL) removeItem;

/*
 * URL Comparison methods
 */

-(enumPathCompare) relationToPath:(NSString*) otherPath;
-(enumPathCompare) compareTo:(TreeItem*) otherItem;
-(BOOL) canContainPath:(NSString*)path;
-(BOOL) containedInPath: (NSString*) path;
-(BOOL) canContainURL:(NSURL*)url;
-(BOOL) containedInURL:(NSURL*) url;



-(BOOL) hasDuplicates;
-(NSNumber*) duplicateGroup;
/*
 * Dupplicate Support
 */
-(BOOL) compareMD5checksum: (TreeURL*)otherFile;

-(BOOL) addDuplicate:(TreeURL*) duplicateFile group:(NSUInteger)group;
-(TreeURL*) nextDuplicate;
-(NSUInteger) duplicateCount;
-(NSMutableArray*) duplicateList;
-(void) removeFromDuplicateRing;
-(void) resetDuplicates;
-(void) setDuplicateRefreshCount:(NSInteger)count;
-(NSInteger) duplicateRefreshCount;


@end
