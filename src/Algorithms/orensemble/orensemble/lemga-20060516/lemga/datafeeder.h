// -*- C++ -*-
#ifndef __LEMGA_DATAFEEDER_H__
#define __LEMGA_DATAFEEDER_H__

/** @file
 *  @brief Declare @link lemga::DataFeeder DataFeeder@endlink class.
 *
 *  $Id: datafeeder.h 2563 2006-01-20 05:04:22Z ling $
 */

#include <iostream>
#include "learnmodel.h"

namespace lemga {

/** @brief Feed (random splitted) training and testing data.
 */
class DataFeeder {
public:
    enum NORMETHOD {   // normalization method
        MIN_MAX,       // make min -1, max +1
        MEAN_VAR,      // make mean 0, var 1
        NONE
    };

private:
    pDataSet dat;
    std::istream* perms;
    NORMETHOD _do_normalize;
    UINT fsize, tr_size;
    REAL tr_flip;

public:
    DataFeeder (const pDataSet&);
    DataFeeder (std::istream&);

    void set_permutation (std::istream& i) { perms = &i; }
    void do_normalize (NORMETHOD dn = MIN_MAX) { _do_normalize = dn; }
    UINT size () const { return fsize; }
    /// the size of the training set
    UINT train_size () const { return tr_size; }
    /// set the size of the training set
    void set_train_size (UINT);
    /// the artificial flipping noise level for the training set
    REAL train_noise () const { return tr_flip; }
    /// set the artificial flipping noise level for the training set
    void set_train_noise (REAL);

    pDataSet data () const { return dat; }
    bool next_train_test (pDataSet&, pDataSet&) const;

protected:
    bool next_permutation (std::vector<UINT>&) const;

    struct LINEAR_SCALE_PARAM {
        REAL center, scale;
    };
    typedef std::vector<LINEAR_SCALE_PARAM> LINEAR_SCALE_PARAMS;

    static LINEAR_SCALE_PARAMS min_max (DataSet&);
    static LINEAR_SCALE_PARAMS mean_var (DataSet&);
    static void linear_scale (DataSet&, const LINEAR_SCALE_PARAMS&);
};

} // namespace lemga

#ifdef  __DATAFEEDER_H__
#warning "This header file may conflict with another `datafeeder.h' file."
#endif
#define __DATAFEEDER_H__
#endif
