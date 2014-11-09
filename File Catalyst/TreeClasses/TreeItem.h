//
//  TreeItem.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "FileInformation.h"


typedef NS_OPTIONS(NSUInteger, TreeItemTagEnum) {
    tagTreeItemDirty   = (1UL << 0),
    tagTreeItemMarked  = (1UL << 1),
    tagTreeItemDropped = (1UL << 2),
    tagTreeItemToMove  = (1UL << 3),
    tagTreeItemUpdating= (1UL << 4),
    tagTreeItemAll     = NSUIntegerMax
};

@protocol TreeProtocol <NSObject>

-(BOOL) isBranch;

@end


@interface TreeItem : NSObject <NSPasteboardWriting, NSPasteboardReading> {
    NSURL           *_url;
    TreeItemTagEnum _tag;
    TreeItem __weak *_parent; /* Declaring the parent as weak will solve the problem of doubled linked objects */
}

@property (weak) TreeItem           *parent;
@property NSURL                     *url;

-(TreeItem*) initWithURL:(NSURL*)url parent:(id)parent;
-(TreeItem*) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent;

+(TreeItem *)treeItemForURL:(NSURL *)url parent:(id)parent;
+(TreeItem *)treeItemForMDItem:(NSMetadataItem *)mdItem parent:(id)parent;
- (TreeItem*) root;

-(NSArray *) treeComponents;
-(NSArray *) treeComponentsToParent:(id)parent;

-(BOOL) isBranch;
-(NSString*) name;
-(NSDate*)   date_modified;
-(NSString*) path ;
-(NSImage*) image;
-(long long) filesize ;
-(NSNumber*) fileSize;
-(NSString*) fileKind;

-(void) setTag:(TreeItemTagEnum)tag;
-(void) resetTag:(TreeItemTagEnum)tag;
-(TreeItemTagEnum) tag;
-(BOOL) hasTags:(TreeItemTagEnum) tag;

/*
 * File manipulation methods
 */
-(BOOL) openFile;
-(BOOL) removeItem;

/*
 * URL Comparison methods
 */

-(NSInteger) relationTo:(NSString*) otherPath;
-(BOOL) canContainURL:(NSURL*)url;
-(BOOL) containedInURL:(NSURL*) url;



@end
