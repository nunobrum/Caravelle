//
//  filterBranch.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 12/10/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"

@interface filterBranch : TreeBranch {
    NSPredicate *_filter;
    NSString *_branchName;
}

-(TreeBranch*) initWithFilter:(NSPredicate*)filt name:(NSString*)name parent:(TreeBranch*)parent;
//-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;

@property NSPredicate *filter;

#pragma mark overriden methods
// This method is overriden so that the url attribute can be set with the parents url
-(NSString*) name; // This is needed to return the branchName as Name.
-(void) setParent:(TreeItem *)parent;
-(TreeItem*) addURL:(NSURL*)theURL;
-(BOOL) canContainURL:(NSURL *)url;

#pragma mark -
#pragma mark new methods
-(BOOL) addTreeItem:(TreeItem*)treeItem;
-(TreeItem*) addMDItem:(NSMetadataItem*)mdItem;
-(BOOL) canContainMDItem:(NSMetadataItem *)mdItem;
-(BOOL) canContainTreeItem:(TreeItem *)treeItem;

#pragma mark -
#pragma mask KVO Validation
-(BOOL)validateBranchName:(id *)ioValue error:(NSError * __autoreleasing *)outError;

@end
