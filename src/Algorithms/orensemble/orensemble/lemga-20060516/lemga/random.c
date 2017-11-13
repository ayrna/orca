#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "random.h"

void set_seed (unsigned int seed)
{
    if (seed == 0 || seed > RAND_MAX) {
        /* use time() to set the seed */
        time_t t = time(NULL);
        assert(t > 0);
        seed = t;
    }
    fprintf(stderr, "random seed = %u\n", seed);
    srand(seed);
}

REAL randn () {
    static int saved = 0;
    static REAL saved_val;
    REAL rsq, v1, v2, ratio;

    if (saved) {
        saved = 0;
        return saved_val;
    }

    do {
        v1 = 2*randu()-1;
        v2 = 2*randu()-1;
        rsq = v1*v1 + v2*v2;
    } while (rsq >= 1 || rsq == 0);
    ratio = sqrt(-2 * log(rsq)/rsq);

    saved_val = v1 * ratio;
    saved = 1;
    return v2 * ratio;
}
