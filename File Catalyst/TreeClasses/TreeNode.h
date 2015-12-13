//
//  TreeNode.h
//  Caravelle
//
//  Created by Nuno Brum on 12/06/15.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "BrowserProtocol.h"


@interface TreeNode : NSMutableArray <BrowserProtocol> {
}




-(NSEnumerator*) itemsInNodeEnumerator;

-(BrowserItemPointer) childWithName:(NSString*) name class:(id)cls;
-(BOOL) replaceItem:(BrowserItemPointer)original with:(BrowserItemPointer)replacement;
-(BOOL) removeItemAtIndex:(NSUInteger)index;



// Private Method
//-(void) _harvestItemsInBranch:(NSMutableArray*)collector;

/*
 * Item Manipulation methods
 */

//-(BOOL) addChild:(BrowserItemPointer)item;
//-(BOOL) removeChild:(BrowserItemPointer)item;
//-(BOOL) moveChild:(BrowserItemPointer)item;

-(void) releaseChildren;

/*
 * Tag manipulation
 */
//-(void) setTagsInNode:(attrViewTagEnum)tags;
//-(void) setTagsInBranch:(attrViewTagEnum)tags;
//-(void) resetTagsInNode:(attrViewTagEnum)tags;
//-(void) resetTagsInBranch:(attrViewTagEnum)tags;
//-(void) performSelector:(SEL)selector inTreeItemsWithTag:(attrViewTagEnum)tags;
//-(void) performSelector:(SEL)selector withObject:(id)param inTreeItemsWithTag:(attrViewTagEnum)tags;
//-(void) purgeDirtyItems;
@end


@interface ItemEnumerator : NSEnumerator {
    NSUInteger index;
    TreeNode *parent;
}
    
-(instancetype) initWithParent:(TreeNode*)parent;

@end
