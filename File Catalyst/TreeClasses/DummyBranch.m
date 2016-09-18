//
//  DummyBranch.m
//  Caravelle
//
//  Created by Nuno on 08/08/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "DummyBranch.h"
#import "TreeManager.h"
#import "TreeBranchCatalyst.h"

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
    // Will block any Catalyst Folder
    if ([item isKindOfClass:[TreeBranchCatalyst class]])
        return nil;
    NSURL *url;
    TreeItem *target;
    if (item->_parent) {
        target = item->_parent;
        url = getURL(item->_parent);
        if (url==nil) {
            return nil;
        }
    }
    else {
        url = getURL(item);
        if (url==nil) {
            return nil;
        }
        if ([[url pathComponents] count]==1) {
            return nil;
        }
        url = [url URLByDeletingLastPathComponent];
        target = [appTreeManager addTreeItemWithURL:url askIfNeeded:NO];
    }
    
    DummyBranch *answer = [[DummyBranch alloc] initWithURL:url parent:nil];
    if (target) {
        answer.target = target;
    }
    //else
    //    NSLog(@"DummyBranch.parentFor: couldnt find the target %@", url);
    [answer setName:@".."];
    return answer;
}

-(NSArray *) treeComponents {
    if (self.target != nil)
        return [self.target treeComponents];
    else
        return nil;
}

-(NSArray *) treeComponentsToParent:(id)parent {
    if (self.target != nil)
        return [self.target treeComponentsToParent:parent];
    else
        return nil;
}

-(TreeItemTagEnum) tag {
    return self.target.tag | tagTreeItemReadOnly;
}

-(BOOL) hasTags:(TreeItemTagEnum) tag {
    return ((self.target.tag  | tagTreeItemReadOnly) & tag)!=0 ? YES : NO;
}

// The following method assures that nothing is done in the dummy class.
// The super class has an implementation on newName that is used to rename or create files.
-(NSString*) name {
    if (self.nameCache==nil) {
        return self.target.name;
    }
    return self.nameCache;
}
-(void) setName:(NSString*)newName {
    self.nameCache = newName;
}

-(BOOL) needsSizeCalculation {
    // Never compute the size of a dummy directory
    return NO;
}
// TODO:1.3 Add a badge to the dummy icon. Actually need to understand what happened with XCODE 7.2. Icons seem to already come with a badge.

-(BOOL) canAndNeedsFlat {
    return NO;
}

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
        //NSLog(@"DummyBranch.valueForKey:%@  NO target", key);
        return [super valueForKey:key];
    }
}

@end
