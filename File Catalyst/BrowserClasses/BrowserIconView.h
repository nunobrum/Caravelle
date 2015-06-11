//
//  BrowserIconView.h
//  Caravelle
//
//  Created by Nuno Brum on 11/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IconViewBox.h"

@interface BrowserIconView : NSCollectionView {
    IconViewBox * _lastClick;
}

-(IconViewBox*) iconForEvent:(NSEvent*) theEvent;
-(IconViewBox*) lastClick;

- (void)keyDown:(NSEvent *)theEvent;
- (IBAction)mouseDown:(NSEvent *)theEvent;
- (IBAction)rightMouseDown:(NSEvent *)theEvent;

-(IconViewBox*) iconWithItem:(id) item;
- (void)cancelOperation:(id)sender;
@end
