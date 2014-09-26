//
//  TreeManager.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 26/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"

@interface TreeManager : NSMutableArray

-(TreeBranch*) addTreeBranch:(NSURL*)url;
-(void) removeTree:(TreeBranch*)node;
-(TreeItem*) getItemWithURL:(NSURL*)url;

@end
