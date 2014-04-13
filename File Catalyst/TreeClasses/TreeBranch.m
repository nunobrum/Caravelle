//
//  TreeBranch.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"
#import "TreeLeaf.h"

@interface TreeBranch( PrivateMethods )

-(void) _harvestItemsInBranch:(NSMutableArray*)collector;
-(void) _harvestLeafsInBranch:(NSMutableArray*)collector;

@end

@implementation TreeBranch

-(BOOL) isBranch {
    return YES;
}

-(TreeBranch*) init {
    self = [super init];
    self->_children = nil;
    return self;
}

-(void) removeBranch {
    for (TreeItem *item in _children) {
        if ([item isBranch])
            [(TreeBranch*)item removeBranch];
    }
    [[self children] removeAllObjects];
    [self setDateModified:nil];
    [self setByteSize:0];
}

-(NSInteger) numberOfLeafsInNode {
    NSInteger total=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            total++;
        }
    }
    return total;
}

-(NSInteger) numberOfBranchesInNode {
    NSInteger total=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            total++;
        }
    }
    return total;
}

-(NSInteger) numberOfItemsInNode {
    return [_children count];
}

// This returns the number of leafs in a branch
// this function is recursive to all sub branches
-(NSInteger) numberOfLeafsInBranch {
    NSInteger total=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            total += [(TreeBranch*)item numberOfLeafsInBranch];
        }
        else
            total++;
    }
    return total;
}

-(NSString*) path {
    NSString *answer=nil;
    if (self.parent==nil) {
        answer = [NSString stringWithString: self.name];
    }
    else if ([self.parent isKindOfClass:[TreeBranch class]])
    {
        answer = [(TreeBranch*)self.parent path];
        answer = [answer stringByAppendingPathComponent:self.name];
    }
    else
        NSAssert(NO,@"Ooops. This is not supposed to happen");
    return answer;
}

-(NSInteger) numberOfFileDuplicatesInBranch {
    NSInteger total = 0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            total += [(TreeBranch*)item numberOfFileDuplicatesInBranch];
        }
        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            if ([[(TreeLeaf*)item getFileInformation] duplicateCount]!=0)
                total++;
        }
    }
    return total;
}


-(TreeBranch*) branchAtIndex:(NSUInteger) index {
    NSInteger i=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            if (i==index)
                return (TreeBranch*)item;
            i++;
        }
    }
    return nil;
}

-(TreeLeaf*) leafAtIndex:(NSUInteger) index {
    NSInteger i=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            if (i==index)
                return (TreeLeaf*)item;
            i++;
        }
    }
    return nil;
}



-(FileCollection*) filesInNode {
    FileCollection *answer = [[FileCollection new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [answer AddFileInformation:[(TreeLeaf*)item getFileInformation]];
        }
    }
    
    return answer; 
}
-(FileCollection*) filesInBranch {
    return nil; // Pending Implementation
}
-(NSMutableArray*) itemsInNode {
    return self->_children;
}

-(void) _harvestItemsInBranch:(NSMutableArray*)collector {
    [collector addObjectsFromArray: _children];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            [(TreeBranch*)item _harvestItemsInBranch: collector];
        }
    }
}
-(NSMutableArray*) itemsInBranch {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self _harvestItemsInBranch:answer];
    return answer; // Pending Implementation
}

-(NSMutableArray*) leafsInNode {
    NSMutableArray *answer = [[NSMutableArray new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [answer addObject:item];
        }
    }
    return answer;
}

-(void) _harvestLeafsInBranch:(NSMutableArray*)collector {
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            [(TreeBranch*)item _harvestLeafsInBranch: collector];
        }
        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [collector addObject:item];
        }
    }
}
-(NSMutableArray*) leafsInBranch {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self _harvestLeafsInBranch: answer];
    return answer; // Pending Implementation
}

-(FileCollection*) duplicatesInNode {
    FileCollection *answer = [[FileCollection new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
        }
    }
    return answer;
}

-(FileCollection*) duplicatesInBranch {
    FileCollection *answer = [[FileCollection new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            [answer concatenateFileCollection:[(TreeBranch*)item duplicatesInBranch]];
        }
        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
        }
    }
    return answer;
}

@end
