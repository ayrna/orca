// -*- C++ -*-
#ifndef __LEMGA_AGGREGATING_ADABOOST_H__
#define __LEMGA_AGGREGATING_ADABOOST_H__

/** @file
 *  @brief Declare @link lemga::AdaBoost AdaBoost@endlink class.
 *
 *  $Id: adaboost.h 2696 2006-04-05 20:10:13Z ling $
 */

#include "boosting.h"

namespace lemga {

/** @brief %AdaBoost (adaptive boosting).
 *
 *  %AdaBoost can be seen as gradient descent in the function space
 *  where the pointwise cost functional is defined as
 *  @f[ c(F(x_i),y_i) = e^{-y_i F(x_i)}\,. @f]
 */
class AdaBoost : public Boosting {
public:
    explicit AdaBoost (bool cvx = false, const cost::Cost& c = cost::_cost)
        : Boosting(cvx, c) {}
    AdaBoost (const Boosting& s) : Boosting(s) {}
    explicit AdaBoost (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual AdaBoost* create () const { return new AdaBoost(); }
    virtual AdaBoost* clone () const { return new AdaBoost(*this); }

    virtual void train ();

protected:
    /// data only valid within training (remove?)
    std::vector<REAL> cur_err;

    virtual REAL convex_weight (const DataWgt&, const LearnModel&);
    virtual REAL linear_weight (const DataWgt&, const LearnModel&);
    virtual void linear_smpwgt (DataWgt&);
};

} // namespace lemga

#ifdef  __ADABOOST_H__
#warning "This header file may conflict with another `adaboost.h' file."
#endif
#define __ADABOOST_H__
#endif
