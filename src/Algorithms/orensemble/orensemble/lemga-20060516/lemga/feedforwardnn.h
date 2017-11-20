// -*- C++ -*-
#ifndef __LEMGA_FEEDFORWARDNN_H__
#define __LEMGA_FEEDFORWARDNN_H__

/** @file
 *  @brief Feed-forward neural network.
 *
 *  $Id: feedforwardnn.h 2664 2006-03-07 19:50:51Z ling $
 */

#include <vector>
#include "learnmodel.h"
#include "nnlayer.h"

namespace lemga {

/** @todo documentation */
class FeedForwardNN : public LearnModel {
    void free_space ();
    void forward (const Input& x) const {
        assert(n_layer > 0 && x.size() == n_input());
        layer[1]->feed_forward(x, _y[1]);
        for (UINT i = 2; i <= n_layer; ++i)
            layer[i]->feed_forward(_y[i-1], _y[i]);
    }

public:
    typedef std::vector<NNLayer::WVEC> WEIGHT;
    enum TRAIN_METHOD {
        GRADIENT_DESCENT,
        LINE_SEARCH,
        CONJUGATE_GRADIENT,
        WEIGHT_DECAY,
        ADAPTIVE_LEARNING_RATE
    };

protected:
    UINT n_layer;                   ///< # of layers == layer.size()-1.
    std::vector<NNLayer*> layer;    ///< layer pointers (layer[0] == 0).
    mutable std::vector<Output> _y; ///< buffer for outputs.
    mutable std::vector<Output> _dy;///< buffer for derivatives.

    bool online_learn;
    TRAIN_METHOD train_method;
    REAL learn_rate, min_cst;
    UINT max_run;

public:
    FeedForwardNN ();
    FeedForwardNN (const FeedForwardNN&);
    explicit FeedForwardNN (std::istream& is) { is >> *this; }
    virtual ~FeedForwardNN ();
    const FeedForwardNN& operator= (const FeedForwardNN&);

    virtual const id_t& id () const;
    virtual FeedForwardNN* create () const { return new FeedForwardNN(); }
    virtual FeedForwardNN* clone () const {
        return new FeedForwardNN(*this); }

    UINT size () const { return n_layer; }
    const NNLayer& operator[] (UINT n) const { return *layer[n+1]; }
    void add_top (const NNLayer&);
    void add_bottom (const NNLayer&);

    void set_batch_mode (bool b = true) { online_learn = !b; }
    void set_train_method (TRAIN_METHOD m) { train_method = m; }
    /** @param lr learning rate.
     *  @param mincst minimal cost (error) need to be achieved during
     *         training.
     *  @param maxrun maximal # of epochs the training should take.
     */
    void set_parameter (REAL lr, REAL mincst, UINT maxrun) {
        learn_rate = lr; min_cst = mincst; max_run = maxrun; }

    virtual bool support_weighted_data () const { return true; }
    virtual void initialize ();
    virtual void train ();
    virtual Output operator() (const Input&) const;

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);

    virtual REAL _cost (const Output& F, const Output& y) const {
        return r_error(F, y); }
    virtual Output _cost_deriv (const Output& F, const Output& y) const;
    virtual void log_cost (UINT epoch, REAL err);

public:
    WEIGHT weight () const;
    void set_weight (const WEIGHT&);

    REAL cost (UINT idx) const;
    REAL cost () const;
    WEIGHT gradient (UINT idx) const;
    WEIGHT gradient () const;
    void clear_gradient () const;

    bool stop_opt (UINT step, REAL cst);
};

} // namespace lemga

#ifdef  __FEEDFORWARDNN_H__
#warning "This header file may conflict with another `feedforwardnn.h' file."
#endif
#define __FEEDFORWARDNN_H__
#endif
