// -*- C++ -*-
#ifndef __LEMGA_STUMP_H__
#define __LEMGA_STUMP_H__

/** @file
 *  @brief @link lemga::Stump Decision stump@endlink class.
 *
 *  $Id: stump.h 2891 2006-11-08 03:17:31Z ling $
 */

#include "learnmodel.h"

namespace lemga {

/** @brief Decision stump.
 *  @todo Documentation
 */
class Stump : public LearnModel {
    UINT idx;
    REAL bd1, bd2;///< threshold is (bd1+bd2)/2
    bool dir;     ///< \c true: sgn(x[idx] - th); \c false: -sgn(x[idx] - th).
    bool hard;    ///< use the hard threshold?

public:
    explicit Stump (UINT n_in = 0)
        : LearnModel(n_in, 1), idx(0), bd1(0), bd2(0), hard(true) {}
    explicit Stump (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual Stump* create () const { return new Stump(); }
    virtual Stump* clone () const { return new Stump(*this); }

    UINT index () const { return idx; }
    REAL threshold () const { return (bd1+bd2)/2; }
    bool direction () const { return dir; }
    bool soft_threshold () const { return !hard; }
    void use_soft_threshold (bool s = true) { hard = !s; }

    virtual bool support_weighted_data () const { return true; }

    virtual void train ();
    /// Find the optimal threshold and direction (prefer the middle thresholds)
    static REAL train_1d (const std::vector<REAL>&, const std::vector<REAL>&,
                          REAL, bool&, bool&, REAL&, REAL&);
    /// Find the optimal threshold for positive direction
    static REAL train_1d (const std::vector<REAL>&, const std::vector<REAL>&);

    virtual Output operator() (const Input&) const;

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

} // namespace lemga

#ifdef  __STUMP_H__
#warning "This header file may conflict with another `stump.h' file."
#endif
#define __STUMP_H__
#endif
