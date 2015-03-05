//
//  FileCollection.h
//  Magellan

//
//  Created by Nuno Brum on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#ifndef FileCatalyst1_FileCollection_h
#define FileCatalyst1_FileCollection_h

#import "Definitions.h"
#import "FileInformation.h"

@interface FileCollection : NSObject {
@private
    NSMutableArray *fileArray;
    NSString *rootDirectory;

}


//-(FileCollection *) init; No need to define at this moment, it is inherited from NSObject
-(void) addFilesInDirectory:(NSString *)rootpath callback:(void (^)(NSInteger fileno))callbackhandler;

-(NSInteger) FileCount;
-(NSString*) commonPath;
-(NSMutableArray*) fileArray;

-(void) AddFileInformation: (FileInformation*) aFileInfo;
-(void) addFileByURL: (NSURL *) anURL;
-(void) addFiles: (NSMutableArray *)otherArray;

-(FileCollection*) filesInPath:(NSString*) path;
-(FileCollection*) duplicatesInPath:(NSString*) path dCounter:(NSUInteger)dCount;

/*-(BOOL) isRootContainedInPath:(NSString *)otherRoot;
-(BOOL) rootContainsPath:(NSString *)otherRoot;
-(BOOL) isRootContainedIn:(FileCollection *)otherCollection;
-(BOOL) rootContains:(FileCollection *)otherCollection;
*/
-(void) concatenateFileCollection: (FileCollection *)otherCollection;
-(void) resetDuplicateLists;
-(FileCollection*) FilesWithDuplicates;
-(void) streamFilesWithDuplicates;

-(void) sortByFileSize;

@end

#endif
