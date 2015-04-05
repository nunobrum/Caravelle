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

@property (readwrite, strong) TreeBranch *currentNode;
	
@end
