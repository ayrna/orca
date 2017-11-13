// -*- C++ -*-
#ifndef __LEMGA_MULTICLASS_ADABOOST_ECOC_H__
#define __LEMGA_MULTICLASS_ADABOOST_ECOC_H__

/** @file
 *  @brief Declare @link lemga::AdaBoost_ECOC AdaBoost_ECOC@endlink class.
 *
 *  $Id: adaboost_ecoc.h 2696 2006-04-05 20:10:13Z ling $
 */

#include "multiclass_ecoc.h"
#include "shared_ptr.h"

namespace lemga {

typedef std::vector<DataWgt> JointWgt;
typedef const_shared_ptr<JointWgt> pJointWgt;

/** @brief AdaBoost.ECC with exponential cost and Hamming distance.
 */
class AdaBoost_ECOC : public MultiClass_ECOC {
public:
    enum PARTITION_METHOD {
        RANDOM_HALF,
        MAX_CUT, MAX_CUT_GREEDY,
        RANDOM_2,
        MAX_2
    };

protected:
    PARTITION_METHOD par_method;

public:
    AdaBoost_ECOC () : MultiClass_ECOC(), par_method(MAX_CUT_GREEDY) {}
    AdaBoost_ECOC (const MultiClass_ECOC& s)
        : MultiClass_ECOC(s), par_method(MAX_CUT_GREEDY) {}
    explicit AdaBoost_ECOC (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual AdaBoost_ECOC* create () const { return new AdaBoost_ECOC(); }
    virtual AdaBoost_ECOC* clone () const {
        return new AdaBoost_ECOC(*this); }

    void set_partition_method (PARTITION_METHOD m) { par_method = m; }

protected:
    /// set up by setup_aux(); updated by update_aux();
    /// used by a lot of functions here.
    JointWgt joint_wgt;
    /// set up by train_with_partition();
    /// used by assign_weight() and update_aux().
    mutable std::vector<bool> cur_err;
    /// set up by train_with_partition(); used by assign_weight().
    mutable pDataWgt cur_smpwgt;
    pDataWgt smpwgt_with_partition (const ECOC_VECTOR&) const;
    pLearnModel train_with_full_partition (const ECOC_VECTOR&) const;

    virtual void setup_aux ();
    virtual bool ECOC_partition (UINT, ECOC_VECTOR&) const;
    virtual pLearnModel train_with_partition (ECOC_VECTOR&) const;
    virtual REAL assign_weight (const ECOC_VECTOR&, const LearnModel&) const;
    virtual void update_aux (const ECOC_VECTOR&);

    std::vector<std::vector<REAL> > confusion_matrix () const;
    ECOC_VECTOR max_cut (UINT) const;
    ECOC_VECTOR max_cut_greedy (UINT) const;
    ECOC_VECTOR random_half (UINT) const;
};

} // namespace lemga

#ifdef  __ADABOOST_ECOC_H__
#warning "This header file may conflict with another `adaboost_ecoc.h' file."
#endif
#define __ADABOOST_ECOC_H__
#endif
