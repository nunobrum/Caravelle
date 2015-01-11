//
//  UserPreferencesDialog.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 27/12/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UserPreferencesDialog : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate> {
    NSArray *BaseDirectoriesArray;
}

@end
