/** @file
 *  $Id: lpboost.cpp 2664 2006-03-07 19:50:51Z ling $
 */

#include <assert.h>
#include <cmath>
#include <iostream>
#include "lpboost.h"
extern "C"{
#include <glpk.h>
}

REGISTER_CREATOR(lemga::LPBoost);

namespace lemga {

#define U(i) ((i)+1)  //U(0) to U(n_samples-1)
#define R(t) ((t)+1)  //R(0) to R(T-1)

// Compute the weighted training error, and
// Add one more constraint R(t) = -sum u_i y_i h_t(x_i) >= -1
bool lp_add_hypothesis (LPX* lp, int* ndx, double* val, const LearnModel& lm,
                        const pDataWgt& pdw = 0, REAL maxe = 0)
{
    const pDataSet ptd = lm.train_data();
    assert(ptd != 0);
    const UINT n = ptd->size();
    assert(pdw == 0 || pdw->size() == n);

    REAL err = 0;
    for (UINT i = 0; i < n; ++i) {
        bool e = (lm.c_error(lm.get_output(i), ptd->y(i)) > 0.1);
        if (e && pdw) err += (*pdw)[i];
        ndx[i+1] = U(i);
        val[i+1] = e? 1 : -1; // "discretize" the base learner to -1/1
    }
    if (err >= maxe && pdw) // Cannot find better hypotheses
        return false;

    lpx_add_rows(lp, 1);
    int Rt = lpx_get_num_rows(lp);
    lpx_set_mat_row(lp, Rt, n, ndx, val);
    lpx_set_row_bnds(lp, Rt, LPX_LO, -1.0, 0.0);  // R(t) >= -1

    return true;
}

// return the negative objective, sum of u
REAL lp_solve (LPX* lp, pDataWgt& pdw) {
    lpx_simplex(lp);
    REAL sumu = -lpx_get_obj_val(lp);

    // get the new sample weights
    UINT n = lpx_get_num_cols(lp);
    DataWgt* sample_wgt = new DataWgt(n);
    for (UINT i = 0; i < n; ++i) {
        double wgt = lpx_get_col_prim(lp, U(i));
        assert(wgt >= -EPSILON);
        if (wgt < 0) wgt = 0;
        (*sample_wgt)[i] = wgt / sumu;
    }
    pdw = sample_wgt;
    return sumu;
}

void LPBoost::train () {
    assert(ptd != 0 && ptw != 0);
    assert(lm_base != 0); // we need lm_base to create new hypotheses
    assert(!grad_desc_view);
    set_dimensions(*ptd);

    // Construct inner problem
    LPX* lp = lpx_create_prob();
    lpx_add_cols(lp, n_samples);                        // u_i
    for (UINT i = 0; i < n_samples; ++i) {
        lpx_set_col_bnds(lp, U(i), LPX_DB, 0.0,
                         RegC * (*ptw)[i] * n_samples); // 0 <= u_i <= C_i
        lpx_set_obj_coef(lp, U(i), -1);                 // obj: -sum u_i
    }
    lpx_set_obj_dir(lp, LPX_MIN);                       // min obj

    int* ndx = new int[n_samples+1]; double* val = new double[n_samples+1];

    // adding existing hypotheses
    for (UINT t = 0; t < size(); ++t) {
        const pLearnModel p = lm[t];
        assert(p->train_data() == ptd);
        lp_add_hypothesis(lp, ndx, val, *p);
    }
    n_in_agg = size();

    REAL sumu = RegC * n_samples; // the largest possible sum of u
    pDataWgt pdw = ptw;
    for (UINT t = n_in_agg; t < max_n_model; ++t) {
        if (t > 0)
            sumu = lp_solve(lp, pdw);
        if (sumu < EPSILON) { // we do not expect this to happen
            std::cerr << "Warning: sum u is " << sumu << "; quit earlier.\n";
            break;
        }
        REAL besterr = (1 - 1 / sumu) / 2;

        const pLearnModel p = train_with_smpwgt(pdw);
        assert(p->train_data() == ptd);
        if (!lp_add_hypothesis(lp, ndx, val, *p, pdw, besterr-EPSILON))
            break;

        set_dimensions(*p);
        lm.push_back(p); lm_wgt.push_back(0);
        ++n_in_agg;
    }

    lpx_simplex(lp);

    // Update hypothesis coefficients
    assert((UINT) lpx_get_num_rows(lp) == R(n_in_agg-1));
    for (UINT k = 0; k < n_in_agg; ++k) {
        lm_wgt[k] = lpx_get_row_dual(lp, R(k));
        assert(lm_wgt[k] > -EPSILON);
        if (lm_wgt[k] < 0) lm_wgt[k] = 0;
    }

    delete[] ndx; delete[] val;
    lpx_delete_prob(lp);
}

} // namespace lemga
