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

@protocol PathObserverProtocol <NSObject>

-(void) pathHasChanged:(NSString*)path;

@end


@interface TreeManager : NSObject {
    NSMutableArray <TreeBranch*> *iArray;  // Used to store the root paths
    NSMutableArray *authorizedURLs;        // Used to store the authorized URL bookmarks
    FileSystemMonitoring *FSMonitorThread;
}

-(TreeManager*) init;

-(TreeBranch*) addTreeItemWithURL:(NSURL*)url askIfNeeded:(BOOL)askIfNeeded;
-(TreeItem*) getNodeWithURL:(NSURL*)url;
-(TreeItem*) getNodeWithPath:(NSString*)path;

-(void) fileSystemChangePath:(NSNotification *)note;

-(NSURL*) powerboxOpenFolderWithTitle:(NSString*)dialogTitle;
-(NSURL*) secScopeContainer:(NSURL*) url;
-(NSURL*) validateURSecurity:(NSURL*) url;

-(void) stopAccesses;

-(void) removeAuthorization:(NSString*) path;

-(void) addActivityObserver:(NSObject<PathObserverProtocol>*)obj path:(NSString*)path;
-(void) removeActivityObserver:(id)obj;

@end

extern TreeManager *appTreeManager;
