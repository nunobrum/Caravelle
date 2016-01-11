//
//  ExpandFolders.m
//  Caravelle
//
//  Created by Nuno on 19/07/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "ExpandFolders.h"
#import "MyDirectoryEnumerator.h"
#import "TreeBranch_TreeBranchPrivate.h"

@implementation ExpandFolders

-(NSString*) statusText {
   
    return [NSString stringWithFormat:@"Flattening...%lu files indexed ", statusCount];
}

-(void) main {
    
    NSMutableArray *undeveloppedFolders = [[NSMutableArray alloc] init];
    TreeBranch *itemToFlat = [_taskInfo objectForKey:kDFODestinationKey];
    [itemToFlat harverstUndeveloppedFolders: undeveloppedFolders];
    
    [itemToFlat willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    
    for (TreeBranch* item in undeveloppedFolders) {
        if (self.isCancelled) {
            break;
        }
        
        //NSLog(@"ExpandingFolders.main: path %@", item.path);
        MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:[item url] WithMode:BViewCatalystMode];
        
        @synchronized(item) {
            [item initChildren];
            TreeBranch *cursor = item;
            NSMutableArray *cursorComponents = [NSMutableArray arrayWithArray:[[item url] pathComponents]];
            unsigned long current_level = [cursorComponents count]-1;
            
            
            for (NSURL *theURL in dirEnumerator) {
                statusCount++;
                if (statusCount%1000==0) {
                    if (self.isCancelled) {
                        break;
                    }
                }
                BOOL ignoreURL = NO;
                NSArray *newURLComponents = [theURL pathComponents];
                unsigned long target_level = [newURLComponents count]-2;
                while (target_level < current_level) { // Needs to go back if the new URL is at a lower branch
                    cursor = (TreeBranch*) cursor.parent;
                    current_level--;
                }
                while (target_level != current_level &&
                       [cursorComponents[current_level] isEqualToString:newURLComponents[current_level]]) {
                    // Must navigate into the right folder
                    if (target_level <= current_level) { // The equality is considered because it means that the components at this level are different
                        // steps down in the tree
                        cursor = (TreeBranch*) cursor.parent;
                        current_level--;
                    }
                    else { // Needs to grow the tree
                        current_level++;
                        NSURL *pathURL = [cursor.url URLByAppendingPathComponent:newURLComponents[current_level] isDirectory:YES];
                        cursorComponents[current_level] = newURLComponents[current_level];
                        TreeItem *child = [TreeItem treeItemForURL:pathURL parent:cursor];
                        if (child!=nil) {
                            if (cursor.children==nil) {
                                [cursor initChildren];
                            }
                            [cursor.children addObject:child];
                            if ([child isFolder])
                            {
                                cursor = (TreeBranch*)child;
                                [cursor initChildren];
                            }
                            else {
                                // Will ignore this child and just addd the size to the current node
                                [dirEnumerator skipDescendents];
                                // IGNORE URL
                                ignoreURL = YES;
                            }
                        }
                        else {
                            NSAssert(NO, @"ExpandFolders.main() Couldn't create path %@ \nwhile creating %@",pathURL, theURL);
                        }
                    }
                    
                }
                if (ignoreURL==NO)  {
                    TreeItem *newObj = [TreeItem treeItemForURL:theURL parent:cursor];
                    if (newObj!=nil) {
                        if (cursor.children==nil) {
                            [cursor initChildren];
                        }
                        [cursor.children addObject:newObj];
                        // if it's a folder jump into it, so that the next URL can be directly inserted
                        if ([newObj isKindOfClass:[TreeBranch class]]) {
                            cursor = (TreeBranch*)newObj;
                            [cursor initChildren];
                            current_level++;
                            cursorComponents[current_level] = newURLComponents[current_level];
                            
                        }
                    }
                    else {
                        NSLog(@"ExpandFolders.main() - Couldn't create item %@",theURL);
                    }
                }
            }
        }
    }
    if (self.isCancelled==NO)
        [itemToFlat notifyDidChangeTreeBranchPropertyChildren];  // This will inform the observer about change
    else // only pairs with the willChangeValueForKey stated above
        [itemToFlat didChangeValueForKey:kvoTreeBranchPropertyChildren];
    
    // If not OK Will have to cancel the flat View. OK Will clear the operating status message.
    NSNumber *OK = [NSNumber numberWithBool:![self isCancelled]];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          OK, kDFOOkKey,
                          nil];
    [_taskInfo addEntriesFromDictionary:info];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationFinishedOperation object:nil userInfo:_taskInfo];
}

@end
