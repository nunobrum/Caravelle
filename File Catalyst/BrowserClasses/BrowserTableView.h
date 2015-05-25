//
//  BrowserTableView.h
//  File Catalyst
//
//  Created by Nuno Brum on 08/01/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define COL_FILENAME @"COL_NAME"
#define COL_TEXT_ONLY @"COL_TEXT"
#define COL_SIZE      @"COL_SIZE"
#define ROW_GROUP @"GROUP"

#define GROUP_SORT_ASCENDING  0
#define GROUP_SORT_DESCENDING 1
#define GROUP_SORT_REMOVE     2

@interface BrowserTableView : NSTableView {
    //NSInteger _rightMouseLocation;
}

@property NSInteger rightClickedRow;
//
//- (void)interpretKeyEvents:(NSArray *)eventArray;
//
//- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
//
//- (void)flagsChanged:(NSEvent *)theEvent;
//
- (void)cancelOperation:(id)sender;
//- (void)insertNewline:(id)sender;
//- (void)moveLeft:(id)sender;



@end
