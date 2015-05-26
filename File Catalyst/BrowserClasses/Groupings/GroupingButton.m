//
//  GroupingButton.m
//  Caravelle
//
//  Created by Viktoryia Labunets on 26/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "GroupingButton.h"
#include "Definitions.h"
#import "CustomTableHeaderView.h"

@implementation GroupingButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    self.groupingMenu = nil;
    // Drawing code here.

}

- (IBAction)mouseDown:(NSEvent *)theEvent {
    if (self.groupingMenu==nil) {
        self.groupingMenu = [[NSMenu alloc] initWithTitle:@"Groupings Menu"];
        [self.groupingMenu setDelegate:self];
        NSMenuItem *groupingTitle = [[NSMenuItem alloc] init];
        [groupingTitle setImage:[NSImage imageNamed:@"GrouppingOSX"]];
        [groupingTitle setTitle:@""];
        [self.groupingMenu addItem:groupingTitle];

        for (NSString *colID in sortedColumnNames() ) {
            NSDictionary *colInfo = [columnInfo() objectForKey:colID];
            NSString *menuTitle = [colInfo objectForKey:COL_TITLE_KEY];
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle action:@selector(teste:) keyEquivalent:@""];
            [menuItem setEnabled:YES];
            [menuItem setState:NSOffState];
            [self.groupingMenu addItem:menuItem];
        }
        [self setMenu:self.groupingMenu];
    }
    [super mouseDown:theEvent];
}


-(void) teste:(id) sender {
    NSLog(@"1");
}

@end
