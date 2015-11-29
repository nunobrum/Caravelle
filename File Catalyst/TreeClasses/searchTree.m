//
//  searchTree.m
//  File Catalyst
//
//  Created by Nuno Brum on 12/10/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "searchTree.h"
#import "filterBranch.h"
#import "MyDirectoryEnumerator.h"
//#import "TreeBranch_TreeBranchPrivate.h"
#import "definitions.h"
//#include "FileUtils.h"


@implementation searchTree

#pragma mark Initializers

-(instancetype) initWithSearch:(NSString*)searchKey name:(NSString*)name parent:(TreeBranch*)parent {
    self = [super initWithURL:nil parent:parent];
    self->_query = [[NSMetadataQuery alloc] init];
    self.nameCache = name;
    self->_searchKey = searchKey;
    self->searchContent = NO;
    // To watch results send by the query, add an observer to the NSNotificationCenter
    NSNotificationCenter *nf = [NSNotificationCenter defaultCenter];
    [nf addObserver:self selector:@selector(queryNote:) name:nil object:self->_query];

    // We want the items in the query to automatically be sorted by the file system name; this way, we don't have to do any special sorting
    [self->_query setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:(id)kMDItemFSName ascending:YES]]];
    // For the groups, we want the first grouping by the kind, and the second by the file size.
    [self->_query setGroupingAttributes:[NSArray arrayWithObjects:(id)kMDItemKind, (id)kMDItemFSSize, nil]];
    [self->_query setDelegate:self];
    return self;
}

//+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
//    searchTree *tree = [searchTree alloc];
//    return [tree initFromEnumerator:dirEnum URL:rootURL parent:parent cancelBlock:cancelBlock];
//}

-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
    self = [self initWithURL:rootURL parent:parent];
    /* Since the instance is created now, there is no problem with thread synchronization */
    for (NSURL *theURL in dirEnum) {
        [self addURL:theURL];
        if (cancelBlock())
            break;
    }
    return self;
}

#pragma mark NSMetadataQueryDelegate
// NSMetadataQuery delegate methods.
//- (id)metadataQuery:(NSMetadataQuery *)query replacementObjectForResultObject:(NSMetadataItem *)result {
//
//}

// metadataQuery:replacementValueForAttribute:value allows the resulting value retrieved from an NSMetadataItem to be changed. When items are grouped, we want to allow all items of a similar size to be grouped together. This allows this to happen.
//- (id)metadataQuery:(NSMetadataQuery *)query replacementValueForAttribute:(NSString *)attrName value:(id)attrValue {
//    if ([attrName isEqualToString:(id)kMDItemFSSize]) {
//        NSInteger fsSize = [attrValue integerValue];
//        // Here is a special case for small files
//        if (fsSize == 0) {
//            return NSLocalizedString(@"0 Byte Files", @"File size, for empty files and directories");
//        }
//        const NSInteger cutOff = 1024;
//
//        if (fsSize < cutOff) {
//            return NSLocalizedString(@"< 1 KB Files", @"File size, for items that are less than 1 kilobyte");
//        }
//
//        // Figure out how many kb, mb, etc, that we have
//        NSInteger numK = fsSize / 1024;
//        if (numK < cutOff) {
//            return [NSString stringWithFormat:NSLocalizedString(@"%ld KB Files", @"File size, expressed in kilobytes"), (long)numK];
//        }
//
//        NSInteger numMB = numK / 1024;
//        if (numMB < cutOff) {
//            return [NSString stringWithFormat:NSLocalizedString(@"%ld MB Files", @"File size, expressed in megabytes"), (long)numMB];
//        }
//
//        return NSLocalizedString(@"Huge files", @"File size, for really large files");
//    } else if ((attrValue == nil) || (attrValue == [NSNull null])) {
//        // We don't want to display <null> for the user, so, depending on the category, display something better
//        if ([attrName isEqualToString:(id)kMDItemKind]) {
//            return NSLocalizedString(@"Other", @"Kind to display for unknown file types");
//        } else {
//            return NSLocalizedString(@"Unknown", @"Kind to display for other unknown values");
//        }
//    } else {
//        return attrValue;
//    }
//
//}


#pragma mark notifications

- (void)queryNote:(NSNotification *)note {
    // The NSMetadataQuery will send back a note when updates are happening. By looking at the [note name], we can tell what is happening
    if ([[note name] isEqualToString:NSMetadataQueryDidStartGatheringNotification]) {
        // The gathering phase has just started!
        NSLog(@"Started gathering");
    } else if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        // At this point, the gathering phase will be done. You may recieve an update later on.
        NSLog(@"Finished gathering");
        for (NSMetadataItem *item in self->_query.results) {
            //NSLog(@"QR:%@",[item valueForAttribute:(id)kMDItemPath]);
            //NSArray *a = [item attributes];
            //for (NSString *s in a)
             //   NSLog(@"%@ - %@",s, [item valueForAttribute:s]);
            [self addMDItem:item];
        }
    } else if ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification]) {
        // The query is still gatherint results...
        NSLog(@"Progressing...%lu", (unsigned long)self->_query.resultCount);
    } else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
        // An update will happen when Spotlight notices that a file as added, removed, or modified that affected the search results.
        NSLog(@"An update happened.");
    }
}


- (void)createSearchPredicate {
    // This demonstrates a few ways to create a search predicate.

    // The user can set the checkbox to include this in the search result, or not.
    NSPredicate *predicateToRun = nil;
    if (self->searchContent) {
        // In the example below, we create a predicate with a given format string that simply replaces %@ with the string that is to be searched for. By using "like", the query will end up doing a regular expression search similar to *foo* when you are searching for the word "foo". By using the [c], the NSCaseInsensitivePredicateOption will be set in the created predicate. The particular item type to search for, kMDItemTextContent, is described in MDItem.h.
        NSString *predicateFormat = @"kMDItemTextContent like[c] %@";
        predicateToRun = [NSPredicate predicateWithFormat:predicateFormat, self->_searchKey];
    }

    // Create a compound predicate that searches for any keypath which has a value like the search key. This broadens the search results to include things such as the author, title, and other attributes not including the content. This is done in code for two reasons: 1. The predicate parser does not yet support "* = Foo" type of parsing, and 2. It is an example of creating a predicate in code, which is much "safer" than using a search string.
    NSUInteger options = (NSCaseInsensitivePredicateOption|NSDiacriticInsensitivePredicateOption);
    NSPredicate *compPred = [NSComparisonPredicate
                             predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"*"]
                             rightExpression:[NSExpression expressionForConstantValue:self->_searchKey]
                             modifier:NSDirectPredicateModifier
                             type:NSLikePredicateOperatorType
                             options:options];

    // Combine the two predicates with an OR, if we are including the content as searchable
    if (self->searchContent) {
        predicateToRun = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:compPred, predicateToRun, nil]];
    } else {
        // Since we aren't searching the content, just use the other predicate
        predicateToRun = compPred;
    }

    if (0) { // This is the original code from Spotlighter
    // Now, we don't want to include email messages in the result set, so add in an AND that excludes them
    NSPredicate *emailExclusionPredicate = [NSPredicate predicateWithFormat:@"(kMDItemContentType != 'com.apple.mail.emlx') && (kMDItemContentType != 'public.vcard')"];
    predicateToRun = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicateToRun, emailExclusionPredicate, nil]];

    } else { // I want to use the URL to limit the search
        if ([self url]!=nil)
            [self->_query setSearchScopes:[NSArray arrayWithObjects:[self url], nil]];
        else
            [self->_query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUserHomeScope]];
    }


    // Set it to the query. If the query already is alive, it will update immediately
    [self->_query setPredicate:predicateToRun];

    // In case the query hasn't yet started, start it.
    [self->_query startQuery];
}


#pragma mark -



@end
