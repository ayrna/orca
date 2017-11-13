/** @file
 *  $Id: adaboost_erp.cpp 2637 2006-02-13 01:59:50Z ling $
 */

#include <assert.h>
#include "adaboost_erp.h"

REGISTER_CREATOR(lemga::AdaBoost_ERP);

namespace lemga {

bool AdaBoost_ERP::ECOC_partition (UINT i, ECOC_VECTOR& p) const {
    if (MultiClass_ECOC::ECOC_partition(i, p)) return true;
    const UINT n = 2; // (n_class() + 3) / 4;

    switch (par_method) {
    case RANDOM_2:
        p = random_half(n);
        break;

    case MAX_2:
        p = max_cut_greedy(n);
        break;

    default:
        return AdaBoost_ECOC::ECOC_partition(i, p);
    }

    return true;
}

pLearnModel
AdaBoost_ERP::train_with_partial_partition (const ECOC_VECTOR& p) const {
    LearnModel *plm = lm_base->clone();
    assert(plm != 0);

    // We will ignore examples with "color" p[] = 0.
    // The best way is to first group examples by their classes,
    // then each time collect classes with nonzero p.
    // We don't do this for easier modification for future changes,
    // e.g., if we want to allow continuous values of p[]
    DataSet* btd = new DataSet();
    DataWgt* btw = new DataWgt();
    REAL wsum = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        int y = p[ex_class[i]];
        if (y == 0) continue;

        btd->append(ptd->x(i), Output(1, y));
        REAL w = 0;
        for (UINT c = 0; c < nclass; ++c)
            if (p[c] + y == 0)
                w += joint_wgt[c][i];
        wsum += w; btw->push_back(w);
    }
    REAL r = 1 / wsum;
    for (UINT i = 0; i < btw->size(); ++i)
        (*btw)[i] *= r;

    plm->set_train_data(btd, btw);
    plm->train();
    return plm;
}

#define OUTPUT_PARTITION(p,o)                \
    for (UINT c = 0; c < p.size(); ++c)      \
        o << (p[c]>0? '+':(p[c]<0?'-':'0')); \
    o << std::flush

pLearnModel AdaBoost_ERP::train_with_partition (ECOC_VECTOR& p) const {
#if VERBOSE_OUTPUT
    std::cout << "    ";
    OUTPUT_PARTITION(p, std::cout);
#endif

    pLearnModel plm = 0;
    bool calc_smpwgt = true;
    UINT s = lrs;
    while (s--) {
        // learning
        assert(calc_smpwgt);
        if (is_full_partition(p)) {
            plm = train_with_full_partition(p); // cur_smpwgt is set
            calc_smpwgt = false;
        } else
            plm = train_with_partial_partition(p);
        assert(plm != 0);
#if VERBOSE_OUTPUT
        std::cout << " ... trained" << std::flush;
#endif

        // Put back the full training set and an arbitrary weight
        // to collect the outputs (in cur_err).
        // Note output 0 will be put as -1.
        plm->set_train_data(ptd, ptw);
        for (UINT i = 0; i < n_samples; ++i)
            cur_err[i] = (plm->get_output(i)[0] > 0);  // tmp use

        if (!(s--)) break;

        // re-partitioning
        std::vector<REAL> mkt(nclass, 0);
        for (UINT i = 0; i < n_samples; ++i) {
            UINT y = ex_class[i];
            int out = (cur_err[i]? 1 : -1);
            for (UINT c = 0; c < nclass; ++c) {
                const REAL jwo = joint_wgt[c][i] * out;
                mkt[c] += jwo; mkt[y] -= jwo;
            }
        }
        bool changed = false;
        for (UINT c = 0; c < nclass; ++c) {
            int np = (mkt[c]>0? -1 : 1);
            changed |= (np != p[c]);
            p[c] = np;
        }
#if VERBOSE_OUTPUT
        std::cout << "\n => ";
        if (changed) {
            OUTPUT_PARTITION(p, std::cout);
        } else
            std::cout << "NO CHANGE";
#endif

        if (!changed) break;
        calc_smpwgt = true;
    }
#if VERBOSE_OUTPUT
    std::cout << '\n';
#endif
    assert(is_full_partition(p) /* && cur_err == output of plm */);

    // Update the current error & sample weights
    for (UINT i = 0; i < n_samples; ++i)
        cur_err[i] = cur_err[i] ^ (p[ex_class[i]] > 0);
    if (calc_smpwgt)
        cur_smpwgt = smpwgt_with_partition(p);

    return plm;
}

} // namespace lemga
