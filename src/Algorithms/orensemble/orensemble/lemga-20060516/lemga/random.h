/* random.h -- Define several random distributions
 *
 * Copyright (C) 2001 Ling Li
 * ling@caltech.edu
 */

#ifndef __RANDOM_H__
#define __RANDOM_H__
#define __COMMON_TYPES_RANDOM_H__

#include <stdlib.h>
#include "object.h"

typedef REAL PROBAB;

#ifdef __cplusplus
extern "C" {
#endif

void set_seed (unsigned int seed);
/* randu: [0, 1); randuc: [0, 1] */
#define randu()    (rand() / (RAND_MAX + 1.0))
#define randuc()   (rand() / (PROBAB) RAND_MAX)
REAL randn ();

#ifdef __cplusplus
}
#endif

#else /* __RANDOM_H__ */

#ifndef __COMMON_TYPES_RANDOM_H__
 #error This header file conflicts with another "random.h" file.
#endif

#endif
