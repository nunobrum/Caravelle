//
//  FileExistsChoice.h
//  File Catalyst
//
//  Created by Nuno Brum on 16/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeItem.h"

typedef NS_ENUM(NSInteger, fileExistsQuestionResult) {
    FileExistsSkip = 1,
    FileExistsReplace,
    FileExistsRename
};

extern NSString *notificationClosedFileExistsWindow;
extern NSString *kFileExistsAnswerKey;
extern NSString *kFileExistsNewFilenameKey;

@interface FileExistsChoice : NSWindowController <NSTableViewDataSource,NSTableViewDelegate, NSTextFieldDelegate> {
    //fileExistsQuestionResult _answer;
    NSMutableArray *attributesTable;
}
@property (strong) IBOutlet NSWindow *windowOutlet;
@property (strong) IBOutlet NSTextField *tfFilename;
//@property (strong) IBOutlet NSArrayController *attributesContent;
@property (strong) IBOutlet NSTextField *tfNewFilename;
@property (strong) IBOutlet NSButton *pbReplace;
@property (strong) IBOutlet NSButton *pbSkip;
@property (strong) IBOutlet NSTableView *attributeTableView;
@property (strong) IBOutlet NSTextField *labelFilesAreTheSame;
@property (strong) IBOutlet NSTextField *labelKeep;

-(void) closeWindow;
-(void) displayWindow:(id) sender;

- (IBAction)actionOverwrite:(id)sender;
- (IBAction)actionSkip:(id)sender;

-(BOOL) makeTableWithSource:(TreeItem*)source andDestination:(TreeItem*) dest;

@end
