/** @file
 *  $Id: bagging.cpp 2664 2006-03-07 19:50:51Z ling $
 */

#include <assert.h>
#include <cmath>
#include "bagging.h"

REGISTER_CREATOR(lemga::Bagging);

namespace lemga {

Output Bagging::operator() (const Input& x) const {
    assert(n_in_agg <= size() && _n_out > 0);

    Output y(_n_out, 0);
    for (UINT i = 0; i < n_in_agg; ++i) {
        assert(lm[i] != 0 && exact_dimensions(*lm[i]));
        Output yi = (*lm[i])(x);
        for (UINT j = 0; j < _n_out; ++j)
            y[j] += (yi[j] > 0)? 1 : -1;
    }

    return y;
}

void Bagging::train () {
    assert(ptd != 0 && ptw != 0);
    set_dimensions(*ptd);

    for (n_in_agg = size(); n_in_agg < max_n_model; ++n_in_agg) {
#if VERBOSE_OUTPUT
        std::cout << "=== " << id() << " #" << n_in_agg+1 << " / "
                  << max_n_model << " ===\n";
#endif
        assert(lm_base != 0);
        LearnModel *p = lm_base->clone();
        p->set_train_data(ptd->random_sample(*ptw, n_samples));
        p->train();
        p->set_train_data(ptd, ptw); // get rid of the random sample
        set_dimensions(*p);
        lm.push_back(p);
    }
}

REAL Bagging::margin_norm () const {
    return n_in_agg;
}

REAL Bagging::margin_of (const Input& x, const Output& y) const {
    assert(std::fabs(y[0]*y[0]-1) < INFINITESIMAL);
    return (*this)(x)[0] * y[0];
}

} // namespace lemga
