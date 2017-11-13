// -*- C++ -*-
#ifndef __LEMGA_AGGREGATING_LPBOOST_H__
#define __LEMGA_AGGREGATING_LPBOOST_H__

/** @file
 *  @brief Declare @link lemga::LPBoost LPBoost@endlink class.
 *
 *  $Id: lpboost.h 2696 2006-04-05 20:10:13Z ling $
 */

#include <assert.h>
#include "boosting.h"

namespace lemga {

/** @brief %LPBoost (Linear-Programming %Boosting).
 *
 *  With a similar idea to the original %LPBoost [1], which solves
 *  \f{eqnarray*}
 *          \min && -\rho + D \sum_i \xi_i \\
 *  \textrm{s.t.}&& y_i\left(\sum_t\alpha_t h_t(x_i)\right)\ge \rho-\xi_i, \\
 *               && \xi_i\ge 0, \quad \alpha_t\ge 0, \quad \sum_t\alpha_t=1.
 *  \f}
 *  we instead implement the algorithm to solve
 *  \f{eqnarray*}
 *          \min && \sum_t \alpha_t + C \sum_i \xi_i \\
 *  \textrm{s.t.}&& y_i \left(\sum_t \alpha_t h_t(x_i)\right) \ge 1 - \xi_i,\\
 *               && \xi_i \ge 0, \quad \alpha_t \ge 0.
 *  \f}
 *  by column generation. Note that the dual problem is
 *  \f{eqnarray*}
 *          \max && \sum_i u_i \\
 *  \textrm{s.t.}&& \sum_i u_i y_i h_t(x_i) \le 1, \qquad (*)\\
 *               && 0 \le u_i \le C.
 *  \f}
 *  Column generation corresponds to generating the constraints (*).
 *  We actually use individual upper bound @f$C_i@f$ proportional to
 *  example's initial weight.
 *
 *  If we treat @f$w_i@f$, the normalized version of @f$u_i@f$, as the
 *  sample weight, and @f$\Sigma_u = \sum_i u_i@f$ as the normalization
 *  constraint, (*) is the same as
 *     @f[ \Sigma_u (1 - 2 e(h_t, w)) \le 1, @f]
 *  which means
 *     @f[ e(h_t, w) \ge \frac12 (1 - \Sigma_u^{-1}).\qquad (**) @f]
 *  Assume that we have found @f$h_1, \dots, h_T@f$ so far, solving the dual
 *  problem with @f$T@f$ (*) constraints gives us @f$\Sigma_u@f$. If for
 *  every remaining @f$h@f$ in @f$\cal{H}@f$,
 *     @f$ e(h, w) \ge \frac12 (1 - \Sigma_u^{-1}),@f$
 *  the duality condition tells us that even if we set @f$\alpha=0@f$ for those
 *  remaining @f$h@f$, the solution is still optimal. Thus, we can train the
 *  weak learner with sample weight @f$w@f$ in each iteration, and terminate
 *  if the best hypothesis has satisfied (**).
 *
 *  [1] A. Demiriz, K. P. Bennett, and J. Shawe-Taylor. Linear programming
 *      boosting via column generation. <EM>Machine Learning</EM>,
 *      46(1-3):225-254, 2002.
 */
class LPBoost : public Boosting {
    REAL RegC;

public:
    explicit LPBoost () : Boosting(false) { set_C(1); }
    LPBoost (const Boosting& s) : Boosting(s) { assert(!convex); set_C(1); }
    explicit LPBoost (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual LPBoost* create () const { return new LPBoost(); }
    virtual LPBoost* clone () const { return new LPBoost(*this); }

    /// @todo Implement something similar to that in CGBoost.
    virtual bool set_aggregation_size (UINT) { return false; }
    virtual void train ();

    /// The regularization constant C.
    REAL C () const { return RegC; }
    /// Set the regularization constant C.
    void set_C (REAL _C) { assert(_C >= 0); RegC = _C; }
};

} // namespace lemga

#ifdef  __LPBOOST_H__
#warning "This header file may conflict with another `lpboost.h' file."
#endif
#define __LPBOOST_H__
#endif
