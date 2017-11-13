// -*- C++ -*-
#ifndef __LEMGA_PULSE_H__
#define __LEMGA_PULSE_H__

/** @file
 *  @brief @link lemga::Pulse Pulse function@endlink class
 *
 *  $Id: pulse.h 2664 2006-03-07 19:50:51Z ling $
 */

#include <vector>
#include "learnmodel.h"

namespace lemga {

/** @brief Multi-transition pulse functions (step functions).
 *  @todo Documentation
 */
class Pulse : public LearnModel {
    UINT idx;               ///< which dimenstion?
    std::vector<REAL> th;   ///< transition points
    bool dir;               ///< @c true: start with -1
    UINT max_l;             ///< Maximal # of transitions

public:
    explicit Pulse (UINT n_in = 0) : LearnModel(n_in, 1), idx(0), max_l(1) {}
    explicit Pulse (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual Pulse* create () const { return new Pulse(); }
    virtual Pulse* clone () const { return new Pulse(*this); }

    /** @return The dimension picked for classification. */
    UINT index () const { return idx; }
    /// Set the dimension picked for classification.
    void set_index (UINT i) { assert(i < n_input()); idx = i; }
    /** @return a vector of transition points. */
    const std::vector<REAL>& threshold () const { return th; }
    /// Set the transition points.
    void set_threshold (const std::vector<REAL>&);
    /** @return @c true if the pulse starts with -1. */
    bool direction () const { return dir; }
    /// Set the pulse direction (true if starting with -1).
    void set_direction (bool d) { dir = d; }
    /** @return the maximal number of transitions the pulse can have. */
    UINT max_transitions () { return max_l; }
    /// Set the maximal number of transitions the pulse can have.
    void set_max_transitions (UINT ml) { max_l = ml; }
    // TODO: resize th?

    virtual bool support_weighted_data () const { return true; }

    virtual void train ();

    virtual Output operator() (const Input&) const;

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

} // namespace lemga

#ifdef  __PULSE_H__
#warning "This header file may conflict with another `pulse.h' file."
#endif
#define __PULSE_H__
#endif
