//
//  BrowserTableView.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 08/01/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define BROWSER_TABLE_VIEW_INVALIDATED_ROW -2

@interface BrowserTableView : NSTableView {
    NSInteger _rightMouseLocation;
}

@property NSInteger rightMouseLocation;

@end
