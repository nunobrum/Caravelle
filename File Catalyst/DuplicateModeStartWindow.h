//
//  DuplicateModeStartWindow.h
//  Caravelle
//
//  Created by Nuno on 29/07/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_OPTIONS(NSUInteger, EnumDupStartDialogAnswer) {
    DupDialogMaskChkDontDisplayAgain = 1,
    DupDialogMaskClassicView         = 2,
    DupDialogMaskCaravelleView       = 4,
    DupDialogMaskOKPressed           = 8
};

@interface DuplicateModeStartWindow : NSWindowController

@property (weak) IBOutlet NSImageView *exampleImage;
@property (weak) IBOutlet NSButton *chkDontDisplayAgain;
@property (weak) IBOutlet NSMatrix *duplicateOrganization;
@property (weak) IBOutlet NSTextField *message;
@property (readonly) NSUInteger answer;

- (IBAction)organizationChanged:(id)sender;

- (IBAction)close:(id)sender;

@end
