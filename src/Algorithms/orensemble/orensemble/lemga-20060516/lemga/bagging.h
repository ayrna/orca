// -*- C++ -*-
#ifndef __LEMGA_AGGREGATING_BAGGING_H__
#define __LEMGA_AGGREGATING_BAGGING_H__

/** @file
 *  @brief Declare @link lemga::Bagging Bagging@endlink class.
 *
 *  $Id: bagging.h 2696 2006-04-05 20:10:13Z ling $
 */

#include "aggregating.h"

namespace lemga {

/** @brief %Bagging (boostrap aggregating).
 *
 *  %Bagging averages over all hypotheses.
 *  @todo Documentation
 */
class Bagging : public Aggregating {
public:
    Bagging () : Aggregating() {}
    Bagging (const Aggregating& s) : Aggregating(s) {}
    explicit Bagging (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual Bagging* create () const { return new Bagging(); }
    virtual Bagging* clone () const { return new Bagging(*this); }

    virtual bool support_weighted_data () const { return true; }
    virtual void train ();
    virtual Output operator() (const Input&) const;
    virtual REAL margin_norm () const;
    virtual REAL margin_of (const Input&, const Output&) const;
};

} // namespace lemga

#ifdef  __BAGGING_H__
#warning "This header file may conflict with another `bagging.h' file."
#endif
#define __BAGGING_H__
#endif
