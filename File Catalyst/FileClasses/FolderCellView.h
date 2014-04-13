//
//  FolderCellView.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 3/30/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FolderCellView : NSTableCellView {
@private
IBOutlet NSTextField *subTitleTextField;
//IBOutlet ATColorView *colorView;
//IBOutlet NSProgressIndicator *progessIndicator;
//IBOutlet NSButton *removeButton;
BOOL _isSmallSize;
}

- (NSString *)Title;
- (void)setTitle:(NSString *)subTitle;
- (NSString *)subTitle;
- (void)setSubTitle:(NSString *)subTitle;

//@property(assign) ATColorView *colorView;
//@property(assign) NSProgressIndicator *progessIndicator;

- (void)layoutViewsForSmallSize:(BOOL)smallSize animated:(BOOL)animated;

@end
