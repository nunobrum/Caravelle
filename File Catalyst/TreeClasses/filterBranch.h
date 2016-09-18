//
//  filterBranch.h
//  File Catalyst
//
//  Created by Nuno Brum on 12/10/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "TreeBranchCatalyst.h"

@interface filterBranch : TreeBranchCatalyst {
    NSPredicate *_filter;
}

-(TreeBranch*) initWithFilter:(NSPredicate*)filt name:(NSString*)name parent:(TreeBranch*)parent;
//-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;

@property NSPredicate *filter;

#pragma mark overriden methods
// This method is overriden so that the url attribute can be set with the parents url
-(void) setParent:(TreeBranch *)parent;
-(TreeItem*) addURL:(NSURL*)theURL;
-(BOOL) canContainURL:(NSURL *)url;

#pragma mark -
#pragma mark new methods
-(BOOL) addTreeItem:(TreeItem*)treeItem;
-(NSInteger) addItemArray:(NSArray*) items;

-(TreeItem*) addMDItem:(NSMetadataItem*)mdItem;
-(BOOL) canContainMDItem:(NSMetadataItem *)mdItem;
-(BOOL) canContainTreeItem:(TreeItem *)treeItem;

#pragma mark -
#pragma mask KVO Validation
-(BOOL)validateBranchName:(id *)ioValue error:(NSError * __autoreleasing *)outError;

@end
