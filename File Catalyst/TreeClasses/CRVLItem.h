//
//  CRVLItem.h
//  Caravelle
//
//  Created by Nuno Brum on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Definitions.h"
#import "FileUtils.h"
#import "BrowserProtocol.h"

extern const NSString *keyDuplicateInfo;

typedef NS_ENUM(NSInteger, ItemType) {
    ItemTypeNone = 0,
    ItemTypeBranch,
    ItemTypeFilter,
    ItemTypeDummyBranch, // All items below this one are considered for size calculations (this one excluded)
    //===================== Below this value there are only folders
    ItemTypeLeaf = 10, // All types of files will be above this number
    ItemTypeAudio = 100,
    ItemTypeImage = 200,
    ItemTypeVideo = 300
};



@interface CRVLItem : NSObject <NSPasteboardWriting, NSPasteboardReading, BrowserProtocol> {
    NSURL           *_url;
    attrViewTagEnum _tag;
    CRVLItem __weak *_parent; /* Declaring the parent as weak will solve the problem of doubled linked objects */
}

@property (weak) CRVLItem           *parent;
@property NSString *nameCache; // This is to lower memory allocation calls, for each name call, a new CFString was being allocated

-(instancetype) initWithURL:(NSURL*)url parent:(id)parent;
-(instancetype) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent;

-(void) purgeURLCacheResources;

-(void) updateFileTags;

+(id)CRVLItemForURL:(NSURL *)url parent:(id)parent;
+(id)CRVLItemForMDItem:(NSMetadataItem *)mdItem parent:(id)parent;
- (instancetype) root;

-(void) notifyChange;

-(NSArray *) treeComponents;
-(NSArray *) treeComponentsToParent:(id)parent;

-(BOOL)      isLeaf;
-(ItemType)  itemType;
-(NSDate*)   date_modified;
-(NSDate*)   date_accessed;
-(NSDate*)   date_created;
-(NSString*) path ;
-(NSString*) location;
-(NSNumber*) exactSize;
-(NSNumber*) allocatedSize;
-(NSNumber*) totalSize;
-(NSNumber*) totalAllocatedSize;
-(NSString*) fileKind;


-(void) setUrl:(NSURL*)url;
-(NSURL*) url;

/*
 * File manipulation methods
 */
-(BOOL) openFile;
-(BOOL) removeItem;

/*
 * URL Comparison methods
 */

-(enumPathCompare) relationToPath:(NSString*) otherPath;
-(enumPathCompare) compareTo:(CRVLItem*) otherItem;
-(BOOL) canContainPath:(NSString*)path;
-(BOOL) containedInPath: (NSString*) path;
-(BOOL) canContainURL:(NSURL*)url;
-(BOOL) containedInURL:(NSURL*) url;

/*
 * Coding Compliant methods
 */
-(void) setValue:(id)value forUndefinedKey:(NSString *)key;

-(BOOL) hasDuplicates;
-(NSNumber*) duplicateGroup;

/*
 * Debug
 */

-(NSString*) debugDescription;


@end
