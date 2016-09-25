//
//  BrowserIconView.h
//  Caravelle
//
//  Created by Nuno Brum on 11/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileCollectionViewItem.h"

@interface BrowserIconView : NSCollectionView {
    FileCollectionViewItem * _lastClicked;
}

-(FileCollectionViewItem*) iconForEvent:(NSEvent*) theEvent;
-(FileCollectionViewItem*) lastClicked;

- (void)keyDown:(NSEvent *)theEvent;
//- (IBAction)mouseDown:(NSEvent *)theEvent;
//- (IBAction)rightMouseDown:(NSEvent *)theEvent;

- (void)cancelOperation:(id)sender;

-(BOOL) startEditInIcon:(FileCollectionViewItem*) icon;

@end
