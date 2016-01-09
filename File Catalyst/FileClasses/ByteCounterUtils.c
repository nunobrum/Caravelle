//
//  ByteCounterUtils.cpp
//  Caravelle
//
//  Created by Nuno Brum on 03/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#include "ByteCounterUtils.h"


// TODO:1.4 User Definitions to change between 1000 and 1024 counter style :
/*
 enum {
 NSByteCountFormatterCountStyleFile   = 0,
 NSByteCountFormatterCountStyleMemory = 1,
 NSByteCountFormatterCountStyleDecimal = 2,
 NSByteCountFormatterCountStyleBinary  = 3
 };
 typedef NSInteger NSByteCountFormatterCountStyle;
 */

 void increment_decade (decade_counter_t *value) {
    if (value->dec>=100) {
        value->dec = 1;
        value->decx3 *= 1024;
    }
    else {
        value->dec *= 10;
    }
}
 void decrement_decade (decade_counter_t *value) {
    if (value->dec < 10) {
        value->dec = 100;
        value->decx3 /= 1024;
    }
    else {
        value->dec /= 10;
    }
}

 long long decade_to_long(decade_counter_t value) {
    return (value.dec * value.decx3);
}

int decades_equal(decade_counter_t first, decade_counter_t second) {
    if (first.decx3==second.decx3 && first.dec == second.dec)
        return 1;
    else
        return 0;
}

void adjust_decade_to_value(decade_counter_t *decade, long value) {
    decade->decx3 = 1;
    decade->dec = 1;
    while (decade_to_long(*decade) <= value) {
        increment_decade(decade);
    }
    decrement_decade(decade);
}
