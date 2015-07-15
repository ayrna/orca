/** @file
 *  $Id: stump.cpp 2891 2006-11-08 03:17:31Z ling $
 */

#include <assert.h>
#include <cmath>
#include <algorithm>
#include <vector>
#include <map>
#include "stump.h"

REGISTER_CREATOR(lemga::Stump);

namespace lemga {

bool Stump::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(LearnModel, os, vl, 2);
    return (os << idx << ' ' << bd1 << ' ' << bd2 << ' '
               << (dir? 'P':'N') << '\n');
}

bool Stump::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(LearnModel, is, vl, 2, v);

    if (v == 0) { /* Take care of _n_in and _n_out */
        if (!(is >> _n_in)) return false;
        assert(_n_out == 1);
    }
    /* common part for ver 0, 1, and 2 */
    if (!(is >> idx >> bd1)) return false;
    bd2 = bd1;
    if (v >= 2)
        if (!(is >> bd2) || bd1 > bd2) return false;
    char c;
    if (!(is >> c) || (c != 'P' && c != 'N')) return false;
    dir = (c == 'P');
    return true;
}

typedef std::map<REAL,REAL>::iterator MI;

REAL Stump::train_1d (const std::vector<REAL>& x, const std::vector<REAL>& yw)
{
    const UINT N = x.size();
    assert(yw.size() == N);

    // combine examples with same input, and sort them
    std::map<REAL,REAL> xy;
    for (UINT i = 0; i < N; ++i)
        xy[x[i]] += yw[i];
    UINT n = xy.size();
    xy[xy.begin()->first-2] = 1;    // insert a "very small" x
    assert(xy.size() == n+1);
    for (MI p, pn = xy.begin(); p = pn++, p != xy.end();)
        if (p->second > -INFINITESIMAL && p->second < INFINITESIMAL)
            xy.erase(p);

    n = xy.size();
    xy[xy.rbegin()->first+2] = 1;   // a "very large" x
    assert(n > 0 && xy.size() == n+1);
    const MI xyb = xy.begin();

    REAL minthr = 0, mine = INFINITY, e = - xyb->second;
    REAL cur_x = xyb->first;
    for (MI p = xyb; n; --n) {
        e += p->second;
        assert(p != xyb || e == 0);
        REAL nxt_x = (++p)->first;
        REAL cur_thr = (cur_x + nxt_x) / 2;
        cur_x = nxt_x;

        if (e < mine) {
            mine = e; minthr = cur_thr;
        }
    }

    return minthr;
}

/* yw_inf is yw[infinity] */
REAL Stump::train_1d (const std::vector<REAL>& x, const std::vector<REAL>& yw,
                      REAL yw_inf, bool& ir, bool& mind, REAL& th1, REAL& th2)
{
    const UINT N = x.size();
    assert(yw.size() == N);

    // combine examples with same input, and sort them
    std::map<REAL,REAL> xy;
    for (UINT i = 0; i < N; ++i)
        xy[x[i]] += yw[i];
#ifndef NDEBUG
    UINT n = xy.size();
#endif
    xy[xy.begin()->first-2] = 1;    // insert a "very small" x
    assert(xy.size() == n+1);
    for (MI p, pn = xy.begin(); p = pn++, p != xy.end();)
        if (p->second > -INFINITESIMAL && p->second < INFINITESIMAL)
            xy.erase(p);

#ifndef NDEBUG
    // check whether a constant function is enough
    bool all_the_same = true;
    MI pb = xy.begin(); ++pb;
    for (MI p = pb; p != xy.end(); ++p)
        if (p->second < -INFINITESIMAL) { all_the_same = false; break; }

    if (!all_the_same) {
        all_the_same = true;
        for (MI p = pb; p != xy.end(); ++p)
            if (p->second > INFINITESIMAL) { all_the_same = false; break; }
    }

    if (all_the_same)
        std::cerr << "Stump: Warning: all y's are the same.\n";
#endif
    const MI xyb = xy.begin(), xye = xy.end();

    REAL mine = 0, maxe = 0, e = -1;
    MI mint, maxt, p;
    for (mint = maxt = p = xyb; p != xye; ++p) {
        e += p->second;
        assert(p != xyb || e == 0);
        if (e < mine) {
            mine = e; mint = p;
        } else if (e > maxe) {
            maxe = e; maxt = p;
        }
        // we prefer middle indices
        if (mint == xyb && e == 0) mint = p;
        if (maxt == xyb && e == 0) maxt = p;
    }
    e = (1-e-yw_inf) / 2;// error of y = sgn(x > -Inf)
    mine += e;           // starting with y = -1
    maxe = 1 - (maxe+e); // starting with y = 1

    // unify the solution to mind, mine, and mint
    if (std::fabs(mine - maxe) < EPSILON) {
        MI nxtt = mint; ++nxtt;
        mind = (mint != xyb && nxtt != xye);
    }
    else mind = (mine < maxe);
    if (!mind) {
        mine = maxe; mint = maxt;
    }

    MI nxtt = mint; ++nxtt;
    ir = (mint != xyb && nxtt != xye);
    assert(!ir || !all_the_same);
    th1 = mint->first;
    if (ir)
        th2 = nxtt->first;
    else
        th2 = th1 + 2;

    return mine;
}

/* Find the optimal dimension and threshold */
void Stump::train () {
    const UINT N = n_samples;
    assert(ptd != 0 && ptw != 0 && ptd->size() == N);
    set_dimensions(*ptd);

    // weight the examples
    std::vector<REAL> yw(N);
    for (UINT i = 0; i < N; ++i)
        yw[i] = ptd->y(i)[0] * (*ptw)[i];

    REAL minerr = 2;
    bool minir = true;

    std::vector<REAL> x(N);
    for (UINT d = 0; d < _n_in; ++d) {
        for (UINT i = 0; i < N; ++i)
            x[i] = ptd->x(i)[d];

        bool mind, ir;
        REAL th1, th2;
        REAL mine = train_1d(x, yw, 0, ir, mind, th1, th2);

        if (mine < minerr) {
            minerr = mine;
            minir = ir;
            dir = mind; idx = d;
            bd1 = th1; bd2 = th2;
        }
    }

    if (!minir)
        std::cerr << "Stump: Warning: threshold out of range.\n";
}

Output Stump::operator() (const Input& x) const {
    assert(idx < n_input() && x.size() == n_input());
    assert(bd2 >= bd1);
    REAL y = x[idx]*2 - (bd1 + bd2);
    if (hard || bd1 == bd2)
        y = (y < 0)? -1 : 1;
    else {
        y /= bd2 - bd1;
        y = (y<-1)? -1 : (y>1)? 1 : y;
    }
    return Output(1, dir? y : -y);
}

} // namespace lemga
