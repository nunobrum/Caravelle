//
//  DuplicateModeStartWindow.m
//  Caravelle
//
//  Created by Nuno on 29/07/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "DuplicateModeStartWindow.h"

@interface DuplicateModeStartWindow ()

@end

@implementation DuplicateModeStartWindow

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self->_answer = 0;
}


- (IBAction)close:(id)sender {
    self->_answer = DupDialogMaskOKPressed;
    
    if ([self.chkDontDisplayAgain integerValue] != 0)
        self->_answer |= DupDialogMaskChkDontDisplayAgain;
    
    if ([self.duplicateOrganization selectedColumn]==0)
        self->_answer |= DupDialogMaskClassicView;
    else
        self->_answer |= DupDialogMaskCaravelleView;
    
    
    if (self.window.isModalPanel)
        [NSApp stopModal];
    
    [self.window close];
}

-(void) setWarningMessage:(NSString *)message {
    if (message != nil && [message isEqualToString:@""] == NO) {
        [self.message setStringValue:message];
        [self.message setHidden:NO];
    }
    else
        [self.message setHidden:YES];
}

@end
