//
//  TreeManager.h
//  File Catalyst
//
//  Created by Nuno Brum on 26/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"
#import "FileSystemMonitoring.h"

extern NSString *notificationRefreshViews;


@interface TreeManager : NSObject {
    NSMutableArray *iArray;                 // Used to store the root paths
    NSMutableArray *authorizedURLs;        // Used to store the authorized URL bookmarks
    FileSystemMonitoring *FSMonitorThread;
}

-(TreeManager*) init;

-(TreeBranch*) addTreeItemWithURL:(NSURL*)url;
-(TreeItem*) getNodeWithURL:(NSURL*)url;
-(TreeItem*) getNodeWithPath:(NSString*)path;


//-(void) addTreeBranch:(TreeBranch*)node;
-(void) removeTreeBranch:(TreeBranch*)node;

-(void) fileSystemChangePath:(NSNotification *)note;

-(NSURL*) powerboxOpenFolderWithTitle:(NSString*)dialogTitle;
-(NSURL*) secScopeContainer:(NSURL*) url;
-(NSURL*) validateURSecurity:(NSURL*) url;

-(BOOL) startAccessToURL:(NSURL*)url;
-(void) stopAccesses;

@end

extern TreeManager *appTreeManager;