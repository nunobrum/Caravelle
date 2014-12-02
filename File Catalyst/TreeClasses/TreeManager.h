//
//  TreeManager.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 26/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"
#import "FileSystemMonitoring.h"

extern NSString *notificationRefreshViews;

@interface TreeManager : NSObject {
    NSMutableArray *iArray;
    FileSystemMonitoring *FSMonitorThread;
}

-(TreeManager*) init;

-(TreeBranch*) addTreeItemWithURL:(NSURL*)url;
-(TreeItem*) getNodeWithURL:(NSURL*)url;

-(void) addTreeBranch:(TreeBranch*)node;
-(void) removeTreeBranch:(TreeBranch*)node;

-(void) fileSystemChangePath:(NSNotification *)note;

@end
