/** @file
 *  $Id: cgboost.cpp 2664 2006-03-07 19:50:51Z ling $
 */

#include <assert.h>
#include <cmath>
#include "cgboost.h"
#include "vectorop.h"
#include "optimize.h"

/** The trained hypothesis f (with norm 1) is the real used search
 *  direction. One option is to replace cgd (d) by f everytime, while
 *  trying to keep the norm of d.
 */
#define USE_F_FOR_D  false

REGISTER_CREATOR(lemga::CGBoost);

namespace lemga {

void CGBoost::reset () {
    Boosting::reset();
    all_wgts.clear();
}

bool CGBoost::set_aggregation_size (UINT n) {
    if (grad_desc_view) {
        assert(size() == all_wgts.size() || size()+1 == all_wgts.size());
        if (n > all_wgts.size()) return false;
        if (n > 0) lm_wgt = all_wgts[n-1];
#if BOOSTING_OUTPUT_CACHE
        clear_cache();
#endif
    }
    return Boosting::set_aggregation_size(n);
}

bool CGBoost::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(Boosting, os, vl, 1);
    if (grad_desc_view) {
        const UINT n = size();
        assert(n == all_wgts.size() || n+1 == all_wgts.size());
        if (!(os << n << '\n')) return false;
        for (UINT i = 0; i+1 < n; ++i) {  // Boosting saved the last one
            assert(all_wgts[i].size() == i+1);
            for (UINT j = 0; j <= i; ++j)
                if (!(os << all_wgts[i][j] << ' ')) return false;
            if (!(os << '\n')) return false;
        }
        return true;
    }
    else
        return (os << 0 << '\n');
}

bool CGBoost::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(Boosting, is, vl, 1, v);
    assert(v > 0);

    UINT n;
    if (!(is >> n)) return false;
    if (n > 0 && n != size()) return false;

    if (n == 0 && size() > 0)
        use_gradient_descent(false);

    if (n > 0) {
        use_gradient_descent(true);
        all_wgts.clear();
        for (UINT i = 1; i < n; ++i) {
            std::vector<REAL> wgt(i);
            for (UINT j = 0; j < i; ++j)
                if (!(is >> wgt[j])) return false;
            all_wgts.push_back(wgt);
        }
        all_wgts.push_back(lm_wgt);
    }

    return true;
}

void CGBoost::train () {
    if (!grad_desc_view) {
        using namespace op;
        ncd = *ptw; ncd *= n_samples; // optional, make numbers not too small
        cgd = ncd;
        cur_err.resize(n_samples);
    }

    Boosting::train();

    cur_err.clear();
    ncd.clear(); cgd.clear();
}

void CGBoost::train_gd () {
    _boost_cg bcg(this);
    iterative_optimize(_conjugate_gradient<_boost_cg,BoostWgt,REAL,REAL>
                       (&bcg, convex? 1 : 0.5));
}

/** @note The sample weight (probability) used in training a new
 *  hypothesis is no longer same as the one for calculating the
 *  step length, which is exactly the gradient. We have to recover
 *  the gradient from CGBoost::ncd.
 */
REAL CGBoost::linear_weight (const DataWgt&, const LearnModel& l) {
    assert(exact_dimensions(l));
    assert(l.train_data() == ptd);

    REAL cor = 0, err = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        assert(ncd[i] >= 0);
        cur_err[i] = l.c_error(l.get_output(i), ptd->y(i));
        if (cur_err[i] > 0.1)
            err += ncd[i];
        else cor += ncd[i];
    }
    assert(err+cor > 0);
#if VERBOSE_OUTPUT
    std::cout << "?Weighted classification error: " <<
        err/(err+cor)*100 << "%%\n";
#endif

    if (err >= cor) return -1;

    REAL beta;
    if (err <= 0)
        beta = 1000;
    else
        beta = cor / err;
    return std::log(beta) / 2;
}

/** ncd is actually
 *  @f[ -g/y_i = -\frac{w_i}{y_i} c'_F(F(x_i),y_i) = w_i e^{-y_iF(x_i)} @f]
 *  It can be iteratively computed as
 *  @f[ ncd_i \leftarrow ncd_i \cdot e^{-\alpha y_i f(x_i)} @f]
 */
void CGBoost::linear_smpwgt (DataWgt& sw) {
    // update ratio (\beta) for error and correct samples
    const REAL be = std::exp(lm_wgt[n_in_agg-1]), bc = 1 / be;
    REAL s1 = 0, s2 = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        const REAL tmp = ncd[i] * (cur_err[i]? be : bc);
        s1 += tmp * (tmp - ncd[i]);
        s2 += ncd[i] * ncd[i];
        ncd[i] = tmp;
        assert(fabs(ncd[i] - n_samples * (*ptw)[i] *
                    std::exp(- ptd->y(i)[0]*get_output(i)[0])) < EPSILON);
    }
    assert(s2 != 0);
    REAL beta = s1 / s2;
    if (beta < 0) beta = 0;

#if USE_F_FOR_D
    /* Compute the norm ratio between d and f, which will mutiply
     * f so as to keep the correct norm. */
    REAL d2_sum = 0;
    for (UINT i = 0; i < n_samples; i++)
        d2_sum += cgd[i] * cgd[i];
    const REAL cf_ratio = std::sqrt(d2_sum / n_samples);
#if VERBOSE_OUTPUT
    std::cout << "cf_ratio = " << cf_ratio << ", ";
#endif
#endif

    REAL bw_sum = 0;
    for (UINT i = 0; i < n_samples; ++i) {
#if USE_F_FOR_D
        /* if we want to use f insted of cgd */
        cgd[i] = (cur_err[i] > 0.1)? -cf_ratio : cf_ratio;
#endif
        cgd[i] = ncd[i] + beta * cgd[i];
        bw_sum += cgd[i];
    }
#if VERBOSE_OUTPUT
    std::cout << "beta = " << beta << '\n';
#endif

    assert(bw_sum != 0);
    for (UINT i = 0; i < n_samples; ++i) {
        sw[i] = cgd[i] / bw_sum;
        assert(sw[i] >= 0);
    }
}

} // namespace lemga
