//
//  IconCollectionItem.m
//  Caravelle
//
//  Created by Viktoryia Labunets on 09/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "IconCollectionItem.h"

@interface IconCollectionItem ()

@end

@implementation IconCollectionItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


- (IBAction) doubleClick:(id)sender {
    //NSLog(@"double click in the collectionItem");
    if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(doubleClick:)]) {
        [[[self collectionView] delegate] performSelector:@selector(doubleClick:) withObject:self];
    }
}

- (IBAction)rightClick:(id)sender {
    if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(doubleClick:)]) {
        [[[self collectionView] delegate] performSelector:@selector(rightClick:) withObject:self];
    }
}

@end
