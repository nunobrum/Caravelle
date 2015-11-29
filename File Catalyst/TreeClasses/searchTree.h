//
//  searchTree.h
//  File Catalyst
//
//  Created by Nuno Brum on 12/10/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "filterBranch.h"

@interface searchTree : filterBranch <NSMetadataQueryDelegate> {
    NSSearchPathDirectory *_pathDirectory;
    NSMetadataQuery *_query;
    BOOL searchContent;
    NSString *_searchKey;
}

-(searchTree*) initWithSearch:(NSString*)searchKey  name:(NSString*)name parent:(TreeBranch*)parent;

- (void)createSearchPredicate;

@end
