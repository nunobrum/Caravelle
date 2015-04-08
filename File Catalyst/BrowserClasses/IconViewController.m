//
//  IconViewController.m
//  Caravelle
//
//  Created by Nuno Brum on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "IconViewController.h"

// key values for the icon view dictionary
NSString *KEY_NAME = @"name";
NSString *KEY_ICON = @"icon";

// notification for indicating file system content has been received
//NSString *kReceivedContentNotification = @"ReceivedContentNotification";

@interface IconViewBox : NSBox
@end

@implementation IconViewBox
- (NSView *)hitTest:(NSPoint)aPoint
{
	// don't allow any mouse clicks for subviews in this NSBox
	return nil;
}
@end

@interface IconViewController ()

@property (readwrite, strong) IBOutlet NSArrayController *iconArrayController;
@property (readwrite, strong) NSMutableArray *icons;
@end


@implementation IconViewController

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{

}

-(NSView*) containerView {
    return self.collectionView;
}

-(void) refresh {
    self.icons = [self itemsToDisplay];

}

-(void) refreshKeepingSelections {
    // TODO: !!!! Keep the selections
    //Store selection
    [self refresh];
    // Reposition Selections
}

-(void) reloadItem:(id)object {
    [self refreshKeepingSelections];
}

@end
