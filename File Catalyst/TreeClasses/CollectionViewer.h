//
//  CollectionViewer.h
//  Caravelle
//
//  Created by Nuno Brum on 28.12.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataSourceProtocol.h"
#import "TreeBranch.h"
#import "TreeEnumerator.h"
#import "MySortDescriptors.h"

@interface CollectionViewer : NSObject <TreeViewerProtocol>  {
    
    // This class will enumerate all leafs and branches of the Tree
    NSInteger _currIndex;
    NSInteger _currSection;

    SortedEnumerator *se;
    NSUInteger _maxLevel;

    TreeBranch *_root;
    TreeItem *_item;
    
    NSMutableArray *_sections;
    MySortDescriptors *sort;
    NSPredicate *_filter;
    BOOL _needsRefresh;
}
-(instancetype) initWithParent:(TreeBranch *)parent depth:(NSUInteger)depth;

-(NSInteger) sectionCount;
-(TreeBranch*) sectionNumber:(NSInteger)number;
-(NSInteger) itemCountAtSection:(NSInteger)section;
-(TreeItem*) itemAtIndexPath:(NSIndexPath *)indexPath;
-(NSString*) titleForGroup:(NSInteger)section;


@end
