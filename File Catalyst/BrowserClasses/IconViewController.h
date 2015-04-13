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

@interface IconViewController : NodeViewController <NodeViewProtocol, NSCollectionViewDelegate, NSMenuDelegate>

@property (strong) IBOutlet BrowserIconView *collectionView;
@property (strong) IBOutlet NSArrayController *iconArrayController;

- (IBAction) rightClick:(id)sender;
- (IBAction) doubleClick:(id)sender;
	
@end
