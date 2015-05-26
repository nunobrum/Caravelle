//
//  TreePackage.m
//  Caravelle
//
//  Created by Viktoryia Labunets on 25/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"
#import "TreePackage.h"

@implementation TreePackage

-(ItemType) itemType {
    BOOL appsAsFolders =[[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_BROWSE_APPS];
    if (appsAsFolders) {
        return ItemTypeBranch;
    }
    else {
        return ItemTypeLeaf;
    }
}

@end
