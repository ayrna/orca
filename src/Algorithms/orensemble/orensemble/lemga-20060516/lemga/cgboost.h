// -*- C++ -*-
#ifndef __LEMGA_AGGREGATING_CGBOOST_H__
#define __LEMGA_AGGREGATING_CGBOOST_H__

/** @file
 *  @brief Declare @link lemga::CGBoost CGBoost@endlink class.
 *
 *  $Id: cgboost.h 2696 2006-04-05 20:10:13Z ling $
 */

#include "boosting.h"

namespace lemga {

struct _boost_cg;

/** @brief %CGBoost (Conjugate Gradient Boosting).
 *
 *  This class provides two ways to implement the conjugate gradient
 *  idea in the Boosting frame.
 *
 *  The first way is to manipulate the sample weight.
 *
 *  The other way is to adjust the projected search direction @a f.
 *  The adjusted direction is also a linear combination of weak learners.
 *  We prefer this way (by @c use_gradient_descent(true)).
 *
 *  Differences between AdaBoost and CGBoost (gradient descent view):
 *  -  The weights of all hypotheses (CGBoost), instead of only the
 *     weight of the newly added hypothesis (AdaBoost), will be updated
 *     during one iteration. Thus in order to ``set_aggregation_size()''
 *     correctly, we have to save weights in every iteration.
 *
 *  @todo Documentation
 */
class CGBoost : public Boosting {
    std::vector<std::vector<REAL> > all_wgts;
    friend struct _boost_cg;

protected:
    /* only valid within training */
    std::vector<REAL> ncd,  //!< @f$-g/y_i@f$ where @f$g=\nabla C(F)@f$
        cgd;  //!< @f$d/y_i@f$ where @f$d=-g+\beta d_{\mathrm{prev}}@f$

public:
    explicit CGBoost (bool cvx = false, const cost::Cost& c = cost::_cost)
        : Boosting(cvx, c) {}
    CGBoost (const Boosting& s) : Boosting(s) {
        const std::vector<REAL>::const_iterator b = lm_wgt.begin();
        for (UINT i = 1; i <= lm_wgt.size(); ++i)
            all_wgts.push_back(std::vector<REAL>(b, b+i));
    }
    explicit CGBoost (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual CGBoost* create () const { return new CGBoost(); }
    virtual CGBoost* clone () const { return new CGBoost(*this); }

    virtual bool set_aggregation_size (UINT);
    virtual void train ();
    virtual void reset ();

protected:
    /// data only valid within training (remove?)
    std::vector<REAL> cur_err;

    virtual void train_gd ();
    virtual REAL linear_weight (const DataWgt&, const LearnModel&);
    virtual void linear_smpwgt (DataWgt&);

    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

struct _boost_cg : public _boost_gd {
    CGBoost* cg;
    _boost_cg (CGBoost* pc) : _boost_gd(pc), cg(pc) {}

    void set_weight (const Boosting::BoostWgt& bw) const {
        _boost_gd::set_weight(bw);
        assert(cg->n_in_agg == bw.size() && cg->n_in_agg == cg->lm_wgt.size());

        // save weights to all_wgts
        if (cg->n_in_agg == 0) return;
        const UINT n = cg->n_in_agg - 1;
        if (n < cg->all_wgts.size())
            cg->all_wgts[n] = cg->lm_wgt;
        else {
            assert(n == cg->all_wgts.size()); // allow size inc <= 1
            cg->all_wgts.push_back(cg->lm_wgt);
        }
    }
};

} // namespace lemga

#ifdef  __CGBOOST_H__
#warning "This header file may conflict with another `cgboost.h' file."
#endif
#define __CGBOOST_H__
#endif
