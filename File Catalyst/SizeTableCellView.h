//
//  SizeTableCellView.h
//  Caravelle
//
//  Created by Nuno Brum on 24/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SizeTableCellView : NSTableCellView {
    IBOutlet NSProgressIndicator *ongoing;
}

-(void) startAnimation;
-(void) stopAnimation;
@end
