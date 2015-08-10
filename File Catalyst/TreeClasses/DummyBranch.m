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

-(instancetype) initWithURL:(NSURL*)url parent:(TreeBranch*)parent {
    self = [super initWithURL:url parent:parent];
    self.target = nil;
    return self;
}

-(ItemType) itemType {
    return ItemTypeDummyBranch; // This is done to avoid being requested for size calculations
}

+(instancetype) parentFor:(TreeItem*) item {
    NSURL *url;
    TreeItem *target;
    if (item->_parent) {
        target = item->_parent;
        url = item->_parent.url;
    }
    else {
        if ([[item.url pathComponents] count]==1) {
            return nil;
        }
        url = [item.url URLByDeletingLastPathComponent];
        target = [appTreeManager addTreeItemWithURL:url askIfNeeded:NO];
    }
    
    DummyBranch *answer = [[DummyBranch alloc] initWithURL:url parent:nil];
    if (target) {
        answer.target = target;
    }
    else
        NSLog(@"DummyBranch.parentFor: couldnt find the target %@", url);
    [answer setNameCache:@".."];
    return answer;
}

-(TreeItemTagEnum) tag {
    return self.target.tag | tagTreeItemReadOnly;
}

-(BOOL) hasTags:(TreeItemTagEnum) tag {
    return ((self.target.tag  | tagTreeItemReadOnly) & tag)!=0 ? YES : NO;
}

-(NSString*) name {
    return self.nameCache;
}


// TODO:1.3 Add a badge to the image


-(id) valueForKey:(NSString *)key {
    //NSLog(@"getting value for key: %@", key);
    
    // priority to redefined methods
    if ([key isEqualToString:@"target"] ||
        [key isEqualToString:@"name"] ||
        [key isEqualToString:@"tag"] ||
        [key isEqualToString:@"hasTags"] ||
        [key isEqualToString:@"itemType"]
        ) {
        return [super valueForKey:key];
    }
    
    // The rest is passed to the target
    else if (self.target != nil) {
        //NSLog(@"DummyBranch.valueForKey:%@  on target", key);
        return [self.target valueForKey:key];
    }
    // if the target doesn't exist
    else {
        NSLog(@"DummyBranch.valueForKey:%@  NO target", key);
        return [super valueForKey:key];
    }
}

@end
