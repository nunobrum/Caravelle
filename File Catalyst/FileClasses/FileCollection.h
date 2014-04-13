//
//  FileCollection.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#ifndef FileCatalyst1_FileCollection_h
#define FileCatalyst1_FileCollection_h

#import "FileInformation.h"

typedef struct {
    BOOL names;
    BOOL sizes;
    BOOL contents;
    BOOL dates;
    BOOL mp3_id3;
    BOOL photo_exif;
    BOOL MD5_only;
} comparison_options_t;

@interface FileCollection : NSObject {
@private
    NSMutableArray *fileArray;
    NSString *rootDirectory;

}


//-(FileCollection *) init; No need to define at this moment, it is inherited from NSObject
-(void) addFilesInDirectory:(NSString *)rootpath callback:(void (^)(NSInteger fileno))callbackhandler;

-(NSInteger) FileCount;
-(NSString*) rootPath;
-(NSMutableArray*) fileArray;

-(void) AddFileInformation: (FileInformation*) aFileInfo;
-(void) addFileByURL: (NSURL *) anURL;
-(void) addFiles: (NSMutableArray *)otherArray;

-(FileCollection*) findDuplicates: (comparison_options_t)options;

-(BOOL) isRootContainedInPath:(NSString *)otherRoot;
-(BOOL) rootContainsPath:(NSString *)otherRoot;
-(BOOL) isRootContainedIn:(FileCollection *)otherCollection;
-(BOOL) rootContains:(FileCollection *)otherCollection;

-(void) concatenateFileCollection: (FileCollection *)otherCollection;
-(void) resetDuplicateLists;
-(FileCollection*) FilesWithDuplicates;
-(void) streamFilesWithDuplicates;

-(void) sortByFileSize;

@end

#endif
