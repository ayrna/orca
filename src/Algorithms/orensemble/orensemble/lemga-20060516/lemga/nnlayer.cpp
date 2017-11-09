/** @file
 *  $Id: nnlayer.cpp 2550 2006-01-17 04:00:54Z ling $
 */

#include <assert.h>
#include <algorithm>
#include <numeric>
#include "random.h"
#include "quickfun.h"
#include "nnlayer.h"

REGISTER_CREATOR(lemga::NNLayer);

namespace lemga {

NNLayer::NNLayer (UINT n_in, UINT n_unit)
    : LearnModel(n_in, n_unit), w_min(-1), w_max(1),
      w(n_unit*(n_in+1)), dw(n_unit*(n_in+1)), sig_der(n_unit)
{
    quick_tanh_setup();
}

bool NNLayer::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(LearnModel, os, vl, 1);
    if (!(os << w_min << ' ' << w_max << '\n')) return false;
    WVEC::const_iterator pw = w.begin();
    for (UINT i = 0; i < _n_out; ++i) {
        for (UINT j = 0; j <= _n_in; ++j, ++pw)
            if (!(os << *pw << ' ')) return false;
        os << '\n';
    }
    return true;
}

bool NNLayer::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(LearnModel, is, vl, 1, v);

    if (v == 0) // Take care of _n_in and _n_out
        if (!(is >> _n_in >> _n_out)) return false;
    if (!(is >> w_min >> w_max) || w_min >= w_max) return false;

    const UINT n_weights = _n_out * (_n_in+1);
    w.resize(n_weights);
    dw = WVEC(n_weights, 0);
    sig_der = DVEC(_n_out);

    for (UINT i = 0; i < n_weights; ++i)
        if (!(is >> w[i])) return false;
    return true;
}

void NNLayer::set_weight (const WVEC& wgt) {
    assert(wgt.size() == _n_out * (_n_in+1));
    w = wgt;
}

void NNLayer::clear_gradient () {
    std::fill(dw.begin(), dw.end(), 0);
}

void NNLayer::initialize () {
    for (WVEC::iterator pw = w.begin(); pw != w.end(); ++pw)
        *pw = w_min + randu() * (w_max-w_min);
    clear_gradient();
}

REAL NNLayer::sigmoid (REAL x) const {
    stored_sigmoid = quick_tanh(x);
    return stored_sigmoid;
}

REAL NNLayer::sigmoid_deriv (REAL x) const {
    assert(stored_sigmoid == quick_tanh(x));
    return (1 - stored_sigmoid*stored_sigmoid);
}

void NNLayer::feed_forward (const Input& x, Output& y) const {
    assert(x.size() == n_input());
    assert(y.size() == n_output());

    WVEC::const_iterator pw = w.begin();
    for (UINT i = 0; i < _n_out; ++i) {
        const REAL th = *pw;
        const REAL s = std::inner_product(x.begin(), x.end(), ++pw, th);
        pw += _n_in;

        y[i] = sigmoid(s);
        sig_der[i] = sigmoid_deriv(s);
    }
}

void NNLayer::back_propagate (const Input& x, const DVEC& dy, DVEC& dx) {
    assert(x.size() == n_input());
    assert(dy.size() == n_output());
    assert(dx.size() == n_input());

    std::fill(dx.begin(), dx.end(), 0);

    WVEC::const_iterator pw = w.begin();
    DVEC::iterator pdw = dw.begin();
    for (UINT i = 0; i < _n_out; ++i) {
        const REAL delta = dy[i] * sig_der[i];
        *pdw += delta; ++pdw; ++pw;

        DVEC::iterator pdx = dx.begin();
        Input::const_iterator px = x.begin();
        for (UINT j = _n_in; j; --j) {
            *pdw++ += delta * (*px++);
            *pdx++ += delta * (*pw++);
        }
    }
}

} // namespace lemga
