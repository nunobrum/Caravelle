//
//  TreeBranch.h
//  Caravelle
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"
#import "TreeURL.h"
//#import "FileCollection.h"

extern NSString *const kvoTreeBranchPropertyChildren;
extern NSString *const kvoTreeBranchPropertySize;
//extern NSString *const kvoTreeBranchReleased;

extern NSString* commonPathFromItems(NSArray* itemArray);
//extern NSArray* treesContaining(NSArray* treeItems);

@interface TreeBranchURL : TreeBranch {

@protected
    NSURL *_url;
    long long size_files;
    long long size_allocated;
    long long size_total;
    long long size_total_allocated;
}

-(instancetype) initWithURL:(NSURL*)url parent:(TreeBranch*)parent;
-(instancetype) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent;
-(long long) sizeOfNode;

// Common to TreeURL

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


///// End of Common to TreeURL

-(TreeURL*) childContainingURL:(NSURL*)url;
-(TreeURL*) getNodeWithURL:(NSURL*)url;
-(TreeURL*) getNodeWithPath:(NSString*)path;
-(TreeURL*) addURL:(NSURL*)theURL;
-(BOOL)      addTreeItem:(TreeURL*) item;


-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;
+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;


-(void) calculateSize;
-(void) setSizes:(long long)files allocated:(long long)allocated total:(long long)total totalAllocated:(long long) totalallocated;
-(void) sizeCalculationCancelled;


@end

