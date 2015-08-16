//
//  StartupScreenController.h
//  Caravelle
//
//  Created by Nuno on 29/07/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StartupScreenController : NSWindowController

@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *chkDontShowThisAgain;

- (instancetype)initWithWindowNibName:(NSString *)windowNibName;

-(void) hideDontShowThisAgainButton;

@end
