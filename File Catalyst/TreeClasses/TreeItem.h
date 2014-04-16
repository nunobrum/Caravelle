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


@interface TreeItem : NSObject

@property (retain) TreeItem      *parent;
//@property (retain) NSString       *name;
@property NSURL                   *theURL;
@property long long               byteSize;
//@property (retain) NSDate         *dateModified;

-(TreeItem*) init;
-(BOOL) isBranch;
-(NSString*) name;
-(NSDate*)   dateModified;
-(NSString*) path ;
-(NSNumber*) filesize ;


@end
