//
//  IconViewController.h
//  Caravelle
//
//  Created by Nuno Brum on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NodeViewController.h"

// notification for indicating file system content has been received
//extern NSString *kReceivedContentNotification;

@interface IconViewController : NodeViewController <NodeViewProtocol>

@property (strong) IBOutlet NSCollectionView *collectionView;
@property (strong) IBOutlet NSArrayController *iconArrayController;

@property (readwrite, strong) TreeBranch *currentNode;

- (IBAction)doubleClick:(id)sender;
	
@end
