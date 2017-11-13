/** @file
 *  $Id: adaboost_ecoc.cpp 2695 2006-04-05 05:21:47Z ling $
 */

#include <algorithm>
#include <assert.h>
#include <cmath>
#include <map>
#include "random.h"
#include "utility.h"
#include "vectorop.h"
#include "adaboost_ecoc.h"

REGISTER_CREATOR(lemga::AdaBoost_ECOC);

namespace lemga {

void AdaBoost_ECOC::setup_aux () {
    joint_wgt = JointWgt(n_class(), *ptw);
    // to facilitate the normalization in update_aux(),
    // we explicitly set joint_wgt[y_i][i] to zero
    for (UINT i = 0; i < n_samples; ++i)
        joint_wgt[ex_class[i]][i] = 0;
    cur_err.resize(n_samples);
    if (n_in_agg == 0) return;

    REAL wsum = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        const std::vector<REAL>& d = distances(i);
        UINT y = ex_class[i];
        for (UINT c = 0; c < nclass; ++c) {
            joint_wgt[c][i] *= std::exp(d[y] - d[c]);
            wsum += joint_wgt[c][i];
        }
    }
    REAL r = nclass / wsum;
    if (r > 1e-5 && r < 1e5) return;
    using namespace op;
    joint_wgt *= r; // normalize
}

typedef std::vector<std::vector<REAL> > WMAT;
static REAL binary_cut (const WMAT& w, const ECOC_VECTOR& p) {
    const UINT n = p.size();
    assert(w.size() == n);
    REAL c = 0;
    for (UINT i = 0; i < n; ++i) {
        assert(w[i].size() == n);
        for (UINT j = 0; j < i; ++j) {
            assert(w[i][j] == w[j][i]);
            if (p[i] != p[j])
                c += w[i][j];
        }
    }
    return c;
}

// compute the edge weight
WMAT AdaBoost_ECOC::confusion_matrix () const {
    WMAT w(nclass, std::vector<REAL>(nclass, 0));
    for (UINT j = 0; j < n_samples; ++j) {
        int y = ex_class[j];
        for (UINT c = 0; c < nclass; ++c)
            w[y][c] += joint_wgt[c][j];
    }
    for (UINT c = 0; c < nclass; ++c)
        for (UINT y = 0; y < c; ++y)
            w[y][c] = w[c][y] = w[y][c] + w[c][y];
    return w;
}

/// test all combinations to find out the max-cut
ECOC_VECTOR AdaBoost_ECOC::max_cut (UINT nr) const {
    assert(nr == nclass);
    if (nclass > 13)
        std::cerr << "Warning: Max-cut is very slow for too many classes\n";
    WMAT ewgt = confusion_matrix();
    for (UINT c = 0; c < nclass; ++c)
        assert(ewgt[c][c] == 0); // needed for the max-cut below

    ECOC_VECTOR maxp, p(nclass, 0);
    REAL maxc = 0, cut = 0;
    size_t flip = 0;
    while (gray_next(p, flip), flip != 0) { // p[0] will be fixed at 0
        for (UINT c = 0; c < nclass; ++c)
            if (p[c] == p[flip])
                cut -= ewgt[c][flip];
            else
                cut += ewgt[c][flip];
        if (maxc < cut) {
            maxp = p; maxc = cut;
        }
    }
    for (UINT c = 0; c < nclass; ++c)
        if (maxp[c] == 0) maxp[c] = -1;
    assert(std::fabs(maxc - binary_cut(ewgt, maxp)) < EPSILON);
    return maxp;
}

/// nr (or nr+1) is the maximal # of classes that can be "colored"
ECOC_VECTOR AdaBoost_ECOC::max_cut_greedy (UINT nr) const {
    assert(nr <= nclass);
    WMAT ewgt = confusion_matrix();

    // we could use O(n^2 log(K)) to find the first K edges with largest
    // weights. Here we just use O(n^2 log(n^2)).
    typedef std::multimap<REAL,UINT> MMAP;
    MMAP edge;
    for (UINT j = 1; j < nclass; ++j)
        for (UINT c = 0; c+j < nclass; ++c) {
            UINT y = c + j;
            edge.insert(std::pair<REAL,UINT>(-ewgt[y][c], c*nclass+y));
        }

    ECOC_VECTOR p(nclass, 0);
    UINT pn = 0;
    for (MMAP::iterator pe = edge.begin(); pn < nr && pe != edge.end(); ++pe) {
        UINT k1 = pe->second / nclass, k2 = pe->second % nclass;
        if (randu() < 0.5) std::swap(k1, k2); // not really useful
        if (p[k1] == 0 && p[k2] == 0) {
            p[k1] = 1; p[k2] = -1;
            pn += 2;
        } else if (p[k1] == 0) {
            p[k1] = -p[k2];
            ++pn;
        } else if (p[k2] == 0) {
            p[k2] = -p[k1];
            ++pn;
        }
    }

    return p;
}

ECOC_VECTOR AdaBoost_ECOC::random_half (UINT nr) const {
    assert(nr <= nclass);
    ECOC_VECTOR p(nclass, 0);

    // If nr == n, setting p to be all 1's and then randomly
    // flipping half of p should be the fastest approach.
    std::vector<UINT> idx(nclass);
    for (UINT i = 0; i < nclass; ++i)
        idx[i] = i;
    std::random_shuffle(idx.begin(), idx.end());
    while (nr--)
        p[idx[nr]] = (nr % 2)? 1 : -1;

    return p;
}

bool AdaBoost_ECOC::ECOC_partition (UINT i, ECOC_VECTOR& p) const {
    if (MultiClass_ECOC::ECOC_partition(i, p)) return true;
    const UINT n = n_class();

    switch (par_method) {
    case RANDOM_HALF:
        p = random_half(n);
        break;

    case MAX_CUT:
        p = max_cut(n);
        break;

    case MAX_CUT_GREEDY:
        p = max_cut_greedy(n);
        break;

    default:
        assert(false);
    }

    return true;
}

pDataWgt AdaBoost_ECOC::smpwgt_with_partition (const ECOC_VECTOR& p) const {
    assert(is_full_partition(p));
    DataWgt* btw = new DataWgt(n_samples);
    REAL wsum = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        int y = p[ex_class[i]];
        REAL w = 0;
        for (UINT c = 0; c < n_class(); ++c)
            if (p[c] + y == 0)
                w += joint_wgt[c][i];
        wsum += w; (*btw)[i] = w;
    }
    REAL r = 1 / wsum;
    for (UINT i = 0; i < n_samples; ++i)
        (*btw)[i] *= r;
    return btw;
}

pLearnModel
AdaBoost_ECOC::train_with_full_partition (const ECOC_VECTOR& p) const {
    LearnModel *plm = lm_base->clone();
    assert(plm != 0);

    DataSet* btd = new DataSet();
    for (UINT i = 0; i < n_samples; ++i)
        btd->append(ptd->x(i), Output(1, p[ex_class[i]]));
    cur_smpwgt = smpwgt_with_partition(p); // saved for future use

    plm->set_train_data(btd, cur_smpwgt);
    plm->train();
    return plm;
}

pLearnModel AdaBoost_ECOC::train_with_partition (ECOC_VECTOR& p) const {
    assert(is_full_partition(p));
    pLearnModel plm = train_with_full_partition(p);
    // Put back the full training set and an arbitrary weight
    plm->set_train_data(ptd, ptw);
    for (UINT i = 0; i < n_samples; ++i)
        cur_err[i] = (plm->get_output(i)[0] * p[ex_class[i]] <= 0);
    return plm;
}

REAL
AdaBoost_ECOC::assign_weight (const ECOC_VECTOR&, const LearnModel&) const {
    const DataWgt& sw = *cur_smpwgt;
    REAL err = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        if (cur_err[i])
            err += sw[i];
    }
    if (err >= 0.5) return -1;

    REAL beta;
    if (err <= 0)
        beta = 1000;
    else
        beta = 1/err - 1;
    return std::log(beta) / 2;
}

void AdaBoost_ECOC::update_aux (const ECOC_VECTOR& p) {
    assert(is_full_partition(p));
    const REAL beta = std::exp(lm_wgt[n_in_agg-1]);
    const REAL ibeta = 1 / beta;

    REAL wsum = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        int y = p[ex_class[i]];
        REAL r = (cur_err[i]? beta : ibeta);
        for (UINT c = 0; c < nclass; ++c) {
            if (p[c] != y)
                joint_wgt[c][i] *= r;
            wsum += joint_wgt[c][i];
        }
    }
    REAL r = nclass / wsum;
    if (r > 1e-5 && r < 1e5) return;
    using namespace op;
    joint_wgt *= r; // normalize
}

} // namespace lemga
