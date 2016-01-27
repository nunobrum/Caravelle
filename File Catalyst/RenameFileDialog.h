//
//  RenameFileDialog.h
//  File Catalyst
//
//  Created by Nuno Brum on 13/01/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RenameFileDialog : NSWindowController {
    id targetObject;
    NSString *oldFilename;
}



@property (strong) IBOutlet NSTextField *ebFilename;


- (IBAction) RenameAction:(id) sender;
- (IBAction) RenameCancel:(id) sender;

-(void) setRenamingFile:(NSString *)filename;
-(NSString*) getRenameFile;

@end
