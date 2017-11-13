/** @file
 *  $Id: boosting.cpp 2696 2006-04-05 20:10:13Z ling $
 */

#include <assert.h>
#include "vectorop.h"
#include "optimize.h"
#include "boosting.h"

REGISTER_CREATOR(lemga::Boosting);

#define _cost(F,y)          cost_functor.cost(F[0],y[0])
#define _cost_deriv(F,y)    cost_functor.deriv1(F[0],y[0])

namespace lemga {

/** @copydoc LearnModel(UINT,UINT)
 *  @param cvx \c true if convex combination is used; \c false if
 *  linear combination is used */
Boosting::Boosting (bool cvx, const cost::Cost& c)
    : Aggregating(), convex(cvx), grad_desc_view(false),
      min_cst(0), min_err(-1), cost_functor(c)
{ /* empty */ }

Boosting::Boosting (const Aggregating& s)
    : Aggregating(s), lm_wgt(lm.size(), 1), convex(false),
      grad_desc_view(false), min_cst(0), min_err(-1),
      cost_functor(cost::_cost)
{}

bool Boosting::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(Aggregating, os, vl, 1);
    assert(lm_wgt.size() == lm.size());
    for (UINT i = 0; i < lm_wgt.size(); ++i)
        os << lm_wgt[i] << ' ';
    if (!lm_wgt.empty()) os << '\n';
    return (os << convex << '\n');
}

bool Boosting::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(Aggregating, is, vl, 1, v);

    const UINT n = lm.size();
    lm_wgt.resize(n);
    for (UINT i = 0; i < n; ++i)
        if (!(is >> lm_wgt[i])) return false;

    UINT c;
    if (!(is >> c)) {
        if (v != 0) return false;
        convex = false; // some old version: no convex
    }
    else if (c > 1) return false;
    convex = c;
    return true;
}

void Boosting::reset () {
    Aggregating::reset();
    lm_wgt.clear();
#if BOOSTING_OUTPUT_CACHE
    clear_cache();
#endif
}

REAL Boosting::margin_norm () const {
    return convex? 1 : model_weight_sum();
}

REAL Boosting::margin_of (const Input& x, const Output& y) const {
    assert(std::fabs(y[0]*y[0]-1) < INFINITESIMAL);
    return (*this)(x)[0] * y[0];
}

REAL Boosting::margin (UINT i) const {
    REAL y = ptd->y(i)[0];
    assert(std::fabs(y*y-1) < INFINITESIMAL);
    return get_output(i)[0] * y;
}

Output Boosting::operator() (const Input& x) const {
    assert(n_in_agg <= lm.size() && lm.size() == lm_wgt.size() && _n_out > 0);
#ifndef NDEBUG
    for (UINT i = 0; i < n_in_agg; ++i)
        assert(lm_wgt[i] >= 0);
#endif

    Output y(_n_out, 0);
    for (UINT i = 0; i < n_in_agg; ++i) {
        assert(lm[i] != 0 && exact_dimensions(*lm[i]));
        Output out = (*lm[i])(x);
        for (UINT j = 0; j < _n_out; ++j)
            y[j] += (out[j] > 0)? lm_wgt[i] : -lm_wgt[i];
    }

    if (convex && n_in_agg > 0) {
        using namespace op;
        y *= 1 / model_weight_sum();
    }
    return y;
}

Output Boosting::get_output (UINT idx) const {
    assert(n_in_agg <= lm.size() && lm.size() == lm_wgt.size() && _n_out > 0);
    assert(ptw != 0); // no data sampling

#if BOOSTING_OUTPUT_CACHE
    if (cache_n[idx] > n_in_agg)
        clear_cache(idx);
    Output& y = cache_y[idx];
    UINT start = cache_n[idx];
    cache_n[idx] = n_in_agg;
    if (start == 0) { // y is either empty, or already filled with 0
        assert(y.empty() || y[0] == 0); // only check y[0]
        y.resize(_n_out, 0);
    }
#else
    Output y(_n_out, 0);
    UINT start = 0;
#endif
    assert(y.size() == _n_out);
    for (UINT i = start; i < n_in_agg; ++i) {
        assert(lm[i] != 0 && exact_dimensions(*lm[i]));
        assert(lm[i]->train_data() == ptd);
        Output out = lm[i]->get_output(idx);
        for (UINT j = 0; j < _n_out; ++j)
            y[j] += (out[j] > 0)? lm_wgt[i] : -lm_wgt[i];
    }

    if (convex && n_in_agg > 0) {
        using namespace op;
#if BOOSTING_OUTPUT_CACHE
        Output y2 = y;
        return (y2 *= 1 / model_weight_sum());
#else
        y *= 1 / model_weight_sum();
#endif
    }
    return y;
}

#if BOOSTING_OUTPUT_CACHE
void Boosting::set_train_data (const pDataSet& pd, const pDataWgt& pw) {
    pDataSet old_ptd = ptd;
    Aggregating::set_train_data(pd, pw);
    if (old_ptd != ptd) clear_cache();
}
#endif

void Boosting::train () {
    assert(ptd != 0 && ptw != 0);
    assert(lm_base != 0); // we need lm_base to create new hypotheses
    set_dimensions(*ptd);

    if (grad_desc_view) {
        train_gd();
        return;
    }

    n_in_agg = size();
    pDataWgt sample_wgt = sample_weight();

    while (n_in_agg < max_n_model) {
        const pLearnModel p = train_with_smpwgt(sample_wgt);

        // update sample_wgt, set up hypothesis wgt (lm_wgt)
        const REAL w = assign_weight(*sample_wgt, *p);
        if (w <= 0) break;

        set_dimensions(*p);
        lm.push_back(p); lm_wgt.push_back(w);
        n_in_agg++;
        if (min_cst > 0 && cost() < min_cst) break;
        if (min_err >= 0 && train_c_error() <= min_err) break;
        sample_wgt = update_smpwgt(*sample_wgt, *p);
    }
}

void Boosting::train_gd () {
    _boost_gd bgd(this);
    iterative_optimize(_line_search<_boost_gd,BoostWgt,REAL,REAL>
                       (&bgd, convex? 1.0 : 0.5));
}

pLearnModel Boosting::train_with_smpwgt (const pDataWgt& sw) const {
#if VERBOSE_OUTPUT
    std::cout << "=== " << id()
              << " [" << (convex? "convex" : "linear") << "] #"
              << n_in_agg+1 << " / " << max_n_model << " ===\n";
#endif
    LearnModel *plm = lm_base->clone();
    assert(plm != 0);

    plm->set_train_data(ptd, sw);
    plm->train();
    // put back ptd for future get_output() call, and put back ptw to
    // save memory -- however, plm has to support sample weight
    assert(plm->support_weighted_data());
    plm->set_train_data(ptd, ptw);
    return plm;
}

REAL Boosting::convex_weight (const DataWgt&, const LearnModel&) {
    OBJ_FUNC_UNDEFINED("convex_weight");
}
REAL Boosting::linear_weight (const DataWgt&, const LearnModel&) {
    OBJ_FUNC_UNDEFINED("linear_weight");
}

void Boosting::convex_smpwgt (DataWgt&) {
    OBJ_FUNC_UNDEFINED("convex_smpwgt");
}
void Boosting::linear_smpwgt (DataWgt&) {
    OBJ_FUNC_UNDEFINED("linear_smpwgt");
}

REAL Boosting::cost () const {
    assert(ptd != 0 && ptw != 0);
    REAL cst = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        REAL c = _cost(get_output(i), ptd->y(i));
        cst += c * (*ptw)[i];
    }
    return cst;
}

/** Compute weight (probability) vector according to
 *  @f[ D_i \propto -\frac{w_i}{y_i} c'_F (F(x_i), y_i) @f]
 *  @sa #cost_deriv_functor
 */
pDataWgt Boosting::sample_weight () const {
    assert(ptd != 0 && ptw != 0);
    if (n_in_agg == 0) return ptw;

    DataWgt* pdw = new DataWgt(n_samples);
    REAL sum = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        REAL yi = ptd->y(i)[0];
        REAL p = - (*ptw)[i] / yi * _cost_deriv(get_output(i), ptd->y(i));
        assert(p >= 0);
        (*pdw)[i] = p; sum += p;
    }
    assert(sum > 0);
    const REAL k = 1 / sum;
    for (UINT i = 0; i < n_samples; ++i)
        (*pdw)[i] *= k;

    return pdw;
}

Boosting::BoostWgt& Boosting::BoostWgt::operator+= (const BoostWgt& bw) {
    const UINT ts = size();
    assert(ts+1 == bw.size());

    for (UINT i = 0; i < ts; ++i) {
        assert(lm[i] == bw.lm[i]);
        lm_wgt[i] += bw.lm_wgt[i];
    }
    lm.push_back(bw.lm[ts]);
    lm_wgt.push_back(bw.lm_wgt[ts]);

    return *this;
}

Boosting::BoostWgt Boosting::BoostWgt::operator- () const {
    using namespace op;
    return BoostWgt(lm, -lm_wgt);
}

Boosting::BoostWgt& Boosting::BoostWgt::operator*= (REAL r) {
    using namespace op;
    lm_wgt *= r;
    return *this;
}

} // namespace lemga
