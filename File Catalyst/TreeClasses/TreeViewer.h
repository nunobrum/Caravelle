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

@interface TreeViewer : NSObject <TreeViewerProtocol>  {
    
    // This class will enumerate all leafs and branches of the Tree
    NSRange _currRange;
    NSInteger _currSection;
    NSInteger _currIndex;
    
    FilterEnumerator *se;
    NSUInteger _maxLevel;
    
    TreeBranch *_root;
    TreeItem *_item;
    
    NSMutableArray *_sections;
    NSMutableIndexSet *_sectionIndexes;
    MySortDescriptors *sort;
    NSPredicate *_filter;
    BOOL _needsRefresh;
}
-(instancetype) initWithParent:(TreeBranch *)parent depth:(NSUInteger)depth;

-(NSUInteger) count;
-(TreeItem*) itemAtIndex:(NSUInteger)index;
-(TreeItem*) nextObject;

-(BOOL) isGroup:(NSUInteger)index;
-(NSString*) groupTitle;


@end
