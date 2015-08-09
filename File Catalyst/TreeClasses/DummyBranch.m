//
//  DummyBranch.m
//  Caravelle
//
//  Created by Nuno on 08/08/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "DummyBranch.h"
#import "TreeManager.h"

@implementation DummyBranch

+(instancetype) parentFor:(TreeItem*) item {
    NSURL *url;
    id parent;
    if (item.parent) {
        parent = item.parent.parent;
        url = item.parent.url;
    }
    else {
        if ([[item.url pathComponents] count]==1) {
            return nil;
        }
        url = [item.url URLByDeletingLastPathComponent];

    }

    DummyBranch *answer = [[DummyBranch alloc] initWithURL:url parent:parent];
    [answer setNameCache:@".."];
    return answer;
}

-(TreeItemTagEnum) tag {
    return _tag | tagTreeItemReadOnly;
}

-(BOOL) hasTags:(TreeItemTagEnum) tag {
    return ((_tag  | tagTreeItemReadOnly) & tag)!=0 ? YES : NO;
}

-(NSString*) name {
    return self.nameCache;
}

-(TreeItem*) parent {
    if (super.parent != nil) {
        return super.parent;
    }
    else {
        return [appTreeManager getNodeWithURL:[self.url URLByDeletingLastPathComponent]];
    }
}
// TODO:1.3 Add a badge to the image

@end
