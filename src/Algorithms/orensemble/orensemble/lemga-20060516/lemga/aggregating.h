// -*- C++ -*-
#ifndef __LEMGA_AGGREGATING_H__
#define __LEMGA_AGGREGATING_H__

/** @file
 *  @brief Declare @link lemga::Aggregating Aggregating@endlink class.
 *
 *  $Id: aggregating.h 2664 2006-03-07 19:50:51Z ling $
 */

#include <vector>
#include "learnmodel.h"

namespace lemga {

/** @brief An abstract class for aggregating.
 *
 *  %Aggregating in learning stands for a series of techniques which
 *  generate several hypotheses and combine them into a large and
 *  usually better one. Bagging and AdaBoost are two famous examples
 *  of such techniques. This class provides member functions to
 *  store and retrieve hypotheses used in aggregating.
 *
 *  The class has a vector of hypotheses, and a base learning model,
 *  which is the ``parent'' of all those hypotheses. For users of this
 *  class, a possible calling order for training is
 *  -# <code>Aggregating *ag = new Some_Aggregating_Method (6, 5);</code>\n
 *     Create an instance of aggregating with 6 as input dimension
 *     and 5 output dimension.
 *  -# <code>ag->@link
 *     set_base_model() set_base_model@endlink(a_neural_net);</code>\n
 *     Specify the base learning model (in this example, a neural network).
 *  -# Follow the
 *     @ref learnmodel_training_order "normal calling order for training"
 *     to complete the training.
 *
 *  We do not provide...?
 *  @todo Documentation
 */
class Aggregating : public LearnModel {
protected:
    pcLearnModel lm_base;           ///< The base learning model
    std::vector<pLearnModel> lm;    ///< Pointers to learning models
    UINT n_in_agg;                  ///< \# of models in aggregating
    UINT max_n_model;               ///< Maximal # of models allowed

public:
    Aggregating () : LearnModel(), n_in_agg(0), max_n_model(0) {}
    Aggregating (const Aggregating&);
    const Aggregating& operator= (const Aggregating&);

    virtual Aggregating* create () const = 0;
    virtual Aggregating* clone () const = 0;

    //@{ @name Set/get the base model (weak learner)
    void set_base_model (const LearnModel&);
    const LearnModel& base_model () const { return *lm_base; }
    //@}

    void set_max_models (UINT max) { max_n_model = max; }

    //@{ @name Hypotheses operation
    /// Total number of hypotheses
    UINT size () const { return lm.size(); }
    bool empty () const { return lm.empty(); }
    const LearnModel& model (UINT n) const { return *lm[n]; }
    const LearnModel& operator[] (UINT n) const { return *lm[n]; }
    //@}

    virtual bool set_aggregation_size (UINT);
    UINT aggregation_size () const { return n_in_agg; }
    virtual void set_train_data (const pDataSet&, const pDataWgt& = 0);
    virtual void reset ();

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

} // namespace lemga

#ifdef  __AGGREGATING_H__
#warning "This header file may conflict with another `aggregating.h' file."
#endif
#define __AGGREGATING_H__
#endif
