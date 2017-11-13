// -*- C++ -*-
#ifndef __LEMGA_DATASET_H__
#define __LEMGA_DATASET_H__

/** @file
 *  @brief Class template @link lemga::dataset dataset@endlink for
 *  wrapping a vector of input-output pairs.
 *
 *  $Id: dataset.h 2537 2006-01-08 08:40:36Z ling $
 */

#include <vector>
#include <utility>
#include "random.h"

namespace lemga {

/** @brief Class template for storing, retrieving, and manipulating a
 *  vector of input-output style data.
 *  @param Tx Type of input @a x.
 *  @param Ty Type of output @a y.
 *
 *  What we want are:
 *  1. a place to store data
 *  2. be able to deal with missing feature?
 *
 *  Member functions:
 *  - basic info.: size, dimension, ...
 *  - load from / save to a file
 *  - copy from / to another format (REAL **)
 *  - ways to produce new data set (by sampling...)
 *
 *  @todo documentation
 */
template <typename Tx, typename Ty>
class dataset {
    /** @note An alternative way to store the input-output pairs is
     *  to put them into separate variables, i.e., one vector for @a x
     *  and one for @a y. However, usually the input @a x and output
     *  @a y in a same pair will be used together. Thus it is better
     *  for systems with cache to put together corresponding @a x and
     *  @a y.
     */
    std::vector< std::pair<Tx,Ty> > d;

public:
    typedef Tx x_type;
    typedef Ty y_type;

    dataset () : d() {}

    //@{ @name Basic
    UINT size () const { return d.size(); }
    bool empty () const { return d.empty(); }
    void clear () { d.clear(); }
    const Tx& x (UINT i) const { return d[i].first; }
    const Ty& y (UINT i) const { return d[i].second; }
    //@}

    //@{ @name Convert from other data types
    template <typename IIX, typename IIY>
    dataset (IIX xb, IIX xe, IIY yb, IIY ye) { import(xb, xe, yb, ye); }

    /** @brief Import data from other types.
     *  @param IIX stands for Input Iterator for @a x.
     *  @param IIY stands for Input Iterator for @a y.
     *
     *  import() copies input @a x from range [@a xb, @a xe) and
     *  output @a y from range [@a yb, @a ye). Old data stored in
     *  the set will be erased.
     *
     *  To import data from two vectors @a vx and @a vy, use
     *  @code import(vx.begin(), vx.end(), vy.begin(), vy.end()); @endcode
     *  To import @a n samples from two pointers px and py, use
     *  @code import(px, px+n, py, py+n); @endcode
     */
    template <typename IIX, typename IIY>
    void import (IIX xb, IIX xe, IIY yb, IIY ye) {
        d.clear();
        d.reserve(xe - xb);
        for (; xb != xe && yb != ye; ++xb, ++yb)
            append(*xb, *yb);
    }
    //@}

    //@{ @name Data manipulation
    /** @brief Generate a randomly sampled copy of the data set.
     *  @param n Number of random samples requested.
     *  @return A pointer to the new born data set.
     *
     *  Samples are chosen with uniform probability.
     */
    dataset* random_sample (UINT n) const {
        const UINT dn = d.size();
        assert(n == 0 || dn > 0);

        dataset* rd = new dataset();
        rd->d.reserve(n);
        while (n--) {
            const UINT sel = UINT(randu() * dn);
            assert(sel < dn);
            rd->d.push_back(d[sel]);
        }
        return rd;
    }

    /** @copydoc random_sample()
     *  @param W Sample weight type, which usually is @c vector<REAL>.
     *  @a W should support @c operator[].
     *  @param wgt Sample weight.
     */
    template <typename W>
    dataset* random_sample (const W& wgt, UINT n) const {
        const UINT dn = d.size();
        assert(n == 0 || dn > 0);

        std::vector<PROBAB> cdf(dn+1);
        cdf[0] = 0;
        for (UINT i = 0; i < dn; ++i)
            cdf[i+1] = cdf[i] + wgt[i];
        assert(cdf[dn]-1 > -EPSILON && cdf[dn]-1 < EPSILON);

        dataset* rd = new dataset();
        rd->d.reserve(n);
        while (n--) {
            const PROBAB r = randu();

            UINT b = 0, e = dn, m;
            while (b+1 < e) {
                m = (b + e) / 2;
                if (r < cdf[m]) e = m;
                else b = m;
            }

            rd->d.push_back(d[b]);
        }
        return rd;
    }
    //@}

    /** @brief Combine two data sets.
     *  @note Code
     *  @code copy(ds.d.begin(), ds.d.end(), back_inserter(d)); @endcode
     *  does almost the same thing, but will fail when @a ds is just
     *  *this. That is, @code ds += ds; @endcode doesn't work.
     *  @todo We need more functions to add/remove samples.
     */
    dataset& operator+= (const dataset& ds) {
        const UINT n = ds.d.size();
        d.reserve(d.size() + n);
        for (UINT i = 0; i < n; ++i)
            d.push_back(ds.d[i]);
        return *this;
    }

    void append (const Tx& _x, const Ty& _y) {
        d.resize(d.size()+1);           // 1 constructor + 1 copy
        d.back().first = _x;            // 1 copy
        d.back().second = _y;
        //d.push_back(make_pair(_x, _y));   // 2 copy
    }

    void replace (UINT i, const Tx& _x, const Ty& _y) {
        assert (i < d.size());
        d[i].first = _x;
        d[i].second = _y;
    }
};

} // namespace lemga

#ifdef  __DATASET_H__
#warning "This header file may conflict with another `dataset.h' file."
#endif
#define __DATASET_H__
#endif
