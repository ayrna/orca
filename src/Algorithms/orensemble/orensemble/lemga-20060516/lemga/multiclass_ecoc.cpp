/** @file
 *  $Id: multiclass_ecoc.cpp 2695 2006-04-05 05:21:47Z ling $
 */

#include <assert.h>
#include <cmath>
#include <algorithm>
#include <set>
#include "multiclass_ecoc.h"

REGISTER_CREATOR(lemga::MultiClass_ECOC);

#define LABEL_EQUAL(x,y)  (std::fabs((x)-(y)) < EPSILON)
// search y in the current class labels
#define LABEL2INDEX(y) \
    std::lower_bound(labels.begin(), labels.end(), y) - labels.begin()

namespace lemga {

bool MultiClass_ECOC::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(Aggregating, os, vl, 1);
    const UINT n = lm.size();

    assert(lm_wgt.size() == n);
    for (UINT i = 0; i < n; ++i)
        os << lm_wgt[i] << ' ';
    if (n) os << '\n';

    os << ecoc.size() << '\n';
    for (UINT i = 0; i < ecoc.size(); ++i) {
        assert(n <= ecoc[i].size());
        for (UINT j = 0; j < n; ++j)
            os << ecoc[i][j] << ' ';
        if (n) os << '\n';
    }

    os << nclass << '\n';
    assert(nclass == labels.size());
    for (UINT i = 0; i < nclass; ++i)
        os << labels[i] << ' ';
    if (nclass) os << '\n';
    return os;
}

bool
MultiClass_ECOC::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(Aggregating, is, vl, 1, v);

    const UINT n = lm.size();
    lm_wgt.resize(n);
    for (UINT i = 0; i < n; ++i)
        if (!(is >> lm_wgt[i])) return false;

    UINT c;
    if (!(is >> c)) return false;
    ecoc.resize(c);
    for (UINT i = 0; i < c; ++i) {
        ecoc[i].resize(n);
        for (UINT j = 0; j < n; ++j)
            if (!(is >> ecoc[i][j])) return false;
    }

    if (!(is >> nclass)) return false;
    labels.resize(nclass);
    for (UINT i = 0; i < nclass; ++i)
        if (!(is >> labels[i])) return false;

    return true;
}

void MultiClass_ECOC::set_ECOC_table (const ECOC_TABLE& e) {
    assert(!e.empty());
    ecoc = e;
    if (max_n_model == 0) // only set the max_n_model if it is 0
        set_max_models(ecoc[0].size());
}

void MultiClass_ECOC::set_ECOC_table (UINT i, const ECOC_VECTOR& p) {
    for (UINT c = 0; c < p.size(); ++c) {
        if (ecoc[c].size() <= i) {
            assert(ecoc[c].size() == i);
            ecoc[c].push_back(p[c]);
        }
        else ecoc[c][i] = p[c];
    }
}

void MultiClass_ECOC::set_ECOC_table (ECOC_TYPE et) {
    assert(et != NO_TYPE);
    if (nclass == 0) {   // data not loaded,
        ecoc_type = et;  // do this later in set_train_data()
        return;
    }

    ECOC_TABLE e;

    switch (et) {
    case ONE_VS_ONE: {
        UINT m = nclass*(nclass-1)/2;
        e = ECOC_TABLE(nclass, ECOC_VECTOR(m, 0));
        UINT k = 0;
        for (UINT i = 0; i < nclass; ++i)
            for (UINT j = i+1; j < nclass; ++j, ++k) {
                e[i][k] = 1; e[j][k] = -1;
            }
    }
        break;

    case ONE_VS_ALL:
        e = ECOC_TABLE(nclass, ECOC_VECTOR(nclass, -1));
        for (UINT i = 0; i < nclass; ++i)
            e[i][i] = 1;
        break;

    default:
        assert(false);
    }

    set_ECOC_table(e);
}

// the default one in LearnModel is not suitable for multiclass
REAL MultiClass_ECOC::c_error (const Output& out, const Output& y) const {
    assert(n_output() == 1);
    return !LABEL_EQUAL(out[0], y[0]);
}

void MultiClass_ECOC::reset () {
    Aggregating::reset();
    lm_wgt.clear();
    /// @todo Keep the initial ECOC settings
    ecoc.clear(); ecoc_type = NO_TYPE;
#if MULTICLASS_ECOC_OUTPUT_CACHE
    if (nclass > 0) clear_cache();
#endif
}

void MultiClass_ECOC::set_train_data (const pDataSet& pd,
                                      const pDataWgt& pw) {
    pDataSet old_ptd = ptd;
    Aggregating::set_train_data(pd, pw);
    if (old_ptd == ptd) {
        assert(ecoc_type == NO_TYPE);
        return;
    }

    std::set<REAL> ls;
    for (UINT i = 0; i < n_samples; ++i)
        ls.insert(ptd->y(i)[0]);

    // compare with the old label information
    std::vector<REAL> new_labels(ls.begin(), ls.end());
    if (nclass > 0) {
        bool same = (nclass == new_labels.size());
        for (UINT c = 0; same && c < nclass; ++c)
            same = LABEL_EQUAL(labels[c], new_labels[c]);
        if (!same)
            std::cerr << "MultiClass_ECOC: Warning: "
                "Class label mapping is changed\n";
    }

    // check whether labels are too close
    labels.swap(new_labels);
    nclass = labels.size();
    for (UINT c = 1; c < nclass; ++c)
        if (LABEL_EQUAL(labels[c-1], labels[c])) {
            std::cerr << "MultiClass_ECOC: Error: Labels ("
                      << labels[c-1] << " and " << labels[c]
                      << ") are too close. Alter LABEL_EQUAL?\n";
            std::exit(-1);
        }

    // fill ex_class
    ex_class.resize(n_samples);
    for (UINT i = 0; i < n_samples; ++i) {
        REAL y = ptd->y(i)[0];
        UINT c = LABEL2INDEX(y);
        assert(c < nclass && LABEL_EQUAL(y, labels[c]));
        ex_class[i] = c;
    }

    if (ecoc_type != NO_TYPE) {
        set_ECOC_table(ecoc_type);
        ecoc_type = NO_TYPE;
    } else
        ecoc.resize(nclass);
#if MULTICLASS_ECOC_OUTPUT_CACHE
    clear_cache();
#endif
    local_d.resize(nclass);
}

void MultiClass_ECOC::train () {
    assert(ptd != 0 && ptw != 0);
    assert(lm_base != 0); // we need lm_base to create new hypotheses
    assert(_n_out == 1);  // currently only deal with one output
    assert(nclass <= ecoc.size() && nclass == labels.size());

    // start learning from the current set of hypotheses
    n_in_agg = lm.size();
    assert(n_in_agg == lm_wgt.size());
    setup_aux();

    while (n_in_agg < max_n_model) {
        ECOC_VECTOR par;
        if (!ECOC_partition(n_in_agg, par)) break;
#if VERBOSE_OUTPUT
        std::cout << "*** " << id() << " #" << n_in_agg+1
                  << " / " << max_n_model << " ***\n";
#endif
        // train with this partition (the partition may be altered)
        const pLearnModel p = train_with_partition(par);
        // decide the coefficient
        const REAL w = assign_weight(par, *p);
        if (w <= 0) break;

        set_dimensions(*p);
        lm.push_back(p); lm_wgt.push_back(w);
        set_ECOC_table(n_in_agg, par);
        ++n_in_agg;
        update_aux(par);
    }
}

// find the closest class
#define GET_BEST_CLASS(distance_to_class_c)     \
    REAL dmin = INFINITY; UINT cmin = UINT(-1); \
    for (UINT c = 0; c < nclass; ++c) {         \
        REAL dc = distance_to_class_c;          \
        assert(dc < INFINITY/10);               \
        if (dc < dmin) { dmin = dc; cmin = c; } \
    }
#define GET_MARGIN(distance_to_class_c,y)       \
    REAL dy = 0, dmin = INFINITY;               \
    for (UINT c = 0; c < nclass; ++c) {         \
        REAL dc = distance_to_class_c;          \
        assert(dc < INFINITY/10);               \
        if (c == y) dy = dc;                    \
        else if (dc < dmin) dmin = dc;          \
    }

const std::vector<REAL>& MultiClass_ECOC::distances (const Input& x) const {
    assert(n_in_agg <= lm.size() && n_in_agg <= lm_wgt.size());
#ifndef NDEBUG
    for (UINT i = 0; i < n_in_agg; ++i)
        assert(lm_wgt[i] >= 0);
#endif

    assert(n_output() == 1);
    Output out(n_in_agg);
    for (UINT i = 0; i < n_in_agg; ++i) {
        assert(lm[i] != 0);
        out[i] = (*lm[i])(x)[0];
    }
    std::vector<REAL>& d = local_d;
    assert(d.size() == nclass);
    for (UINT c = 0; c < nclass; ++c)
        d[c] = ECOC_distance(out, ecoc[c]);
    return d;
}

const std::vector<REAL>& MultiClass_ECOC::distances (UINT idx) const {
#if MULTICLASS_ECOC_OUTPUT_CACHE == 2 // distance cache
    assert(cache_n.size() == n_samples);
    if (cache_n[idx] > n_in_agg)
        clear_cache(idx);
    std::vector<REAL>& d = cache_d[idx];
    assert(d.size() == nclass);
    for (UINT i = cache_n[idx]; i < n_in_agg; ++i) {
        REAL o = lm[i]->get_output(idx)[0];
        for (UINT c = 0; c < nclass; ++c)
            d[c] = ECOC_distance(o, ecoc[c][i], lm_wgt[i], d[c]);
    }
    cache_n[idx] = n_in_agg;
#else                                 // compute the output first
#if MULTICLASS_ECOC_OUTPUT_CACHE == 1
    assert(cache_o.size() == n_samples);
    Output& out = cache_o[idx];
    for (UINT i = out.size(); i < n_in_agg; ++i) {
        assert(lm[i] != 0);
        out.push_back(lm[i]->get_output(idx)[0]);
    }
#elif !MULTICLASS_ECOC_OUTPUT_CACHE
    Output out(n_in_agg);
    for (UINT i = 0; i < n_in_agg; ++i) {
        assert(lm[i] != 0);
        out[i] = lm[i]->get_output(idx)[0];
    }
#else
#error "Wrong value of MULTICLASS_ECOC_OUTPUT_CACHE"
#endif
    std::vector<REAL>& d = local_d;
    assert(d.size() == nclass);
    for (UINT c = 0; c < nclass; ++c)
        d[c] = ECOC_distance(out, ecoc[c]);
#endif
    return d;
}

Output MultiClass_ECOC::operator() (const Input& x) const {
    const std::vector<REAL>& d = distances(x);
    GET_BEST_CLASS(d[c]);
    return Output(1, labels[cmin]);
}

Output MultiClass_ECOC::get_output (UINT idx) const {
    assert(ptw != 0); // no data sampling
    assert(nclass <= ecoc.size() && nclass == labels.size());

    const std::vector<REAL>& d = distances(idx);
    GET_BEST_CLASS(d[c]);
    // Due to the instability of real number comparison, the
    // assertion below does not always hold. However, it holds if we
    // replace (dc < dmin) in GET_BEST_CLASS with (dc+EPSILON < dmin)
    //assert(LABEL_EQUAL(labels[cmin], (*this)(ptd->x(idx))[0]));
    return Output(1, labels[cmin]);
}

REAL MultiClass_ECOC::margin_of (const Input& x, const Output& l) const {
    UINT y = LABEL2INDEX(l[0]);
    assert(y < nclass && LABEL_EQUAL(l[0], labels[y]));
    const std::vector<REAL>& d = distances(x);
    GET_MARGIN(d[c], y);
    return dmin - dy;
}

REAL MultiClass_ECOC::margin (UINT idx) const {
    assert(ptw != 0); // no data sampling
    UINT y = ex_class[idx];

    const std::vector<REAL>& d = distances(idx);
    GET_MARGIN(d[c], y);
    return dmin - dy;
}

REAL MultiClass_ECOC::ECOC_distance (const Output& o,
                                     const ECOC_VECTOR& cw) const {
    assert(n_in_agg <= o.size() && n_in_agg <= cw.size());
    assert(n_in_agg <= lm_wgt.size());
    REAL ip = 0;
    for (UINT i = 0; i < n_in_agg; ++i)
        ip += lm_wgt[i] * (o[i]>0? -.5:.5) * cw[i];
    return ip;
}

#if MULTICLASS_ECOC_OUTPUT_CACHE == 2 // distance cache
REAL MultiClass_ECOC::ECOC_distance (REAL o, int cw, REAL w, REAL d) const {
    return d + w * (o>0? -.5:.5) * cw;
}
#endif

bool MultiClass_ECOC::is_full_partition (const ECOC_VECTOR& p) const {
    assert(p.size() == nclass);
    for (UINT c = 0; c < nclass; ++c)
        if (p[c] != -1 && p[c] != 1) return false;
    return true;
}

bool MultiClass_ECOC::ECOC_partition (UINT i, ECOC_VECTOR& p) const {
    assert(nclass <= ecoc.size());
    p.resize(nclass);
    for (UINT c = 0; c < nclass; ++c) {
        if (i >= ecoc[c].size()) return false;
        p[c] = ecoc[c][i];
    }
    return true;
}

pLearnModel MultiClass_ECOC::train_with_partition (ECOC_VECTOR& p) const {
    LearnModel *plm = lm_base->clone();
    assert(plm != 0);

    // generate the binary data
    DataSet* btd = new DataSet();
    DataWgt* btw = new DataWgt();
    REAL wsum = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        const Input& x = ptd->x(i);
        int b = p[ex_class[i]];
        if (b != 0) {
            assert(b == 1 || b == -1);
            btd->append(x, Output(1, b));
            btw->push_back((*ptw)[i]);
            wsum += (*ptw)[i];
        }
    }
    assert(wsum > 0);
    for (UINT i = 0; i < btw->size(); ++i)
        (*btw)[i] /= wsum;

    plm->set_train_data(btd, btw);
    plm->train();
    // To save some memory, we put back the original set and weight
    plm->set_train_data(ptd, ptw);
    return plm;
}

REAL MultiClass_ECOC::cost () const {
    assert(ptd != 0 && ptw != 0);
    REAL cst = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        const std::vector<REAL>& d = distances(i);
        const UINT y = ex_class[i];
        REAL dy = d[y], csti = 0;
        for (UINT c = 0; c < nclass; ++c)
            if (c != y) {
                csti += std::exp(dy - d[c]);
            }
        cst += (*ptw)[i] * csti;
    }
    return cst;
}

} // namespace lemga
