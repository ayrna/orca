// -*- C++ -*-
#ifndef __LEMGA_ORDINAL_BLE_H__
#define __LEMGA_ORDINAL_BLE_H__

/** @file
 *  @brief Declare @link lemga::Ordinal_BLE Ordinal_BLE@endlink class.
 *
 *  $Id: ordinal_ble.h 2782 2006-05-15 19:25:35Z ling $
 */

#include "learnmodel.h"
#include "multiclass_ecoc.h" // ECOC_VECTOR & ECOC_TABLE

namespace lemga {
typedef std::vector<std::vector<REAL> > EXT_TABLE;
enum BLE_TYPE {
    MULTI_THRESHOLD,
    BLE_DEFAULT = MULTI_THRESHOLD
};

/** @brief Ordinal regression via binary learning on extended examples
 */
class Ordinal_BLE : public LearnModel {
protected:
    pLearnModel lm;     ///< the learning model
    bool full_ext;      ///< use the full extension or the partial one?
    ECOC_TABLE out_tab; ///< K (nrank) by T (n_hyp) output ECC matrix
    EXT_TABLE ext_tab;  ///< T (n_hyp) by E (n_ext) extension matrix
    UINT n_ext;

public:
    Ordinal_BLE () : full_ext(true), n_ext(0), d_nrank(0)
    { set_dimensions(0, 1); }
    Ordinal_BLE (const Ordinal_BLE&);
    const Ordinal_BLE& operator= (const Ordinal_BLE&);
    explicit Ordinal_BLE (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual Ordinal_BLE* create () const { return new Ordinal_BLE(); }
    virtual Ordinal_BLE* clone () const { return new Ordinal_BLE(*this); }

    /// set the underlying learning model
    void set_model (const LearnModel&);
    /// the underlying model
    const LearnModel& model () const { assert(lm != 0); return *lm; }

    //@{ Settings on how to extend the original examples
    bool full_extension () const { return full_ext; }
    void set_full_extension (bool = true);
    const ECOC_TABLE& ECOC_table () const { return out_tab; }
    const EXT_TABLE& extension_table () const { return ext_tab; }
    void set_tables (const ECOC_TABLE&, const EXT_TABLE&);
    void set_tables (BLE_TYPE, UINT);
    //@}

    /// the number of ranks from the training set
    UINT n_rank () const { return d_nrank; }

    virtual bool support_weighted_data () const { return true; }
    virtual REAL c_error (const Output& out, const Output& y) const;
    virtual REAL r_error (const Output& out, const Output& y) const;
    virtual void set_train_data (const pDataSet&, const pDataWgt& = 0);
    virtual void train ();
    virtual void reset ();
    virtual Output operator() (const Input&) const;

protected:
    pDataSet ext_d;     ///< the extended dataset
    pDataWgt ext_w;     ///< the weight for the extended set
    UINT d_nrank;       ///< number of ranking levels of the training set
    bool reset_data;    ///< whether to reset the training set for lm

    void extend_input (const Input&, UINT, Input&) const;
    void extend_example (const Input&, UINT, UINT, Input&, REAL&) const;
    void extend_data ();

    virtual REAL ECOC_distance (const Output&, const ECOC_VECTOR&) const;
    mutable std::vector<REAL> local_d;
    const std::vector<REAL>& distances (const Input&) const;

    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

} // namespace lemga

#ifdef  __ORDINAL_BLE_H__
#warning "This header file may conflict with another `ordinal_ble.h' file."
#endif
#define __ORDINAL_BLE_H__
#endif
