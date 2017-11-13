// -*- C++ -*-
#ifndef __LEMGA_UTILITY_H__
#define __LEMGA_UTILITY_H__

/** @file
 *  @brief Some utility functions.
 *
 *  $Id: utility.h 2631 2006-02-08 21:58:14Z ling $
 */

#include <vector>
#include "object.h"

/** Solve inv(@a A) * @a b, when @a A is symmetric and positive-definite.
 *  Actually we only need the upper triangular part of @a A.
 */
bool ldivide (std::vector<std::vector<REAL> >& A,
              const std::vector<REAL>& b, std::vector<REAL>& x);

/// Gray code: start from all 0's, and iteratively go through all numbers
template<class N>
bool gray_next (std::vector<N>& v, typename std::vector<N>::size_type& p) {
    typename std::vector<N>::size_type n = v.size();
    assert(n > 0);

    // by default we alter the last bit
    p = n - 1;
    bool more = true;

    // find the largest n such that v[n] == 1
    while (--n && v[n] == 0) /* empty */;

    if (n > 0) {
        typename std::vector<N>::size_type j = n;
        bool xor_sum = true;
        while (n--)
            xor_sum = xor_sum ^ (v[n] != 0);
        if (xor_sum) p = j - 1;
    } else if (v[0] != 0) {
        p = 0; more = false;
    }
    v[p] = (v[p] == 0);
    return more;
}

template<class N>
bool gray_next (std::vector<N>& v) {
    typename std::vector<N>::size_type p;
    return gray_next(v, p);
}

#ifdef  __UTILITY_H__
#warning "This header file may conflict with another `utility.h' file."
#endif
#define __UTILITY_H__
#endif
