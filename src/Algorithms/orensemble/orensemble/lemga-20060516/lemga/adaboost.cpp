/** @file
 *  $Id: adaboost.cpp 2664 2006-03-07 19:50:51Z ling $
 */

#include <assert.h>
#include <cmath>
#include <iostream>
#include "adaboost.h"

REGISTER_CREATOR(lemga::AdaBoost);

namespace lemga {

void AdaBoost::train () {
    cur_err.resize(n_samples);
    Boosting::train();
    cur_err.clear();
}

REAL AdaBoost::linear_weight (const DataWgt& sw, const LearnModel& l) {
    assert(exact_dimensions(l));
    assert(l.train_data() == ptd);

    REAL err = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        if ((cur_err[i] = l.c_error(l.get_output(i), ptd->y(i))) > 0.1)
            err += sw[i];
    }
#if VERBOSE_OUTPUT
    std::cout << "Weighted classification error: " << err*100 << "%\n";
#endif

    if (err >= 0.5) return -1;

    REAL beta;
    if (err <= 0)
        beta = 1000;
    else
        beta = 1 / err - 1;
    return std::log(beta) / 2;
}

REAL AdaBoost::convex_weight (const DataWgt&, const LearnModel&) {
    std::cerr << "Please use the gradient descent methods for"
        " convex combinations\n";
    OBJ_FUNC_UNDEFINED("convex_weight");
}

/* We assume classification problem here. The density update rule is
 *      d <- d * e^(-w y f)
 * if y and f are binary, it is equivalent to say
 *      d <- d * beta for y != f, where beta = e^2w */
void AdaBoost::linear_smpwgt (DataWgt& sw) {
    const REAL beta = std::exp(2 * lm_wgt[n_in_agg-1]);
    REAL bw_sum = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        if (cur_err[i] > 0.1)
            sw[i] *= beta;
        bw_sum += sw[i];
    }

    assert(bw_sum != 0);
    for (UINT i = 0; i < n_samples; ++i)
        sw[i] /= bw_sum;
}

} // namespace lemga
