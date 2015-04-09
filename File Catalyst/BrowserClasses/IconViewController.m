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



@interface IconViewController ()

@property (readwrite, strong) NSMutableArray *icons;
@end


@implementation IconViewController

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
// TODO: !!!!! Set observer for the selection of iconArrayController

    [self.iconArrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:@"Selection Changed"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectedObjects"]) {

        // TODO: !!!! replace by a Status Notfication
        [self updateFocus:self];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


-(NSView*) containerView {
    return self.collectionView;
}

-(void) refresh {
    self.icons = [self itemsToDisplay];

}

- (void) selectionChanged:(NSNotification*) note {
    [self updateFocus:self];
}

/* This action is associated manually with the doubleClickTarget in Bindings */
- (IBAction)doubleClick:(id)sender {
    //NSIndexSet *selectedIndexes = [self.iconArrayController selectionIndexes];
    //NSArray *itemsSelected = [self.icons objectsAtIndexes:selectedIndexes];
    NSArray *itemsSelected = [self.iconArrayController selectedObjects];
    [self orderOperation:opOpenOperation onItems:itemsSelected];
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
