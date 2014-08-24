//
//  TreeItem.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "FileInformation.h"


enum {
    tagTreeItemDirty = (1UL << 0),
    tagTreeItemMarked = (1UL << 1),
    tagTreeItemDropped = (1UL << 2),
    tagTreeItemToMove = (1UL << 2)
};
typedef NSUInteger TreeItemTagEnum;

@protocol TreeProtocol <NSObject>

-(BOOL) isBranch;

@end


@interface TreeItem : NSObject <NSPasteboardWriting, NSPasteboardReading> {
    NSURL *_url;
    TreeItemTagEnum _tag;
}

//@property (retain) TreeItem      *parent;
@property NSURL                     *url;
@property TreeItemTagEnum           tag;

-(TreeItem*) init;
-(TreeItem*) initWithURL:(NSURL*)url parent:(id)parent;

+ (TreeItem *)treeItemForURL:(NSURL *)url parent:(id)parent;

-(BOOL) isBranch;
-(NSString*) name;
-(NSDate*)   dateModified;
-(NSString*) path ;
-(long long) filesize ;
/*
 * File manipulation methods
 */
-(BOOL) sendToRecycleBin;
-(BOOL) eraseFile;
-(BOOL) copyFileTo:(NSString *)path;
-(BOOL) moveFileTo:(NSString *)path;
-(BOOL) openFile;


@end
