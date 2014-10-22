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
    NSString *_name;
}

-(TreeBranch*) initWithFilter:(NSPredicate*)filt name:(NSString*)name parent:(TreeBranch*)parent;
//-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;

-(void) setParent:(TreeItem *)parent;

@end
