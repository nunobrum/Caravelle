//
//  MainSideBarController.h
//  Caravelle
//
//  Created by Nuno on 01/02/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


#define SIDE_GROUP_FAVORITES      @"FAVS"
#define SIDE_GROUP_RECENT_USED    @"MRUS"
#define SIDE_GROUP_AUTHORIZATIONS @"AUTH"
#define SIDE_GROUP_APPINS         @"APIN"

@interface MainSideBarController : NSViewController <NSOutlineViewDelegate, NSOutlineViewDataSource, NSMenuDelegate> {
@private
    NSMutableArray *_topLevelItems;
    IBOutlet NSOutlineView *_sidebarOutlineView;
    
}

//@property (assign) IBOutlet NSWindow *window;


//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (IBAction)sidebarMenuDidChange:(id)sender;

@end
