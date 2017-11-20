// -*- C++ -*-
#ifndef __LEMGA_AGGREGATING_MGNBOOST_H__
#define __LEMGA_AGGREGATING_MGNBOOST_H__

/** @file
 *  @brief Declare @link lemga::MgnBoost MgnBoost@endlink class.
 *
 *  $Id: mgnboost.h 2664 2006-03-07 19:50:51Z ling $
 */

#include "boosting.h"

namespace lemga {

/** @brief Cost proxy used in MgnBoost.
 *
 *  This class is a proxy to any other ``base'' cost functor. The
 *  minimal margin @f$\lambda@f$ is subtracted from the margin of
 *  each examples, and then the base cost functor is called.
 */
struct MgnCost : public cost::Cost {
    const cost::Cost& orig_cost;
    REAL lambda; ///< current minimal margin @f$\lambda@f$
    REAL wsum;   ///< current sum of weak learner weights

    MgnCost (const cost::Cost& c = cost::_cost)
        : orig_cost(c), lambda(0), wsum(0) {}
    virtual REAL cost (const REAL& F, const REAL& y) const {
        return orig_cost.cost(F - lambda*wsum/y, y);
    }
    virtual REAL deriv1 (const REAL& F, const REAL& y) const {
        return orig_cost.deriv1(F - lambda*wsum/y, y);
    }
};

/** @brief %MgnBoost (margin maximizing boosting).
 *
 *  %MgnBoost is an implementation of the arc-gv boosting algorithm
 *  [1]. We add a proxy MgnCost to modify any cost function, though
 *  arc-gv only uses the exponential cost (which is the default).
 *  (Thus the use of other cost functions is just experimental.) The
 *  minimal margin is updated only before the gradient calculation,
 *  but not during the line-search step. This is exactly how arc-gv
 *  works. I've tried updating the minimal margin also in the
 *  line-search step, but it didn't work well (minimal margin remains
 *  very negative).
 *
 *  [1] L. Breiman. Prediction games and arcing algorithms.
 *      <EM>Neural Computation</EM>, 11(7):1493-1517, 1999.
 */
class MgnBoost : public Boosting {
    friend struct _mgn_gd;
    MgnCost shifted_cost;
    void update_cost_l () { shifted_cost.lambda = min_margin()/margin_norm(); }
    void update_cost_w () { shifted_cost.wsum = model_weight_sum(); }

public:
    explicit MgnBoost (bool cvx = false, const cost::Cost& c = cost::_cost)
        : Boosting(cvx, shifted_cost), shifted_cost(c)
    { use_gradient_descent(); }
    explicit MgnBoost (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual MgnBoost* create () const { return new MgnBoost(); }
    virtual MgnBoost* clone () const { return new MgnBoost(*this); }

    virtual void train ();

protected:
    virtual void train_gd ();
};

struct _mgn_gd : public _boost_gd {
    MgnBoost* pm;
    explicit _mgn_gd (MgnBoost* p) : _boost_gd(p), pm(p) {}

    void set_weight (const Boosting::BoostWgt& bw) {
        _boost_gd::set_weight(bw);
        pm->update_cost_w();
    }

    Boosting::BoostWgt gradient () const {
        pm->update_cost_w(); pm->update_cost_l();
        return _boost_gd::gradient();
    }
};

} // namespace lemga

#ifdef  __MGNBOOST_H__
#warning "This header file may conflict with another `mgnboost.h' file."
#endif
#define __MGNBOOST_H__
#endif
