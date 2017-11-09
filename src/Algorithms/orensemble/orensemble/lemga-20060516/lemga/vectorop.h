// -*- C++ -*-
#ifndef __STL_ADDON_VECTOROP_H__
#define __STL_ADDON_VECTOROP_H__

/** @file
 *  @brief Add basic arithmetic support to @c vector.
 *
 *  Let @a u and @a v be two vectos and @a r be a scalar. This file defines
 *  the following operators:
 *   - @a u += @a v
 *   - -\a v
 *   - @a v *= @a r
 *   - inner_product<@a typename> (@a u, @a v)
 *
 *  @note The template can `recursively' apply itself to vectors of vectors,
 *  such as two matrices of real numbers could add up (if they have the
 *  same size).
 *
 *  @warning @a u, @a v, and @a r can have different base types. For example,
 *  if @a u is a double vector and @a v an integer vector. When an
 *  inappropriate coercion happens, the compiler may complain (with @c gcc,
 *  turn options @c -Wconversion or @c -Wall on).
 *
 *  $Id: vectorop.h 1907 2004-12-11 00:51:14Z ling $
 */

#include <assert.h>
#include <vector>

namespace lemga {
namespace op {

using std::vector;

/// @a u += @a v.
template <typename R, typename N>
vector<R>& operator+= (vector<R>& u, const vector<N>& v) {
    assert(u.size() == v.size());
    typename vector<R>::iterator x = u.begin();
    typename vector<N>::const_iterator y = v.begin();
    for (; x != u.end(); ++x, ++y) *x += *y;
    return u;
}

/// -@a v.
template <typename R>
vector<R> operator- (const vector<R>& v) {
    vector<R> s(v);
    for (typename vector<R>::iterator x = s.begin(); x != s.end(); ++x)
        *x = -*x;
    return s;
}

/** @brief Inner product of @a u and @a v.
 *
 *  The return type has to be explicitly specified, e.g.,\n
 *  <code>double ip = inner_product<double>(u, v);</code>\n
 *  The compiler will still complain if there is `downward' coercion.
 */
template <typename R, typename N>
inline R inner_product (const R& u, const N& v) {
    return u * v;
}
template <typename RET, typename R, typename N>
RET inner_product (const vector<R>& u, const vector<N>& v) {
    assert(u.size() == v.size());
    RET s(0);
    typename vector<R>::const_iterator x = u.begin();
    typename vector<N>::const_iterator y = v.begin();
    for (; x != u.end(); ++x, ++y) s += inner_product<RET>(*x, *y);
    return s;
}

/// @a v *= @a r.
template <typename R, typename N>
vector<R>& operator*= (vector<R>& v, const N& r) {
    for (typename vector<R>::iterator x = v.begin(); x != v.end(); ++x)
        *x *= r;
    return v;
}

}} // namespace lemga::op

#ifdef  __VECTOROP_H__
#warning "This header file may conflict with another `vectorop.h' file."
#endif
#define __VECTOROP_H__
#endif
