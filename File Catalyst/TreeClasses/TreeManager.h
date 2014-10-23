//
//  TreeManager.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 26/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"

@interface TreeManager : NSObject {
    NSMutableArray *iArray;
}

-(TreeManager*) init;

-(TreeBranch*) addTreeBranchWithURL:(NSURL*)url;
-(TreeItem*) getNodeWithURL:(NSURL*)url;

-(void) addTreeBranch:(TreeBranch*)node;
-(void) removeTreeBranch:(TreeBranch*)node;


@end
