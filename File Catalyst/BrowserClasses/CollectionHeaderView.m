//
//  CollectionHeaderView.m
//  Caravelle
//
//  Created by Nuno Brum on 28.12.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "CollectionHeaderView.h"

@implementation CollectionHeaderView

-(void) drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSColor *c = [NSColor colorWithCalibratedWhite:0.8 alpha:0.8];
    [c set];
    NSRectFillUsingOperation(dirtyRect,NSCompositeSourceOver);
}

@end
