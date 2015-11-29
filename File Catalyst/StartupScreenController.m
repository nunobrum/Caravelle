//
//  StartupScreenController.m
//  Caravelle
//
//  Created by Nuno on 29/07/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "StartupScreenController.h"

@interface StartupScreenController () {
    BOOL dontDisplayButton;
}

@end

@implementation StartupScreenController

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    self->dontDisplayButton = NO;
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    if (dontDisplayButton) {
        [self.chkDontShowThisAgain setHidden:YES];
        [self.window displayIfNeeded];
    }
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)close:(id)sender {
    NSInteger dontDisplayAgain = [self.chkDontShowThisAgain integerValue];
    [self.window close];
    [NSApp stopModalWithCode:dontDisplayAgain];
}

- (IBAction)launchWebsite:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.nunobrum.com/roadmap.html"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

-(void) hideDontShowThisAgainButton {
    dontDisplayButton = YES;
}

@end
