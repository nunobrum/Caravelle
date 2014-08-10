//
//  PathControlManager.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 09/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "PathControlManager.h"

@implementation PathControlManager

-(void) setRootPath:(NSString*) rootPath Catalyst:(BOOL) catalystMode {
    _rootPath = rootPath;
    if (catalystMode)
        _rootLevel = [[rootPath pathComponents] count];
    else
        _rootLevel = 0;

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
    for (NSString *dirname in pathComponents) {
        rng.length++;
        if (rng.length < _rootLevel) {
            continue;
        }
        else if (rng.length == _rootLevel) {
            cell = [[NSPathComponentCell new] initTextCell:_rootPath];
        }
        else {
            cell = [[NSPathComponentCell new] initTextCell:dirname];
        }
        NSURL *newURL = [NSURL fileURLWithPathComponents: [pathComponents subarrayWithRange:rng]];
        NSImage *icon =[[NSWorkspace sharedWorkspace] iconForFile:[newURL path]];
        [icon setSize:iconSize];
        [cell setURL:newURL];
        [cell setImage:icon];

        [pathComponentCells addObject:cell];
    }
    [self setPathComponentCells:pathComponentCells];
    //[super setURL:aURL];

}
-(NSURL*) URL {
    NSPathComponentCell *pathCell = [[self pathComponentCells] lastObject];
    return [pathCell URL];
}

@end
