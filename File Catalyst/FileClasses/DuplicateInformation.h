//
//  FileInformation.h
//  FileCatalyst1
//
//  Created by Nuno Brum on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSValue.h>

#include "MD5.h"

@interface DuplicateInformation : NSObject { // TODO: To Consider : Derive this class directly from NSURL : Memory footprint improvement ? Another idea is to merge this class with the TreeItem. Use a Dictionary to hold the key information.
@private
    id __weak  treeItem; // Doesn't hold the target if it is released. TODO:!!! See if this can be deleted at the end.
    NSURL      *url;
    NSString   *name;
    NSDate     *dateModified;
    NSNumber   *fileSize;
	md5_byte_t md5_checksum[16];
    bool valid_md5;
    NSString *Type;
@public
    DuplicateInformation *duplicate_chain;
    NSUInteger dCounter;
}


//@property long long               byteSize;
//@property NSDate *DateModified;
//@property NSNumber *Size;

-(void)      setURL:(NSURL*)theURL;
-(NSURL*)    getURL;
-(NSString*) getName;
-(NSString*) getPath;
-(NSArray*)  getPathComponents;
-(NSDate*)   getDateModified;
-(NSNumber*) getFileSize;
-(NSData*)   getMD5;

+(DuplicateInformation*) createWithURL: (NSURL*) theURL;
-(DuplicateInformation *) init;
-(void) calculateMD5;
//-(BOOL) validMD5;

-(BOOL) compareMD5checksum: (DuplicateInformation *)otherFile;
-(BOOL) compareContents:(DuplicateInformation*)otherFile;
-(BOOL) equalName:(DuplicateInformation *)otherFile;
-(BOOL) equalSize:(DuplicateInformation *)otherFile;
-(BOOL) equalDate:(DuplicateInformation *)otherFile;

-(NSComparisonResult) compareSize:(DuplicateInformation *)otherFile;

-(void) addDuplicate:(DuplicateInformation*)duplicateFile;
-(BOOL) hasDuplicates;
-(NSUInteger) duplicateCount;
-(NSMutableArray*) duplicateList;
-(void) resetDuplicates;

// File Operations
/*-(BOOL) sendToRecycleBin;
-(BOOL) eraseFile;
-(BOOL) copyFileTo:(NSString *)path;
-(BOOL) moveFileTo:(NSString *)path;
-(BOOL) openFile;
*/
@end
