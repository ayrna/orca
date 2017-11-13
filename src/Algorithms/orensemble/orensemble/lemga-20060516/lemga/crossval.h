// -*- C++ -*-
#ifndef __LEMGA_CROSSVAL_H__
#define __LEMGA_CROSSVAL_H__

/** @file
 *  @brief Declare @link lemga::CrossVal Cross-Validation@endlink classes.
 *
 *  $Id: crossval.h 2664 2006-03-07 19:50:51Z ling $
 */

#include <assert.h>
#include "shared_ptr.h"
#include "learnmodel.h"

namespace lemga {

/** @brief A combination of cross-validation and model selection.
 *
 *  @note The interface is experimental. Say, it might be under LearnModel.
 */
class CrossVal : public LearnModel {
protected:
    bool fullset;                ///< train the best model on the full set?
    std::vector<pcLearnModel> lm;///< all candidate models
    std::vector<REAL> err;       ///< cross-validation errors
    UINT n_rounds;               ///< # of CV rounds, to beat the variance
    pLearnModel best_lm;         ///< the best model (trained on the full set)
    int best;                    ///< @a best_lm was actually @a lm[best]
    ///< @note Before cross-validation, best is -1. After, lm[best] is the
    ///< best model. If full-training is required, best_lm is then assigned.

public:
    CrossVal () : fullset(true), n_rounds(1), best(-1) {}
    CrossVal (const CrossVal&);
    const CrossVal& operator= (const CrossVal&);

    virtual CrossVal* create () const = 0;
    virtual CrossVal* clone () const = 0;

    /// add a candidate model to be cross-validated
    void add_model (const LearnModel&);
    /// the number of candidate models under cross-validation
    UINT size () const { assert(lm.size() == err.size()); return lm.size(); }
    /// the n-th candidate model
    const LearnModel& model (UINT n) const {
        assert(n < size() && lm[n] != 0); return *lm[n]; }

    /// how many rounds of cross-validation?
    UINT rounds () const { return n_rounds; }
    /// specifiy the number of rounds of cross-validation
    void set_rounds (UINT r) { assert(r > 0); n_rounds = r; }
    /// train the best model on the full set?
    bool full_train () const { return fullset; }
    void set_full_train (bool f = true) { fullset = f; }

    virtual void set_train_data (const pDataSet&, const pDataWgt& = 0);
    virtual void train ();
    virtual void reset ();
    virtual Output operator() (const Input& x) const {
        assert(best >= 0 && best_lm != 0);
        return (*best_lm)(x); }
    virtual Output get_output (UINT i) const {
        assert(best >= 0 && best_lm != 0 && ptd == best_lm->train_data());
        return best_lm->get_output(i); }
    virtual REAL margin_norm () const {
        assert(best >= 0 && best_lm != 0);
        return best_lm->margin_norm(); }
    virtual REAL margin_of (const Input& x, const Output& y) const {
        assert(best >= 0 && best_lm != 0);
        return best_lm->margin_of(x, y); }
    virtual REAL margin (UINT i) const {
        assert(best >= 0 && best_lm != 0 && ptd == best_lm->train_data());
        return best_lm->margin(i); }

    /// the cross-validation error of the n-th candidate model
    REAL error (UINT n) const {
        assert(n < size() && err[n] >= 0); return err[n]; }
    /// the best model (trained if full_train() == true)
    const LearnModel& best_model () const {
        assert(best >= 0);
        return best_lm? *best_lm : *lm[best]; }

protected:
    /// one round of the cross-validation operation
    virtual std::vector<REAL> cv_round () const = 0;

    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

/// v-fold cross validation.
class vFoldCrossVal : public CrossVal {
public:
    vFoldCrossVal (UINT v = 10, UINT r = 0) { set_folds(v, r); }
    explicit vFoldCrossVal (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual vFoldCrossVal* create () const { return new vFoldCrossVal(); }
    virtual vFoldCrossVal* clone () const { return new vFoldCrossVal(*this); }

    UINT folds () const { return n_folds; }
    /// set the folds and optionally also set the number of rounds
    void set_folds (UINT v, UINT r = 0) {
        assert(v > 1); n_folds = v;
        if (r > 0) set_rounds(r);
    }

protected:
    UINT n_folds;
    virtual std::vector<REAL> cv_round () const;

    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};
typedef vFoldCrossVal kFoldCrossVal;

/// Randomized holdout cross-validation.
class HoldoutCrossVal : public CrossVal {
public:
    HoldoutCrossVal (REAL p = 1.0/6, UINT r = 0) { set_holdout(p, r); }
    explicit HoldoutCrossVal (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual HoldoutCrossVal* create () const { return new HoldoutCrossVal(); }
    virtual HoldoutCrossVal* clone () const {
        return new HoldoutCrossVal(*this); }

    REAL holdout () const { return p_test; }
    /// set the holdout portion and optionally set the number of rounds
    void set_holdout (REAL p, UINT r = 0) {
        assert(p > 0 && p < 0.9); p_test = p;
        if (r > 0) set_rounds(r);
    }

protected:
    REAL p_test;
    virtual std::vector<REAL> cv_round () const;

    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

} // namespace lemga

#ifdef  __CROSSVAL_H__
#warning "This header file may conflict with another `crossval.h' file."
#endif
#define __CROSSVAL_H__
#endif
