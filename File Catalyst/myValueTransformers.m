//
//  myValueTransformers.m
//  File Catalyst
//
//  Created by Nuno Brum on 26/10/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "myValueTransformers.h"

@implementation DateToStringTransformer
+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

-(instancetype) init {
    self->transformer = [[NSDateFormatter alloc] init];
    [self->transformer setTimeStyle:NSDateFormatterMediumStyle];
    [self->transformer setDateStyle:NSDateFormatterMediumStyle];
    return self;
}

-(instancetype) initWithFormat:(NSString*)format {
    self->transformer = [[NSDateFormatter alloc] init];
    [self->transformer setDateFormat:format];
    return self;
}

- (id)transformedValue:(id)value {
    NSString *str = (value == nil) ? nil : [self->transformer stringFromDate:value];
    return str;
}
@end

DateToStringTransformer *DateToYearTransformer() {
    static DateToStringTransformer *DateTransformer=nil;
    // TODO:! Put formats in the User Definitions
    if (DateTransformer==nil)
        DateTransformer = [[DateToStringTransformer alloc] initWithFormat:@"yyyy"];
    return DateTransformer ;
}

DateToStringTransformer *DateToMonthTransformer() {
    static DateToStringTransformer *DateTransformer=nil;
    if (DateTransformer==nil)
        DateTransformer = [[DateToStringTransformer alloc] initWithFormat:@"MM"];
    return DateTransformer ;
}

DateToStringTransformer *DateToDayTransformer() {
    static DateToStringTransformer *DateTransformer=nil;
    if (DateTransformer==nil)
        DateTransformer = [[DateToStringTransformer alloc] initWithFormat:@"dd"];
    return DateTransformer ;
}


@implementation SizeToStringTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSNumber class] ]) {
        long long v = [(NSNumber*) value longLongValue];
        return [NSByteCountFormatter stringFromByteCount:v countStyle:NSByteCountFormatterCountStyleFile];
    }
    return nil;
}

@end

@implementation BookmarkToPathTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

//
// Transforms URL bookmarks into visible paths to display in the User Definitions
- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSData class] ]) {
        BOOL dataStalled;
        NSError *error;
        NSURL *allowedURL = [NSURL URLByResolvingBookmarkData:value
                                                      options:NSURLBookmarkResolutionWithSecurityScope
                                                relativeToURL:nil
                                          bookmarkDataIsStale:&dataStalled
                                                        error:&error];
        if (error==nil && dataStalled==NO) {
            return [allowedURL path];
        }
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:[value count]];
        for (id bookmark in value) {
            if ([bookmark isKindOfClass:[NSData class] ]) {
                BOOL dataStalled;
                NSError *error;
                NSURL *allowedURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                              options:NSURLBookmarkResolutionWithSecurityScope
                                                        relativeToURL:nil
                                                  bookmarkDataIsStale:&dataStalled
                                                                error:&error];
                if (error==nil && dataStalled==NO) {
                    [result addObject: [allowedURL path]];
                }
                else {
                    [result addObject:@"unrecognized authorization token"];
                }
            }
        }
        return result;
    }
    return nil;
}


@end

@implementation MySelectedColorTransformer

+ (Class)transformedValueClass {
    return [NSColor class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSNumber class] ]) {
        BOOL selected = [value boolValue];
        if (selected)
            return [NSColor alternateSelectedControlTextColor];
    }
    return [NSColor controlTextColor];
}
@end
