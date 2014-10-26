//
//  myValueTransformers.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 26/10/14.
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

