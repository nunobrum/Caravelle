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
    DupDialogMaskTreeSelected        = 8,
    DupDialogMaskOKPressed           = 16
};

@interface DuplicateModeStartWindow : NSWindowController


@property (weak) IBOutlet NSButton *chkDontDisplayAgain;
@property (weak) IBOutlet NSSegmentedControl *segViewMode;
@property (weak) IBOutlet NSSegmentedControl *segTreeView;

@property (weak) IBOutlet NSTextField *message;
@property (readonly) NSUInteger answer;

- (IBAction)close:(id)sender;

-(void) setWarningMessage:(NSString*) message;

@end
