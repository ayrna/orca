// -*- C++ -*-
#ifndef __LEMGA_MULTICLASS_ADABOOST_ERP_H__
#define __LEMGA_MULTICLASS_ADABOOST_ERP_H__

/** @file
 *  @brief Declare @link lemga::AdaBoost_ERP AdaBoost_ERP@endlink class.
 *
 *  $Id: adaboost_erp.h 2746 2006-04-21 22:45:38Z ling $
 */

#include "adaboost_ecoc.h"

namespace lemga {

/** @brief AdaBoost.ERP (AdaBoost.ECC with Re-Partitioning).
 *
 *  Alter the ECC table after learning.
 */
class AdaBoost_ERP : public AdaBoost_ECOC {
protected:
    UINT lrs; ///< # of steps in the learning / re-partitioning cycle
    //? shall we save rp_step when serializing?

public:
    AdaBoost_ERP () : AdaBoost_ECOC(), lrs(2) {}
    AdaBoost_ERP (const AdaBoost_ECOC& s) : AdaBoost_ECOC(s), lrs(2) {}
    explicit AdaBoost_ERP (std::istream& is) : lrs(2) { is >> *this; }

    virtual const id_t& id () const;
    virtual AdaBoost_ERP* create () const { return new AdaBoost_ERP(); }
    virtual AdaBoost_ERP* clone () const {
        return new AdaBoost_ERP(*this); }

    void set_lr_step (UINT s) { assert(s > 1); lrs = s; }

protected:
    pLearnModel train_with_partial_partition (const ECOC_VECTOR&) const;

    virtual bool ECOC_partition (UINT, ECOC_VECTOR&) const;
    virtual pLearnModel train_with_partition (ECOC_VECTOR&) const;
};

} // namespace lemga

#ifdef  __ADABOOST_ERP_H__
#warning "This header file may conflict with another `adaboost_erp.h' file."
#endif
#define __ADABOOST_ERP_H__
#endif
