/** @file
 *  $Id: quickfun.c 1789 2004-04-23 05:15:44Z ling $
 */

#include <assert.h>
#include <math.h>
#include "quickfun.h"

#define round(x)        ((UINT)(x+0.5))

#define TANH_RANGE0     1.84   /* tanh(1.84) = 0.95079514... */
#define TANH_RANGE1     4.5    /* tanh(4.5)  = 0.99975321... */
#define TANH_STEP0      0.001
#define TANH_STEP1      0.005

#define TANH_FACTOR0    (1/TANH_STEP0)
#define TANH_FACTOR1    (1/TANH_STEP1)
#define TANH_SIZE0      (round(TANH_FACTOR0*TANH_RANGE0)+1)
#define TANH_SIZE1      (round(TANH_FACTOR1*(TANH_RANGE1-TANH_RANGE0))+1)

/* note: C doesn't have boolean type */
static int tanh_table_ready = 0;
static REAL tanh_table0[TANH_SIZE0], tanh_table1[TANH_SIZE1];

void quick_tanh_setup (void) {
    UINT i;
    if (tanh_table_ready) return;

    for (i = 0; i < TANH_SIZE0; ++i)
        tanh_table0[i] = tanh(i * TANH_STEP0);
    for (i = 0; i < TANH_SIZE1; ++i)
        tanh_table1[i] = tanh(i * TANH_STEP1 + TANH_RANGE0);
    tanh_table_ready = 1;
}

static REAL quick_tanh_p (REAL x) {
    if (x <= TANH_RANGE0)
        return tanh_table0[round(x * TANH_FACTOR0)];
    else if (x <= TANH_RANGE1)
        return tanh_table1[round((x - TANH_RANGE0) * TANH_FACTOR1)];
    return 0.9998;
}

REAL quick_tanh (REAL x) {
    assert(tanh_table_ready);

    if (x < 0)
        return -quick_tanh_p(-x);
    return quick_tanh_p(x);
}
