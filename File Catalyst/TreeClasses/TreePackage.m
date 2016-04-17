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

#pragma mark - Menu support
-(BOOL) respondsToMenuTag:(EnumContextualMenuItemTags)tag {
    BOOL answer;
    switch (tag) {
            // Enables these ones
//        case menuViewPackage:
//            answer = YES;
//            break;
            
            // Invalidates these ones
        case menuAddFavorite:
        case menuView:
            answer = NO;
            break;
            
        default:
            answer = [super respondsToMenuTag:tag];
            break;
    }
    
    return answer;
}


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
