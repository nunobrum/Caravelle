//
//  SizeTableCellView.m
//  Caravelle
//
//  Created by Nuno Brum on 24/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "SizeTableCellView.h"

@implementation SizeTableCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void) startAnimation {
    [self->ongoing startAnimation:self];
}
-(void) stopAnimation {
    [self->ongoing stopAnimation:self];

}
@end
