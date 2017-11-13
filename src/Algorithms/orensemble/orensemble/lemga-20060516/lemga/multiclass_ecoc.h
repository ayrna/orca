// -*- C++ -*-
#ifndef __LEMGA_MULTICLASS_ECOC_H__
#define __LEMGA_MULTICLASS_ECOC_H__

/** @file
 *  @brief Declare @link lemga::MultiClass_ECOC MultiClass_ECOC@endlink
 *  (Multiclass classification with Error-Correcting Output Code) class.
 *
 *  $Id: multiclass_ecoc.h 2695 2006-04-05 05:21:47Z ling $
 */

#include <vector>
#include "aggregating.h"

// 0 - no cache; 1 - cache output; 2 - cache distance
#define MULTICLASS_ECOC_OUTPUT_CACHE    2

namespace lemga {

typedef std::vector<int> ECOC_VECTOR;
typedef std::vector<ECOC_VECTOR> ECOC_TABLE;
enum ECOC_TYPE {
    NO_TYPE,
    ONE_VS_ONE,
    ONE_VS_ALL
};

/** @brief Multiclass classification using error-correcting output code.
 */
class MultiClass_ECOC : public Aggregating {
protected:
    std::vector<REAL> lm_wgt;   ///< hypothesis weight
    ECOC_TABLE ecoc;            ///< the ECC table
    /// The type of the ECOC table, if there is some fixed type.
    /// @note It is not serialized, at least for now.
    ECOC_TYPE ecoc_type;

    // variables extracted from the training data
    UINT nclass;                ///< number of classes
    std::vector<REAL> labels;   ///< class labels
    std::vector<UINT> ex_class; ///< class number of examples

public:
    MultiClass_ECOC () : Aggregating(), ecoc_type(NO_TYPE), nclass(0)
    { set_dimensions(0, 1); }
    explicit MultiClass_ECOC (std::istream& is) : ecoc_type(NO_TYPE)
    { is >> *this; }

    virtual const id_t& id () const;
    virtual MultiClass_ECOC* create () const { return new MultiClass_ECOC(); }
    virtual MultiClass_ECOC* clone () const {
        return new MultiClass_ECOC(*this); }

    REAL model_weight (UINT n) const { return lm_wgt[n]; }
    const ECOC_TABLE& ECOC_table () const { return ecoc; }
    void set_ECOC_table (const ECOC_TABLE&);
    void set_ECOC_table (ECOC_TYPE);
    void set_ECOC_table (UINT, const ECOC_VECTOR&);
    UINT n_class () const { return nclass; }

    virtual bool support_weighted_data () const { return true; }
    virtual REAL c_error (const Output& out, const Output& y) const;
    virtual void set_train_data (const pDataSet&, const pDataWgt& = 0);
    virtual void train ();
    virtual void reset ();
    virtual Output operator() (const Input&) const;
    virtual Output get_output (UINT idx) const;

    virtual REAL margin (UINT) const;
    virtual REAL margin_of (const Input&, const Output&) const;
    /// The in-sample exponential cost defined in my paper.
    REAL cost () const;

#if MULTICLASS_ECOC_OUTPUT_CACHE
private:
#if MULTICLASS_ECOC_OUTPUT_CACHE == 2  // distance cache
    mutable std::vector<UINT> cache_n;
    mutable std::vector<std::vector<REAL> > cache_d;
    inline void clear_cache (UINT i) const {
        assert(i < n_samples && cache_n.size() == n_samples && nclass > 0);
        cache_n[i] = 0;
        std::vector<REAL> cdi(nclass, 0);
        cache_d[i].swap(cdi);
    }
    inline void clear_cache () const {
        cache_d.resize(n_samples);
        cache_n.resize(n_samples);
        for (UINT i = 0; i < n_samples; ++i)
            clear_cache(i);
    }
#elif MULTICLASS_ECOC_OUTPUT_CACHE == 1
    mutable std::vector<Output> cache_o;
    inline void clear_cache () const {
        std::vector<Output> co(n_samples);
        cache_o.swap(co);
    }
#else
#error "Wrong value of MULTICLASS_ECOC_OUTPUT_CACHE in `multiclass_ecoc.h'."
#endif
#endif // MULTICLASS_ECOC_OUTPUT_CACHE

protected:
    virtual REAL ECOC_distance (const Output&, const ECOC_VECTOR&) const;
#if MULTICLASS_ECOC_OUTPUT_CACHE == 2  // distance cache
    virtual REAL ECOC_distance (REAL, int, REAL, REAL = 0) const;
#endif

    mutable std::vector<REAL> local_d;
    /// @note It might be unsafe to use a reference to a local
    /// variable as the return value
    const std::vector<REAL>& distances (const Input&) const;
    const std::vector<REAL>& distances (UINT) const;

    /// Does the partition only consist of -1 and +1?
    bool is_full_partition (const ECOC_VECTOR&) const;

    /// Prepare auxiliary variables for current n_in_agg
    virtual void setup_aux () {}
    virtual bool ECOC_partition (UINT, ECOC_VECTOR&) const;
    virtual pLearnModel train_with_partition (ECOC_VECTOR&) const;
    virtual REAL assign_weight (const ECOC_VECTOR&, const LearnModel&) const
    { return 1; }
    /// Update those auxiliary variables after this round of learning
    virtual void update_aux (const ECOC_VECTOR&) {}

    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

} // namespace lemga

#ifdef  __MULTICLASS_ECOC_H__
#warning "This header file may conflict with another `multiclass_ecoc.h' file."
#endif
#define __MULTICLASS_ECOC_H__
#endif
