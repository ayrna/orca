/** @file
 *  $Id: datafeeder.cpp 2563 2006-01-20 05:04:22Z ling $
 */

#include <assert.h>
#include <algorithm>
#include <cmath>
#include "random.h"
#include "datafeeder.h"

namespace lemga {

DataFeeder::DataFeeder (const pDataSet& pd)
    : dat(pd), perms(0), _do_normalize(MIN_MAX), tr_size(0), tr_flip(0) {
    fsize = dat->size();
}

DataFeeder::DataFeeder (std::istream& ds)
    : perms(0), _do_normalize(MIN_MAX), tr_size(0), tr_flip(0) {
    /* load all the data */
    dat = load_data(ds, (1L<<30)-1);
    fsize = dat->size();
}

void DataFeeder::set_train_size (UINT trn) {
    assert(trn < fsize);
    tr_size = trn;
}

void DataFeeder::set_train_noise (REAL p) {
    assert(p >= 0 && p <= 1);
    tr_flip = p;
}

bool DataFeeder::next_train_test (pDataSet& ptr, pDataSet& pte) const {
    DataSet *p_tr = new DataSet();
    DataSet *p_te = new DataSet();

    std::vector<UINT> perm;
    if (!next_permutation(perm)) return false;

    for (UINT i = 0; i < tr_size; ++i) {
        bool flip = (tr_flip > 0) && (randu() < tr_flip);
        if (!flip)
            p_tr->append(dat->x(perm[i]), dat->y(perm[i]));
        else {
            const Output& y = dat->y(perm[i]);
            assert(y.size() == 1 &&
                   std::fabs(std::fabs(y[0]) - 1) < INFINITESIMAL);
            p_tr->append(dat->x(perm[i]), Output(1, -y[0]));
        }
    }
    for (UINT i = tr_size; i < fsize; ++i)
        p_te->append(dat->x(perm[i]), dat->y(perm[i]));

    if (_do_normalize != NONE) {
        LINEAR_SCALE_PARAMS lsp;
        switch (_do_normalize) {
            case MIN_MAX:  lsp = min_max(*p_tr); break;
            case MEAN_VAR: lsp = mean_var(*p_tr); break;
            default:       assert(false);
        }
        linear_scale(*p_tr, lsp);
        linear_scale(*p_te, lsp);
    }

    ptr = p_tr; pte = p_te;
    return true;
}

bool DataFeeder::next_permutation (std::vector<UINT>& perm) const {
    perm.resize(fsize);

    if (perms == 0) {
        for (UINT i = 0; i < fsize; ++i)
            perm[i] = i;
        std::random_shuffle(perm.begin(), perm.end());
        return true;
    }

    std::vector<bool> visited(fsize, false);
    for (UINT i = 0; i < fsize; ++i) {
        UINT idx; // starting from 0
        if (!((*perms) >> idx)) {
            if (i) std::cerr << "DataFeeder: "
                "Permutation stream ends prematurely\n";
            return false;
        }
        if (idx >= fsize || visited[idx]) {
            std::cerr << "DataFeeder: "
                "Permutation stream has errors\n";
            return false;
        }
        visited[idx] = true;
        perm[i] = idx;
    }
    return true;
}

DataFeeder::LINEAR_SCALE_PARAMS DataFeeder::min_max (DataSet& d) {
    assert(d.size() > 0);

    const Input& x0 = d.x(0);
    const UINT ls = x0.size();
    std::vector<REAL> dmin(x0), dmax(x0);
    for (UINT i = 1; i < d.size(); ++i) {
        const Input& x = d.x(i);
        for (UINT j = 0; j < ls; ++j) {
            if (dmin[j] > x[j])
                dmin[j] = x[j];
            else if (dmax[j] < x[j])
                dmax[j] = x[j];
        }
    }

    LINEAR_SCALE_PARAMS l(ls);
    for (UINT j = 0; j < ls; ++j) {
        l[j].center = (dmin[j] + dmax[j]) / 2;
        if (dmin[j] != dmax[j])
            l[j].scale = 2 / (dmax[j] - dmin[j]);
        else
            l[j].scale = 0;
    }
    return l;
}

DataFeeder::LINEAR_SCALE_PARAMS DataFeeder::mean_var (DataSet& d) {
    const UINT n = d.size();
    assert(n > 0);
    const UINT ls = d.x(0).size();

    std::vector<REAL> sum1(ls, 0), sum2(ls, 0);
    for (UINT i = 0; i < n; ++i) {
        const Input& x = d.x(i);
        for (UINT j = 0; j < ls; ++j) {
            sum1[j] += x[j];
            sum2[j] += x[j] * x[j];
        }
    }

    LINEAR_SCALE_PARAMS l(ls);
    for (UINT j = 0; j < ls; ++j) {
        l[j].center = sum1[j] / n;
        REAL n_1_var = sum2[j] - sum1[j] * l[j].center;
        if (n_1_var > INFINITESIMAL)
            l[j].scale = std::sqrt((n-1) / n_1_var);
        else
            l[j].scale = 0;
    }
    return l;
}

void DataFeeder::linear_scale (DataSet& d, const LINEAR_SCALE_PARAMS& l) {
    const UINT ls = l.size();
    for (UINT i = 0; i < d.size(); ++i) {
        Input x = d.x(i);
        assert(x.size() == ls);
        for (UINT j = 0; j < ls; ++j)
            x[j] = (x[j] - l[j].center) * l[j].scale;
        d.replace(i, x, d.y(i));
    }
}

} // namespace lemga
