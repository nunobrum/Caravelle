//
//  BrowserOutlineView.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 08/01/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define BROWSER_OUTLINE_VIEW_INVALIDATED_ROW -2

@interface BrowserOutlineView : NSOutlineView {
    NSInteger _rightMouseLocation;
}

@property NSInteger rightMouseLocation;

@end
