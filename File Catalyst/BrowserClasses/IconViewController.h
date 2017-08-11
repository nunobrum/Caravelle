//
//  IconViewController.h
//  Caravelle
//
//  Created by Nuno Brum on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NodeViewController.h"
#import "BrowserIconView.h"

// notification for indicating file system content has been received
//extern NSString *kReceivedContentNotification;

@interface IconViewController : NodeViewController <NodeViewProtocol, NSCollectionViewDelegate, NSMenuDelegate, NSCollectionViewDataSource>

@property (strong) IBOutlet BrowserIconView *collectionView;

@property (weak) IBOutlet NSProgressIndicator *myProgressIndicator;

@property (strong) IBOutlet NSLayoutConstraint *viewWidthConstraint;

// Binded to the slider in the icon View
@property (weak) IBOutlet NSSlider *imageSizeSlider;


- (IBAction) lastClick:(id)sender;
- (IBAction) lastRightClick:(id)sender;
- (IBAction) doubleClick:(id)sender;
- (IBAction) sizeChange:(id)sender;


// Used to transmit the information that the content was resized. The controller needs to know this to adjust controls.
-(void) subviewResized:(id)sender;

@end
