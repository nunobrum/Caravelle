//
//  FileCollection.h
//  Caravelle

//
//  Created by Nuno Brum on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#ifndef _FileCollection_h
#define _FileCollection_h

#import <Foundation/Foundation.h>

@interface FileCollection : NSObject {
@private
    NSMutableArray *fileArray;
}


-(NSMutableArray*) fileArray;

-(void) addFiles: (NSArray *)otherArray;
-(void) setFiles: (NSArray *)otherArray;

-(FileCollection*) filesInPath:(NSString*) path;
//-(FileCollection*) duplicatesInPath:(NSString*) path dCounter:(NSUInteger)dCount;
//-(FileCollection*) duplicatesOfPath:(NSString*) path dCounter:(NSUInteger)dCount;
+(FileCollection*) duplicatesOfFiles:(NSArray*)fileArray dCounter:(NSUInteger)dCount;

-(void) concatenateFileCollection: (FileCollection *)otherCollection;

@end

#endif
