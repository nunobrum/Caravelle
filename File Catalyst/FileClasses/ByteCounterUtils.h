//
//  ByteCounterUtils.h
//  Caravelle
//
//  Created by Nuno Brum on 03/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//



#ifndef __Caravelle__ByteCounterUtils__
#define __Caravelle__ByteCounterUtils__

typedef struct {
    long dec;
    long decx3;
} decade_counter_t;


extern void increment_decade (decade_counter_t *value);
extern void decrement_decade (decade_counter_t *value);

extern long long decade_to_long(decade_counter_t value);
extern int decades_equal(decade_counter_t first, decade_counter_t second);
extern void adjust_decade_to_value(decade_counter_t *decade, long value);

#endif /* defined(__Caravelle__ByteCounterUtils__) */
