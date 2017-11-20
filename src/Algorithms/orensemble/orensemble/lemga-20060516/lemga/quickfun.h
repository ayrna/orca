#ifndef __QUICKFUN_H__
#define __QUICKFUN_H__
#define __COMMON_TYPES_QUICKFUN_H__

#include "object.h"

#ifdef __cplusplus
extern "C" {
#endif

void quick_tanh_setup (void);
REAL quick_tanh (REAL x);

#ifdef __cplusplus
}
#endif

#else /* def __QUICKFUN_H__ */

#ifndef __COMMON_TYPES_QUICKFUN_H__
 #error This header file conflicts with another "quickfun.h" file.
#endif

#endif
