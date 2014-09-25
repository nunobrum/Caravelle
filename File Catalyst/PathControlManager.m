//
//  PathControlManager.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 09/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "Definitions.h"
#import "PathControlManager.h"
#import "FileUtils.h"

@implementation PathControlManager {
    NSPopUpButton *_popButton;
    NSPathControl *_pathBar;
}

-(PathControlManager*) initWithBar:(NSPathControl*)pathBar andButton:(NSPopUpButton*)popButton {
    _popButton = popButton;
    _pathBar = pathBar;
    return self;
}

-(void) setRootPath:(NSURL*) rootPath {
    _rootPath = [rootPath path];
    _rootLevel = [[rootPath pathComponents] count];
}

-(void) setURL:(NSURL*)aURL {
    NSMutableArray *pathComponentCells = [NSMutableArray array];
    NSArray *pathComponents = [aURL pathComponents];
    NSPathComponentCell *cell;
    NSRange rng;
    NSSize iconSize = {12,12};
    iconSize.height =12;
    iconSize.width = 12;
    rng.location=0;
    rng.length = 0;

    NSURL *rootURL = [NSURL fileURLWithPathComponents:pathComponents[0]];
    NSDictionary *diskInfo = getDiskInformation(rootURL);
    NSString *volumeName = diskInfo[@"DAVolumeName"];

    for (NSString *dirname in pathComponents) {
        rng.length++;
        if (rng.length < _rootLevel) {
            continue;
        }
//        else if (rng.length == _rootLevel) {
//            cell = [[NSPathComponentCell new] initTextCell:[NSString stringWithFormat:@"%@/%@",volumeName, _rootPath]];
//        }
        else {
            if (rng.length==1) {
                cell = [[NSPathComponentCell new] initTextCell:volumeName];
            }
            else {
                cell = [[NSPathComponentCell new] initTextCell:dirname];
            }
        }
        NSURL *newURL = [NSURL fileURLWithPathComponents: [pathComponents subarrayWithRange:rng]];
        NSImage *icon =[[NSWorkspace sharedWorkspace] iconForFile:[newURL path]];
        [icon setSize:iconSize];
        [cell setURL:newURL];
        [cell setImage:icon];

        [pathComponentCells addObject:cell];
    }
    [_pathBar setPathComponentCells:pathComponentCells];
    //[super setURL:aURL];

}
-(NSURL*) URL {
    NSPathComponentCell *pathCell = [[_pathBar pathComponentCells] lastObject];
    return [pathCell URL];
}

@end
