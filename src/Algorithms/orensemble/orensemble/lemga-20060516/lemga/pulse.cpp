/** @file
 *  $Id: pulse.cpp 2664 2006-03-07 19:50:51Z ling $
 */

#include <assert.h>
#include <cmath>
#include <vector>
#include <map>
#include <algorithm>
#include "pulse.h"

REGISTER_CREATOR(lemga::Pulse);

template <typename II>
bool serialize (std::ostream& os, const II& b, const II& e, bool l = true) {
    if (l) if (!(os << (e - b) << '\n')) return false;
    for (II i = b; i != e; ++i)
        if (!(os << *i << ' ')) return false;
    if (b != e) os << '\n';
    return true;
}

template <typename II>
bool unserialize (std::istream& is, const II& b, const II& e) {
    for (II i = b; i != e; ++i)
        if (!(is >> *i)) return false;
    return true;
}

namespace lemga {

bool Pulse::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(LearnModel, os, vl, 1);
    if (!(os << idx << ' ' << th.size() << ' ' << (dir? '-':'+') << '\n'))
        return false;
    return ::serialize(os, th.begin(), th.end(), false);
}

bool Pulse::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(LearnModel, is, vl, 1, v);
    assert(v > 0);

    UINT nl;
    if (!(is >> idx >> nl)) return false;
    char c;
    if (!(is >> c) || (c != '-' && c != '+')) return false;
    dir = (c == '-');

    th.resize(nl);
    return ::unserialize(is, th.begin(), th.end());
}

void Pulse::set_threshold (const std::vector<REAL>& t) {
    assert(t.size() <= max_l);
#ifndef NDEBUG
    // assert t is sorted (std::is_sorted is an SGL extension)
    for (UINT i = 1; i < t.size(); ++i)
        assert(t[i-1] <= t[i]);
#endif
    th = t;
}

void Pulse::train () {
    const UINT N = n_samples;
    assert(ptd != 0 && ptw != 0 && ptd->size() == N);
    set_dimensions(*ptd);

    std::vector<REAL> yw(N);
    for (UINT i = 0; i < N; ++i)
        yw[i] = ptd->y(i)[0] * (*ptw)[i];

    REAL minerr = 2;         // a number large enough (> 1)
    std::vector<UINT> thi;   // threshold index
    std::vector<REAL> xb(N); // backup for sorted x

    // no reallocation within loops
    std::vector<REAL> x(N), ysum(N);
    for (UINT d = 0; d < _n_in; ++d) {
        // extract the dimension d info, collapse data with same x
        std::map<REAL,REAL> xy;
        for (UINT i = 0; i < N; ++i)
            xy[ptd->x(i)[d]] += yw[i];
        REAL sum = 0;
        int last_sign = 0;  // 1: pos, 2: neg, 3: zero
        std::vector<REAL>::iterator px = x.begin(), py = ysum.begin();
        for (std::map<REAL,REAL>::const_iterator
                 p = xy.begin(); p != xy.end(); ++p) {
            static REAL last_x;
            const int cur_sign = (p->second > 0)? 1:((p->second < 0)? 2:3);
            if (last_sign != cur_sign && last_sign != 0) {
                /** @note we can also save the threshold info. as lower
                 *  and upper @a x values, which is a bit faster (less
                 *  operations) but needs more memory space. */
                *px = last_x + p->first; *py = sum * 2;
                ++px; ++py;
            }
            last_sign = cur_sign;
            last_x = p->first;
            sum += p->second;
            assert(-1.01 < sum && sum < 1.01);
        }
        *py = sum * 2;
        const UINT n = py - ysum.begin();

        std::vector<REAL> e0(n+1, 0); // error of pulses ending with -1
        std::vector<REAL> e1(n+1, 0); // error of pulses ending with +1
        std::vector<std::vector<UINT> > t0(n+1), t1(n+1); // transitions idx

        // dynamic programming: compute err for level 1--max_l
        // e0 and e1 at the begining of loop l are
        //    e0[i] = 2*best_e_{i,l} - 1 - sum(w*y),
        //    e1[i] = 2*best_e_{i,l} - 1 + sum(w*y).
        // where best_e_{i,l} is the lowest error if l transitions
        // happens before or at position i.
        for (UINT l = 0; l < max_l; ++l) {
            // swap e0 & e1, t0 & t1 to get rid of the sign change
            e0.swap(e1); t0.swap(t1);

            // compute errors for level (l+1)
            std::vector<REAL>::iterator p0 = e0.begin(), p1 = e1.begin();
            std::vector<REAL>::iterator ps = ysum.begin();
            for (UINT i = 0; i <= n; ++p0, ++p1, ++ps, ++i) {
                *p0 -= *ps; *p1 += *ps;
            }
            assert(p0 == e0.end());

            std::vector<std::vector<UINT> >::iterator
                pt0 = t0.begin(), pt1 = t1.begin();
            REAL bst0 = 3, bst1 = 3;  // a number large enough (> 2)
            p0 = e0.begin(); p1 = e1.begin();
            for (UINT i = 0; i <= n; ++p0, ++p1, ++pt0, ++pt1, ++i) {
                static std::vector<UINT> tb0, tb1;  // always the best
                assert(-2.01 < *p0 && *p0 < 2.01);
                assert(-2.01 < *p1 && *p1 < 2.01);

                if (*p0 < bst0) {
                    bst0 = *p0; tb0.swap(*pt0); // => tb0 = *pt0;
                    if (i < n) tb0.push_back(i);
                }
                *p0 = bst0; *pt0 = tb0;

                if (*p1 < bst1) {
                    bst1 = *p1; tb1.swap(*pt1); // => tb1 = *pt1;
                    if (i < n) tb1.push_back(i);
                }
                *p1 = bst1; *pt1 = tb1;
            }
            assert(p0 == e0.end());
        }

        e0[n] += ysum[n] / 2;
        e1[n] -= ysum[n] / 2;
        if (e0[n] <= e1[n] && e0[n] < minerr) {
            minerr = e0[n]; idx = d; dir = !(max_l & 1);
            thi.swap(t0[n]); xb.swap(x);
        } else if (e1[n] < minerr) {
            minerr = e1[n]; idx = d; dir = (max_l & 1);
            thi.swap(t1[n]); xb.swap(x);
        }
    }

    th.clear();
    for (UINT i = 0; i < thi.size(); /* empty */) {
        UINT ind = thi[i]; ++i;
        if (i < thi.size() && ind == thi[i])
            ++i;
        else
            th.push_back(xb[ind] / 2);
    }
}

Output Pulse::operator() (const Input& x) const {
    assert(idx < n_input() && x.size() == n_input());

    if (th.empty())
        return Output(1, dir? -1 : 1);

    const UINT i =
        std::lower_bound(th.begin(), th.end(), x[idx]) - th.begin();
    return Output(1, ((i & 1) ^ dir)? -1 : 1);
}

} // namespace lemga
