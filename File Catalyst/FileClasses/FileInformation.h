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

@interface FileInformation : NSObject { // TODO:? To Consider : Derive this class directly from NSURL : Memory footprint improvement ??????? Another idea is to merge this class with the TreeItem. Use a Dictionary to hold the key information.
@private
    //NSURL      *URL;
    NSString   *name;
    NSString   *path;
    NSDate     *dateModified;
    NSNumber   *fileSize;
	md5_byte_t md5_checksum[16];
    bool valid_md5;
    NSString *Type;
@public
    FileInformation *duplicate_chain;
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

+(FileInformation *) createWithURL: (NSURL*) theURL;
-(FileInformation *) init;
-(void) calculateMD5;
//-(BOOL) validMD5;

-(BOOL) compareMD5checksum: (FileInformation *)otherFile;
-(BOOL) compareContents:(FileInformation*)otherFile;
-(BOOL) equalName:(FileInformation *)otherFile;
-(BOOL) equalSize:(FileInformation *)otherFile;
-(BOOL) equalDate:(FileInformation *)otherFile;

-(NSComparisonResult) compareSize:(FileInformation *)otherFile;

-(void) addDuplicate:(FileInformation*)duplicateFile;
-(BOOL) hasDuplicates;
-(NSUInteger) duplicateCount;
-(NSMutableArray*) duplicateList;
-(void) resetDuplicates;

// File Operations
-(BOOL) sendToRecycleBin;
-(BOOL) eraseFile;
-(BOOL) copyFileTo:(NSString *)path;
-(BOOL) moveFileTo:(NSString *)path;
-(BOOL) openFile;

@end
