//
//  TreeItem.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileInformation.h"


@protocol TreeProtocol <NSObject>

-(BOOL) isBranch;

@end


@interface TreeItem : NSObject {
    NSURL *_url;
}

//@property (retain) TreeItem      *parent;
//@property (retain) NSString       *name;
@property NSURL                     *url;
//@property long long               byteSize;
//@property (retain) NSDate         *dateModified;

-(TreeItem*) init;
-(TreeItem*) initWithURL:(NSURL*)url;

-(BOOL) isBranch;
-(NSString*) name;
-(NSDate*)   dateModified;
-(NSString*) path ;
-(long long) filesize ;
/*
 * File manipulation methods
 */
-(BOOL) sendToRecycleBin;
-(BOOL) eraseFile;
-(BOOL) copyFileTo:(NSString *)path;
-(BOOL) moveFileTo:(NSString *)path;
-(BOOL) openFile;


@end
