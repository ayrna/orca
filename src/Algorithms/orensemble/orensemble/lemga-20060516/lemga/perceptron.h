// -*- C++ -*-
#ifndef __LEMGA_PERCEPTRON_H__
#define __LEMGA_PERCEPTRON_H__

/** @file
 *  @brief @link lemga::Perceptron Perceptron@endlink class.
 *
 *  $Id: perceptron.h 2891 2006-11-08 03:17:31Z ling $
 */

#include <vector>
#include "learnmodel.h"
#include "svm.h"

namespace lemga {

/** @brief %Perceptron models a type of artificial neural network that
 *  consists of only one neuron, invented by Frank Rosenblatt in 1957.
 *
 *  We use the convention that @f$w_0@f$ is the negative threshold,
 *  or equivalently, letting @f$x_0=1@f$. When presented with input
 *  @f$x@f$, the perceptron outputs
 *  @f[ o = \theta(s),\quad s=\sum_i w_ix_i, @f]
 *  where @f$\theta(\cdot)@f$ is usually the sign function,
 *
 *  The learning algorithm updates the weight according to
 *  @f[ w^{(t+1)} = w^{(t)} + \eta (y-o) x, @f]
 *  where @f$y@f$ is the desired output. If @f$\theta@f$ is the sign,
 *  the learning rate @f$\eta@f$ can be omitted since it just scales
 *  @f$w@f$.
 *
 *  @note If @f$o@f$ is replaced by @f$s@f$, the sum before the function
 *  @f$\theta@f$, the algorithm is then called the ADALINE learning.
 */
class Perceptron : public LearnModel {
public:
    typedef std::vector<REAL> WEIGHT;
    enum TRAIN_METHOD {
        // These are known algorithms
        PERCEPTRON,          // Rosenblatt's learning rule
        ADALINE,
        POCKET,              // Gallant's pocket algorithm
        POCKET_RATCHET,
        AVE_PERCEPTRON,      // Freund's average-perceptron
        ROMMA,
        ROMMA_AGG,
        SGD_HINGE,           // Zhang's stochastic gradient descent
        SGD_MLSE,            // on SVM hinge loss or modified least square
        // These are the recommended ones of my algorithms
        RCD,
        RCD_BIAS,
        RCD_GRAD,
        // Below are just for research comparison
        AVE_PERCEPTRON_RAND,
        ROMMA_RAND,
        ROMMA_AGG_RAND,
        COORDINATE_DESCENT,
        FIXED_RCD,
        FIXED_RCD_CONJ,
        FIXED_RCD_BIAS,
        FIXED_RCD_CONJ_BIAS,
        RCD_CONJ,
        RCD_CONJ_BIAS,
        RCD_GRAD_BATCH,
        RCD_GRAD_RAND,
        RCD_GRAD_BATCH_RAND,
        RCD_MIXED,
        RCD_GRAD_MIXED,
        RCD_GRAD_MIXED_INITRAND,
        RCD_GRAD_MIXED_BATCH,
        RCD_GRAD_MIXED_BATCH_INITRAND,
        // Old definitions
        RAND_COOR_DESCENT = RCD,
        RAND_COOR_DESCENT_BIAS = RCD_BIAS,
        RAND_CONJ_DESCENT = RCD_CONJ,
        RAND_CONJ_DESCENT_BIAS = RCD_CONJ_BIAS,
        GRADIENT_COOR_DESCENT_ONLINE = RCD_GRAD
    };

protected:
    WEIGHT wgt;      ///< wgt.back() is the bias
    // only for online-type algorithms; RCD always uses reweighting
    bool resample;   ///< reweighting or resampling
    TRAIN_METHOD train_method;
    REAL learn_rate, min_cst;
    UINT max_run;
    bool with_fld;   ///< start training with FLD?
    bool fixed_bias; ///< using a fixed bias?

public:
    explicit Perceptron (UINT n_in = 0);
    Perceptron (const SVM&);
    explicit Perceptron (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual Perceptron* create () const { return new Perceptron(); }
    virtual Perceptron* clone () const { return new Perceptron(*this); }

    WEIGHT weight () const { return wgt; }
    void set_weight (const WEIGHT&);

    void start_with_fld (bool b = true) { with_fld = b; }
    void set_fixed_bias (bool b = false) { fixed_bias = b; }
    void use_resample (bool s = true) { resample = true; }
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
    WEIGHT fld () const;
    virtual void train ();
    virtual Output operator() (const Input&) const;

    virtual REAL margin_norm () const { return w_norm(); }
    virtual REAL margin_of (const Input&, const Output&) const;
    REAL w_norm () const;

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
    virtual void log_error (UINT, REAL = -1) const;
};

} // namespace lemga

#ifdef  __PERCEPTRON_H__
#warning "This header file may conflict with another `perceptron.h' file."
#endif
#define __PERCEPTRON_H__
#endif
