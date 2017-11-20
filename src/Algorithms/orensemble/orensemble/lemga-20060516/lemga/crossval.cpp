/** @file
 *  $Id: crossval.cpp 2664 2006-03-07 19:50:51Z ling $
 */

#include <algorithm>
#include "vectorop.h"
#include "random.h"
#include "crossval.h"

REGISTER_CREATOR2(lemga::vFoldCrossVal, vfold);
REGISTER_CREATOR2(lemga::HoldoutCrossVal, holdout);

namespace lemga {

CrossVal::CrossVal (const CrossVal& cv)
    : LearnModel(cv), fullset(cv.fullset), lm(cv.lm), err(cv.err),
      n_rounds(cv.n_rounds), best(cv.best)
{
    best_lm = 0;
    if (cv.best_lm != 0) {
        best_lm = cv.best_lm->clone();
        assert(best >= 0 && best_lm->id() == lm[best]->id());
    }
}

const CrossVal& CrossVal::operator= (const CrossVal& cv) {
    if (&cv == this) return *this;

    LearnModel::operator=(cv);
    fullset  = cv.fullset;
    lm       = cv.lm;
    err      = cv.err;
    n_rounds = cv.n_rounds;
    best     = cv.best;

    best_lm = 0;
    if (cv.best_lm != 0) {
        best_lm = cv.best_lm->clone();
        assert(best >= 0 && best_lm->id() == lm[best]->id());
    }

    return *this;
}

bool CrossVal::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(LearnModel, os, vl, 1);

    UINT n = size();
    if (!(os << n << ' ' << best << ' ' << (best_lm != 0) << '\n'))
        return false;
    for (UINT i = 0; i < n; ++i)
        if (!(os << *lm[i])) return false;
    for (UINT i = 0; i < n; ++i)
        if (!(os << err[i] << ' ')) return false;
    os << '\n';
    if (best_lm != 0) {
        assert(best >= 0 && best_lm->id() == lm[best]->id());
        if (!(os << *best_lm)) return false;
    }
    return (os << n_rounds << ' ' << fullset << '\n');
}

bool CrossVal::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    assert(d == NIL_ID);
    UNSERIALIZE_PARENT(LearnModel, is, vl, 1, v);
    assert(v > 0);

    UINT n;
    bool trained;
    if (!(is >> n >> best >> trained)) return false;
    if (best < -1 || best >= (int) n) return false;

    lm.clear(); err.resize(n);
    for (UINT i = 0; i < n; ++i) {
        LearnModel* p = (LearnModel*) Object::create(is);
        lm.push_back(p);
        if (p == 0 || !valid_dimensions(*p)) return false;
    }
    for (UINT i = 0; i < n; ++i)
        if (!(is >> err[i])) return false;

    best_lm = 0;
    if (trained) {
        LearnModel* p = (LearnModel*) Object::create(is);
        best_lm = p;
        if (p == 0 || !exact_dimensions(*p)) return false;
        if (best < 0 || p->id() != lm[best]->id()) return false;
    }

    return (is >> n_rounds >> fullset) && (n_rounds > 0);
}

void CrossVal::add_model (const LearnModel& l) {
    set_dimensions(l);
    lm.push_back(l.clone());
    err.push_back(-1);
}

void CrossVal::set_train_data (const pDataSet& pd, const pDataWgt& pw) {
    assert(pw == 0); // cannot deal with sample weights
    LearnModel::set_train_data(pd, 0);
    if (best_lm != 0) {
        assert(best >= 0 && best_lm->id() == lm[best]->id());
        best_lm->set_train_data(pd, 0);
    }
}

void CrossVal::train () {
    assert(n_rounds > 0 && ptd != 0 && ptw == 0);
    best_lm = 0;

    std::fill(err.begin(), err.end(), 0);
    using namespace op;
    for (UINT r = 0; r < n_rounds; ++r)
        err += cv_round();
    err *= 1 / (REAL) n_rounds;

    best = std::min_element(err.begin(), err.end()) - err.begin();
    if (fullset) {
        best_lm = lm[best]->clone();
        best_lm->initialize();
        best_lm->set_train_data(ptd);
        best_lm->train();
        set_dimensions(*best_lm);
    }
}

void CrossVal::reset () {
    LearnModel::reset();
    std::fill(err.begin(), err.end(), -1);
    best_lm = 0; best = -1;
}

bool vFoldCrossVal::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(CrossVal, os, vl, 1);
    return (os << n_folds << '\n');
}

bool
vFoldCrossVal::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(CrossVal, is, vl, 1, v);
    assert(v > 0);
    return (is >> n_folds) && (n_folds > 1);
}

std::vector<REAL> vFoldCrossVal::cv_round () const {
    assert(ptd != 0);
    UINT n = size(), ds = ptd->size();
    std::vector<REAL> cve(n, 0);

    // get a random index
    std::vector<UINT> perm(ds);
    for (UINT i = 0; i < ds; ++i) perm[i] = i;
    std::random_shuffle(perm.begin(), perm.end());

    UINT b, e = 0;
    for (UINT f = 1; f <= n_folds; ++f) {
        // [b,e) is the index range for the testing set
        b = e; e = f * ds / n_folds;
        assert(e-b == ds/n_folds || e-b == (ds+n_folds-1)/n_folds);

        // generate the training and testing sets
        DataSet *p_tr = new DataSet();
        DataSet *p_te = new DataSet();
        //! using perm[i] is bad for system cache
        for (UINT i = 0; i < b; ++i)
            p_tr->append(ptd->x(perm[i]), ptd->y(perm[i]));
        for (UINT i = b; i < e; ++i)
            p_te->append(ptd->x(perm[i]), ptd->y(perm[i]));
        for (UINT i = e; i < ds; ++i)
            p_tr->append(ptd->x(perm[i]), ptd->y(perm[i]));
        pDataSet ptr = p_tr, pte = p_te;

        // go over all candidates and collect the errors
        for (UINT i = 0; i < n; ++i) {
            pLearnModel p = lm[i]->clone();
            p->set_train_data(ptr);
            p->train();
            // which error to collect? let's assume classification error
            cve[i] += p->test_c_error(pte) * pte->size();
        }
    }
    using namespace op;
    cve *= 1 / (REAL) ds;

    return cve;
}

bool HoldoutCrossVal::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(CrossVal, os, vl, 1);
    return (os << p_test << '\n');
}

bool
HoldoutCrossVal::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(CrossVal, is, vl, 1, v);
    assert(v > 0);
    return (is >> p_test) && (p_test > 0 && p_test < 0.9);
}

std::vector<REAL> HoldoutCrossVal::cv_round () const {
    assert(ptd != 0);
    const UINT n = ptd->size();
    UINT k = UINT(n * p_test + 0.5); if (k < 1) k = 1;
    DataSet *p_tr = new DataSet();
    DataSet *p_te = new DataSet();

    // (n,k): choosing k examples from n ones.
    // To generate (n,k), we pick the 1st example with probability k/n,
    // and do (n-1,k-1) if the example is picked, or (n-1,k) if it is not.
    // Note: we may break out when k reaches 0 to save some randu() calls.
    for (UINT i = 0; i < n; ++i) {
        UINT toss = UINT(randu() * (n-i));
        assert(0 <= toss && toss < n-i);
        if (toss < k) {
            p_te->append(ptd->x(i), ptd->y(i));
            --k;
        } else
            p_tr->append(ptd->x(i), ptd->y(i));
    }
    assert(k == 0);

    pDataSet ptr = p_tr, pte = p_te;
    const UINT lms = size();
    std::vector<REAL> cve(lms);
    // go over all candidates and collect the errors
    for (UINT i = 0; i < lms; ++i) {
        pLearnModel p = lm[i]->clone();
        p->set_train_data(ptr);
        p->train();
        // which error to collect? let's assume classification error
        cve[i] = p->test_c_error(pte);
    }

    return cve;
}

} // namespace lemga
