//
//  CRVLFile.h
//  Caravelle
//
//  Created by Nuno on 28/05/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Definitions.h"
#import "FileUtils.h"

@interface CRVLFile : NSObject <ItemProtocol, NSPasteboardReading, NSPasteboardWriting> {
    NSURL *_url;
}

@property NSString *nameCache; // This is to lower memory allocation calls, for each name call, a new CFString was being allocated

-(instancetype) initWithURL:(NSURL*)url;
-(void) setUrl:(NSURL*)url;
-(NSURL*) url;


-(NSDate*)   date_modified;
-(NSDate*)   date_accessed;
-(NSDate*)   date_created;
-(NSString*) path ;
-(NSString*) location;
-(NSImage*) image;
-(NSNumber*) exactSize;
-(NSNumber*) allocatedSize;
-(NSNumber*) totalSize;
-(NSNumber*) totalAllocatedSize;
-(NSString*) fileKind;
-(NSString*) hint;


-(NSString*) fileOwnerName;
-(NSNumber*) fileOwnerID;
-(NSString*) fileGroupName;
-(NSNumber*) fileGroupID;
-(NSString*) filePermissions;

-(void) purgeURLCacheResources;


/*
 * File manipulation methods
 */
-(BOOL) openFile;

-(NSArray*) openWithApplications;

/*
 * URL Comparison methods
 */

-(enumPathCompare) relationToPath:(NSString*) otherPath;
-(enumPathCompare) compareTo:(CRVLFile*) otherItem;
-(BOOL) canContainPath:(NSString*)path;
-(BOOL) containedInPath: (NSString*) path;
-(BOOL) canContainURL:(NSURL*)url;
-(BOOL) containedInURL:(NSURL*) url;


-(BOOL) hasDuplicates;
-(NSNumber*) duplicateGroup;


@end
