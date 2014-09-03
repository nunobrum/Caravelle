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


extern BOOL copyItemsToBranch(NSArray *items, TreeBranch *folder);
extern BOOL moveItemsToBranch(NSArray *items, TreeBranch *folder);
extern BOOL copyItemToBranch(TreeItem *items, TreeBranch *folder);
extern BOOL moveItemToBranch(TreeItem *items, TreeBranch *folder);