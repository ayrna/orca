// -*- C++ -*-
#ifndef __LEMGA_AGGREGATING_BOOSTING_H__
#define __LEMGA_AGGREGATING_BOOSTING_H__

/** @file
 *  @brief Declare @link lemga::Boosting Boosting@endlink (AnyBoost) class.
 *
 *  $Id: boosting.h 2696 2006-04-05 20:10:13Z ling $
 */

#include <numeric>
#include <utility>
#include "aggregating.h"
#include "cost.h"

#define BOOSTING_OUTPUT_CACHE   1

namespace lemga {

/// Interface for optimization of Boosting
struct _boost_gd;

/** @brief %Boosting generates a linear combination of hypotheses.
 *
 *  As one specific aggregating technique, boosting generates a linear
 *  (may be restricted to convex) combination of hypotheses by
 *  sequentially calling a weak learner (the base model) with varying
 *  sample weights.
 *
 *  For many problems, convex combination may result in a same super
 *  learning model as linear combination does. However, the training
 *  algorithms used in different combinations may differ. Whether to
 *  use convex or linear combinations is specified with the constructor
 *  (Boosting()). The default is linear combination.
 *
 *  Traditional boosting techniques (e.g., %AdaBoost) carry out training
 *  in the following form to generate @a n hypotheses:
 *  -# Initialize sample weights;
 *  -# For @a i from 1 to @a n, do
 *     -# Call the weak learner with the current sample weights to
 *        get a new hypothesis;
 *     -# Calculate the weight for this hypothesis;
 *     -# Update the sample weights.
 *  -# Return the weighted sum of hypotheses (with a @c sign operation).
 *
 *  (See the code of Boosting::train() for more details.)
 *  The function assign_weight() is used to calculate the weight for
 *  the hypothesis; update_smpwgt() is used to update the sample weights.
 *  Modifying these two functions properly is usually enough for
 *  designing a new boosting algorithm. (To be precise, functions to
 *  be modified are convex_weight(), convex_smpwgt(), and/or
 *  linear_weight(), linear_smpwgt().)
 *
 *  @attention We do not assume update_smpwgt() will ever be called.
 *  However, if it is called, we do assume assign_weight() has been
 *  called immediately before it.
 *
 *  %Boosting algorithms (at least some of them) can be viewed as
 *  gradient descent in a function space. A cost functional
 *  @f[ C(F) = \sum_i w_i \cdot c(F(x_i), y_i) @f]
 *  is the sample average of some pointwise cost (#cost_functor).
 *  A @em corresponding boosting algorithm decreases this cost
 *  functional by adding proper weak hypotheses to @a F.
 *
 *  The gradient, which is a function, is also defined on training samples:
 *  @f[ \nabla C(F)(x_i) = w_i \cdot c'_F (F(x_i), y_i)\,. @f]
 *  The next hypothesis should maximize the inner-product between it
 *  and @f$\nabla C(F)@f$. Thus the sample weights used to training
 *  this hypothesis is
 *  @f[ D_i \propto -\frac{w_i}{y_i} c'_F (F(x_i), y_i) @f]
 *  where @f$c'_F(\cdot,\cdot)@f$ is the partial derivative to the
 *  first argument (see #cost_functor.deriv1()).
 *
 *  Denote the newly generated hypothesis by @a g. The weight for @a g
 *  can be determined by doing a line search along @f$F+\alpha g@f$,
 *  where @f$\alpha@f$ is a positive scalar. The weight also makes
 *  the updated vector of sample weights perpendicular to the vector
 *  of errors of @a g.
 *
 *  We use the @link _line_search line search template@endlink to
 *  implement the training of gradient descent view. Employing different
 *  #cost_functor should be enough to get a different boosting algorithm.
 *  See also _boost_gd.
 *
 *  @note For some cost functionals, the weight can be calculated directly
 *  without a line search. Replacing the line search with the direct
 *  calculation would improve the performace.
 */
class Boosting : public Aggregating {
protected:
    std::vector<REAL> lm_wgt;   ///< hypothesis weight
    bool convex;                ///< convex or linear combination

    // runtime parameters
    bool grad_desc_view;        ///< Traditional way or gradient descent
    REAL min_cst, min_err;

public:
    /// Calculate @f$c(F(x),y)@f$ and its derivative
    const cost::Cost& cost_functor;

    explicit Boosting (bool cvx = false, const cost::Cost& = cost::_cost);
    Boosting (const Aggregating&);
    explicit Boosting (std::istream& is): cost_functor(cost::_cost)
    { is >> *this; }

    virtual const id_t& id () const;
    virtual Boosting* create () const { return new Boosting(); }
    virtual Boosting* clone () const { return new Boosting(*this); }

    bool is_convex () const { return convex; }
    REAL model_weight (UINT n) const { return lm_wgt[n]; }
    void use_gradient_descent (bool gd = true) { grad_desc_view = gd; }
    void set_min_cost (REAL mincst) { min_cst = mincst; }
    void set_min_error (REAL minerr) { min_err = minerr; }
    virtual REAL margin_norm () const;
    virtual REAL margin_of (const Input&, const Output&) const;
    virtual REAL margin (UINT) const;

    virtual bool support_weighted_data () const { return true; }
    virtual void train ();
    virtual void reset ();
    virtual Output operator() (const Input&) const;
    virtual Output get_output (UINT) const;

#if BOOSTING_OUTPUT_CACHE
    virtual void set_train_data (const pDataSet&, const pDataWgt& = 0);

private:
    mutable std::vector<UINT> cache_n;
    mutable std::vector<Output> cache_y;
protected:
    inline void clear_cache (UINT idx) const {
        assert(idx < n_samples && cache_n.size() == n_samples);
        cache_n[idx] = 0;
        cache_y[idx].clear();
    }
    inline void clear_cache () const {
        cache_n.clear(); cache_y.clear();
        cache_n.resize(n_samples, 0);
        cache_y.resize(n_samples);
    }
#endif

protected:
    REAL model_weight_sum () const {
        return std::accumulate
            (lm_wgt.begin(), lm_wgt.begin()+n_in_agg, REAL(0));
    }

    //@{ @name Common routines
    pLearnModel train_with_smpwgt (const pDataWgt&) const;
    //@}

    //@{ @name Traditional way
    /// Assign weight to a newly generated hypothesis
    /** We assume @a l is not but will be added.
     *  @param sw the sample weight used in training @a l.
     *  @param l the newly generated hypothesis.
     *  @return The weight of @a l. A nonpositive weight means the
     *  hypothesis @a l should not be added into the aggregation.
     */
    REAL assign_weight (const DataWgt& sw, const LearnModel& l) {
        assert(n_samples == sw.size());
        return convex? convex_weight(sw, l) : linear_weight(sw, l);
    }
    /// Update sample weights after adding the new hypothesis
    /** We assume @a l has just been added to the aggregation.
     *  @param sw the sample weight before adding @a l.
     *  @param l the newly added hypothesis.
     *  @return The updated sample weights.
     */
    pDataWgt update_smpwgt (const DataWgt& sw, const LearnModel& l) {
        assert(n_in_agg > 0 && lm[n_in_agg-1] == &l);
        assert(n_samples == sw.size());
        DataWgt* pdw = new DataWgt(sw);  // create a separate copy
        convex? convex_smpwgt(*pdw) : linear_smpwgt(*pdw);
        return pdw;
    }

    /** @copydoc assign_weight */
    virtual REAL convex_weight (const DataWgt&, const LearnModel&);
    virtual REAL linear_weight (const DataWgt&, const LearnModel&);
    virtual void convex_smpwgt (DataWgt&);
    virtual void linear_smpwgt (DataWgt&);
    //@}

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);

    //@{ @name Gradient-descent view
public:
    friend struct _boost_gd;
    REAL cost () const;

protected:
    virtual void train_gd ();       ///< Training using gradient-descent
    pDataWgt sample_weight () const;///< Sample weights for new hypothesis

public:
    /// Weight in gradient descent
    class BoostWgt {
        std::vector<pLearnModel> lm;
        std::vector<REAL> lm_wgt;

    public:
        BoostWgt () {}
        BoostWgt (const std::vector<pLearnModel>& _lm,
                  const std::vector<REAL>& _wgt)
            : lm(_lm), lm_wgt(_wgt) { assert(lm.size() == lm_wgt.size()); }

        UINT size () const { return lm.size(); }
        const std::vector<pLearnModel>& models () const { return lm; }
        const std::vector<REAL>& weights () const { return lm_wgt; }
        void clear () { lm.clear(); lm_wgt.clear(); }

        BoostWgt& operator+= (const BoostWgt&);
        BoostWgt& operator*= (REAL);
        BoostWgt operator- () const;
#ifndef NDEBUG
        bool operator== (const BoostWgt& w) const {
            return (lm == w.lm && lm_wgt == w.lm_wgt);
        }
#endif
    };
    //@}
};

struct _boost_gd {
    Boosting* b;
    UINT max_step;
    explicit _boost_gd (Boosting* pb) : b(pb)
    { max_step = b->max_n_model - b->size(); }

    REAL cost () const { return b->cost(); }

    Boosting::BoostWgt weight () const {
        return Boosting::BoostWgt(b->lm, b->lm_wgt);
    }

    void set_weight (const Boosting::BoostWgt& bw) const {
#if BOOSTING_OUTPUT_CACHE
        b->clear_cache();
#endif
        b->lm = bw.models(); b->lm_wgt = bw.weights();
        b->n_in_agg = b->lm.size();
        assert(b->lm.size() == b->lm_wgt.size());
        for (UINT i = 0; i < b->lm.size(); ++i)
            b->set_dimensions(*(b->lm[i]));
    }

    Boosting::BoostWgt gradient () const {
        std::vector<pLearnModel> lm = b->lm;
        std::vector<REAL> wgt(lm.size(), 0);

        lm.push_back(b->train_with_smpwgt(b->sample_weight()));
        wgt.push_back(-1);
        return Boosting::BoostWgt(lm, wgt);
    }

    bool stop_opt (UINT step, REAL cst) const {
        return (step >= max_step || cst < b->min_cst);
    }
};

namespace op {

template <typename R>
R inner_product (const Boosting::BoostWgt& w1, const Boosting::BoostWgt& w2) {
#ifndef NDEBUG
    std::vector<REAL> w1t(w1.size()); w1t.back() = -1;
    assert(w1.weights() == w1t);
    std::vector<REAL> w2t(w2.size()); w2t.back() = -1;
    assert(w2.weights() == w2t);
#endif
    LearnModel& g1 = *w1.models().back();
    LearnModel& g2 = *w2.models().back();

    UINT n = g1.train_data()->size();
    assert(g1.train_data() == g2.train_data());
    R sum = 0;
    for (UINT i = 0; i < n; ++i)
        sum += g1.get_output(i)[0] * g2.get_output(i)[0];
    return sum / n;
}

} // namespace lemga::op
} // namespace lemga

#ifdef  __BOOSTING_H__
#warning "This header file may conflict with another `boosting.h' file."
#endif
#define __BOOSTING_H__
#endif
