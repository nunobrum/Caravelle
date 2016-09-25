//
//  FileTextField.m
//  Caravelle
//
//  Created by Nuno Brum on 25/09/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "FileTextField.h"

@implementation FileTextField

//- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
//    
//    // Drawing code here.
//}

- (void)mouseDown:(NSEvent *)event {
    // This is needed to force the textField to have similar operation as the image.
    // Clicking in it will select the view.
    // The start of edit mode is always started by the CollectionView so that proper text
    // Selection is done.
    [self.superview mouseDown:event];
}

@end
