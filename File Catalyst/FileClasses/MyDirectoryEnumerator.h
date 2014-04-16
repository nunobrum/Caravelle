//
//  MyDirectoryEnumerator.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 15/04/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TreeItem.h"

@interface MyDirectoryEnumerator : NSDirectoryEnumerator

-(MyDirectoryEnumerator *) init:(NSURL*)directoryToScan WithMode:(BOOL) catalystMode;

@end
