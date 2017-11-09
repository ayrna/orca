// -*- C++ -*-
#ifndef __LEMGA_LEARNMODEL_H__
#define __LEMGA_LEARNMODEL_H__

/** @file
 *  @brief Type definitions, @link lemga::DataSet DataSet@endlink, and
 *  @link lemga::LearnModel LearnModel@endlink class.
 *  @todo: add input_dim check to dataset and learnmodel
 *
 *  $Id: learnmodel.h 2779 2006-05-09 06:49:33Z ling $
 */

#include <assert.h>
#include <vector>
#include "object.h"
#include "dataset.h"
#include "shared_ptr.h"

#define VERBOSE_OUTPUT  1

namespace lemga {

typedef std::vector<REAL> Input;
typedef std::vector<REAL> Output;

typedef dataset<Input,Output> DataSet;
typedef std::vector<REAL> DataWgt;
typedef const_shared_ptr<DataSet> pDataSet;
typedef const_shared_ptr<DataWgt> pDataWgt;

/// Load a data set from a stream
DataSet* load_data (std::istream&, UINT, UINT, UINT);
DataSet* load_data (std::istream&, UINT);

/** @brief A unified interface for learning models.
 *
 *  I try to provide
 *  + r_error and c_error
 *    for regression problems, r_error should be defined;
 *    for classification problems, c_error should be defined;
 *    these two errors can both be present
 *
 *  The training data is stored with the learning model (as a pointer)
 *  Say: why (the benefit of store with, a pointer); maybe not a pointer
 *  Say: what's the impact of doing this (what will be changed
 *       from normal implementation)
 *  Say: wgt: could be null if the model doesn't support ...otherwise shoud
 *       be a probability vector (randome_sample)...
 *
 *  @anchor learnmodel_training_order
 *  The flowchart of the learning ...
 *  -# Create a new instance, load from a file, and/or reset an existing
 *     one <code>lm->reset();</code>.
 *  -# <code>lm->set_train_data(sample_data);</code>\n
 *         Specify the training data
 *  -# <code>err = lm->train();</code>\n
 *         Usually, the return value has no meaning
 *  -# <code>y = (*lm)(x);</code>\n
 *         Apply the learning model to new data.
 *
 *  @todo documentation
 *  @todo Do we really need two errors?
 */
class LearnModel : public Object {
protected:
    UINT _n_in;       ///< input dimension of the model
    UINT _n_out;      ///< output dimension of the model
    pDataSet ptd;     ///< pointer to the training data set
    pDataWgt ptw;     ///< pointer to the sample weight (for training)
    UINT n_samples;   ///< equal to @c ptd->size()

    FILE* logf;       ///< file to record train/validate error

public:
    LearnModel (UINT n_in = 0, UINT n_out = 0);

    //@{ @name Basic
    virtual LearnModel* create () const = 0;
    virtual LearnModel* clone () const = 0;

    UINT n_input  () const { return _n_in;  }
    UINT n_output () const { return _n_out; }

    void set_log_file (FILE* f) { logf = f; }
    //@}

    //@{ @name Training related
    /** @brief Whether the learning model/algorithm supports unequally
     *  weighted data.
     *  @return @c true if supporting; @c false otherwise. The default
     *  is @c false, just for safety.
     *  @sa set_train_data()
     */
    virtual bool support_weighted_data () const { return false; }

    /// Error measure for regression problems
    virtual REAL r_error (const Output& out, const Output& y) const;
    /// Error measure for classification problems
    virtual REAL c_error (const Output& out, const Output& y) const;

    /// Training error (regression)
    REAL train_r_error () const;
    /// Training error (classification)
    REAL train_c_error () const;
    /// Test error (regression)
    REAL test_r_error (const pDataSet&) const;
    /// Test error (classification)
    REAL test_c_error (const pDataSet&) const;

    virtual void initialize () {
        std::cerr << "!!! initialize() is depreciated.\n"
                  << "!!! See the documentation of LearnModel and reset().\n";
    }

    /// Set the data set and sample weight to be used in training
    virtual void set_train_data (const pDataSet&, const pDataWgt& = 0);
    /// Return pointer to the embedded training data set
    const pDataSet& train_data () const { return ptd; }
    /* temporarily disabled; ptw in boosting base learners is reset
     * after the training; disabled to be sure no one actually uses it
    const pDataWgt& data_weight () const { return ptw; }
     */

    /** @brief Train with preset data set and sample weight.
     */
    virtual void train () = 0;

    /// Cleaning up the learning model but keeping most settings.
    /// @note This is probably needed after training or loading from file,
    /// but before having another training.
    virtual void reset ();
    //@}

    virtual Output operator() (const Input&) const = 0;

    /** @brief Get the output of the hypothesis on the @a idx-th input.
     *  @note It is possible to cache results to save computational effort.
     */
    virtual Output get_output (UINT idx) const {
        assert(ptw != 0); // no data sampling
        return operator()(ptd->x(idx)); }

    //@{ @name Margin related
    /** @brief The normalization term for margins.
     *
     *  The margin concept can be normalized or unnormalized. For example,
     *  for a perceptron model, the unnormalized margin would be the wegithed
     *  sum of the input features, and the normalized margin would be the
     *  distance to the hyperplane, and the normalization term is the norm
     *  of the hyperplane weight.
     *
     *  Since the normalization term is usually a constant, it would be
     *  more efficient if it is precomputed instead of being calculated
     *  every time when a margin is asked for. The best way is to use a
     *  cache. Here I use a easier way: let the users decide when to
     *  compute the normalization term.
     */
    virtual REAL margin_norm () const { return 1; }
    /// Report the (unnormalized) margin of an example (@a x, @a y).
    virtual REAL margin_of (const Input& x, const Output& y) const;
    /** @brief Report the (unnormalized) margin of the example @a i.
     *  @note It is possible to cache results to save computational effort.
     */
    virtual REAL margin (UINT i) const {
        assert(ptw != 0); // no data sampling
        return margin_of(ptd->x(i), ptd->y(i)); }
    /// The minimal (unnormalized) in-sample margin.
    REAL min_margin () const;
    //@}

    bool valid_dimensions (UINT, UINT) const;
    inline bool valid_dimensions (const LearnModel& l) const {
        return valid_dimensions(l.n_input(), l.n_output()); }

    inline bool exact_dimensions (UINT i, UINT o) const {
        return (i > 0 && o > 0 && valid_dimensions(i, o)); }
    inline bool exact_dimensions (const LearnModel& l) const {
        return exact_dimensions(l.n_input(), l.n_output()); }
    inline bool exact_dimensions (const DataSet& d) const {
        assert(d.size() > 0);
        return exact_dimensions(d.x(0).size(), d.y(0).size()); }

protected:
    void set_dimensions (UINT, UINT);
    inline void set_dimensions (const LearnModel& l) {
        set_dimensions(l.n_input(), l.n_output()); }
    inline void set_dimensions (const DataSet& d) {
        assert(exact_dimensions(d));
        set_dimensions(d.x(0).size(), d.y(0).size()); }

    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

typedef var_shared_ptr<LearnModel> pLearnModel;
typedef const_shared_ptr<LearnModel> pcLearnModel;

} // namespace lemga

#ifdef  __LEARNMODEL_H__
#warning "This header file may conflict with another `learnmodel.h' file."
#endif
#define __LEARNMODEL_H__
#endif
