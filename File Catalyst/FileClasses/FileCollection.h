//
//  FileCollection.h
//  Caravelle

//
//  Created by Nuno Brum on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#ifndef _FileCollection_h
#define _FileCollection_h

#import "TreeItem.h"

@interface FileCollection : NSObject {
@private
    NSMutableArray *fileArray;
    NSString *rootDirectory;

}


//-(FileCollection *) init; No need to define at this moment, it is inherited from NSObject
//-(void) addFilesInDirectory:(NSString *)rootpath callback:(void (^)(NSInteger fileno))callbackhandler;

-(NSInteger) FileCount;
-(NSString*) commonPath;
-(NSMutableArray*) fileArray;

-(void) addFile: (TreeItem*) item;
-(void) addFiles: (NSArray *)otherArray;
-(void) setFiles: (NSArray *)otherArray;

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

//-(void) sortByFileSize;

@end

#endif
