/** @file
 *  $Id: cascade.cpp 2550 2006-01-17 04:00:54Z ling $
 */

#include <assert.h>
#include "cascade.h"

namespace lemga {

bool Cascade::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(Aggregating, os, vl, 1);
    assert(lm.size() == upper_margin.size() &&
           lm.size() == lower_margin.size());
    for (UINT i = 0; i < lm.size(); ++i)
        if (!(os << '(' << lower_margin[i] << ','
              << upper_margin[i] << ')' << ' ')) return false;
    return true;
}

bool Cascade::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(Aggregating, is, vl, 1, v);

    const UINT n = lm.size();
    upper_margin.resize(n);
    lower_margin.resize(n);

    for (std::vector<REAL>::iterator
             pu = upper_margin.begin(), pl = lower_margin.begin();
         pu != upper_margin.end(); ++pu, ++pl)
    {
        char c;
        if (!(is >> c >> *pl >> c >> *pu >> c)) return false;
        if (*pl > *pu) return false;
    }

    return true;
}

Output Cascade::operator() (const Input& x) const {
    assert(n_in_agg > 0 && n_in_agg <= lm.size());
    assert(lm.size() == upper_margin.size() &&
           lm.size() == lower_margin.size());

    for (UINT i = 0; i < n_in_agg-1; ++i) {
        assert(lm[i] != NULL);
        Output out = (*lm[i])(x);
        REAL b = belief(*lm[i], x, out);
        //assert(lower_margin[i] < upper_margin[i]);
        if (b > upper_margin[i] || b < lower_margin[i])
            return out;
    }

    return (*lm[n_in_agg-1])(x);
}

/** We use the ``sign'' part of margin in AdaBoost */
REAL Cascade::belief (const LearnModel& l, const Input& x,
                      const Output& y) const {
    assert(l(x) == y);
    assert(l.n_output() == 1);
    return y[0];
}

} // namespace lemga
