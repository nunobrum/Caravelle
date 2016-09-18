//
//  FolderCellView.m
//  Caravelle
//
//  Created by Nuno Brum on 3/30/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "FolderCellView.h"
#import "Definitions.h"

@implementation FolderCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        /* Sign for receiving drops of files */
    }
    
    return self;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

- (NSString *)Title {
    return [[self textField ] stringValue];
}

- (void)setTitle:(NSString *)subTitle {
    [[self textField] setStringValue: subTitle];
}

- (NSString *)subTitle {
    return [subTitleTextField stringValue];
}

- (void)setSubTitle:(NSString *)subTitle {
    [subTitleTextField setStringValue: subTitle];
}


@end
