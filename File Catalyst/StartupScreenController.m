//
//  StartupScreenController.m
//  Caravelle
//
//  Created by Nuno on 29/07/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "StartupScreenController.h"

@interface StartupScreenController ()

@end

@implementation StartupScreenController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)close:(id)sender {
    NSInteger dontDisplayAgain = [self.chkDontShowThisAgain integerValue];
    [self.window close];
    [NSApp stopModalWithCode:dontDisplayAgain];
}

@end
