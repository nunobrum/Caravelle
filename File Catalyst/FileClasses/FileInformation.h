//
//  FileInformation.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSValue.h>

#import "MyURL.h"
#include "MD5.h"

@interface FileInformation : MyURL {
@private
    //NSURL      *URL;
    NSString   *name;
    NSString   *path;
    NSDate     *dateModified;
    NSNumber   *fileSize;
	md5_byte_t md5_checksum[16];
    bool valid_md5;
    NSString *Type;
    FileInformation *duplicate_chain;
}


//@property long long               byteSize;
//@property NSDate *DateModified;
//@property NSNumber *Size;

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


@end
