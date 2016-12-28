//
//  CollectionViewer.h
//  Caravelle
//
//  Created by Nuno Brum on 28.12.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"
#import "TreeEnumerator.h"

@interface CollectionViewer : NSObject  {
    
    // This class will enumerate all leafs and branches of the Tree
    NSInteger _currIndex;
    NSInteger _currSection;

    SortedEnumerator *se;
    NSUInteger _maxLevel;

    TreeBranch *_root;
    TreeItem *_item;
    
    NSMutableArray *_sections;
    NSSortDescriptor *sort;
}

-(NSInteger) sectionCount;
-(TreeBranch*) sectionNumber:(NSInteger)number;


@end
