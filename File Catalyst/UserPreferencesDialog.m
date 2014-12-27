//
//  UserPreferencesDialog.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 27/12/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "UserPreferencesDialog.h"

@interface UserPreferencesDialog ()

@end

@implementation UserPreferencesDialog

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [_preferencesDirectory addChild:[NSDictionary dictionaryWithObjectsAndKeys: @"Teste", @"titleKey", nil]];
    [_preferencesDirectory commitEditing];
}

-(void) setAutomaticallyPrepareContents {
    // TODO:!!! All initiatlization of the Tree Controller are done here.
    NSLog(@"setAutomaticallyPrepareContents");
}

@end
