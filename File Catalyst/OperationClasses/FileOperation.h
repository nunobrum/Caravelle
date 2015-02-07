//
//  FileOperation.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "AppOperation.h"
#import "TreeBranch.h"

@interface FileOperation : AppOperation

@end

extern NSString *notificationFinishedFileOperation;

extern BOOL putInQueue(NSDictionary *taskInfo);

extern BOOL copyItemsToBranch(NSArray *items, TreeBranch *folder);
extern BOOL moveItemsToBranch(NSArray *items, TreeBranch *folder);
extern BOOL sendItemsToRecycleBin(NSArray *items);
extern BOOL eraseItems(NSArray *items);

extern BOOL copyItemToBranch(TreeItem *item, TreeBranch *folder, NSString *newName);
extern BOOL moveItemToBranch(TreeItem *item, TreeBranch *folder, NSString *newName);
extern BOOL sendItemToRecycleBin(TreeItem* item);
extern BOOL eraseItem(TreeItem *item);

extern BOOL copyURLToBranch(NSURL* item, TreeBranch *folder);
extern BOOL moveURLToBranch(NSURL* item, TreeBranch *folder);

extern BOOL copyURLToURL(NSURL *source, NSURL *dest);
extern BOOL moveURLToURL(NSURL *source, NSURL *dest);