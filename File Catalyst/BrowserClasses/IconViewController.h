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
@property (weak) IBOutlet NSSlider *iconSizeSlider;


- (IBAction) lastClick:(id)sender;
- (IBAction) lastRightClick:(id)sender;
- (IBAction) doubleClick:(id)sender;
- (IBAction) sliderChange:(id)sender;

@end
