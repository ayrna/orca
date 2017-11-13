// -*- C++ -*-
#ifndef __LEMGA_NNLAYER_H__
#define __LEMGA_NNLAYER_H__

/** @file
 *  @brief Neural network layer @link lemga::NNLayer NNLayer@endlink.
 *
 *  $Id: nnlayer.h 2664 2006-03-07 19:50:51Z ling $
 */

#include <vector>
#include "learnmodel.h"

namespace lemga {

/** @brief A layer in a neural network.
 *
 *  This class simulates a layer of neurons.
 *
 *  Here's usage information.
 *
 *  Here's some details.
 *
 *  Say, we have @a n neurons and @a m inputs. The output from
 *  the neuron is
 *  @f[ y_i=\theta(s_i),\quad s_i=\sum_{j=0}^m w_{ij}x_j, @f]
 *  where @f$s_i@f$ is the weighted sum of inputs, @f$x_0\equiv1@f$,
 *  and @f$w_{i0}@f$ is sort of the threshold. feed_forward() does
 *  this calculation and saves @f$\theta'(s_i)@f$ for future use.
 *
 *  The ``chain rule'' for back-propagation says the derative w.r.t.
 *  the input @a x can be calculated from that to the output @a y.
 *  Define @f[
 *   \delta_i \stackrel\Delta= \frac{\partial E}{\partial s_i}
 *     = \frac{\partial E}{\partial y_i}\frac{\partial y_i}{\partial s_i}
 *     = \frac{\partial E}{\partial y_i}\theta'(s_i). @f]
 *  We have @f[
 *   \frac{\partial E}{\partial w_{ij}}
 *     = \frac{\partial E}{\partial s_i}
 *         \frac{\partial s_i}{\partial w_{ij}}
 *     = \delta_i x_j,\quad
 *   \frac{\partial E}{\partial x_j}
 *     = \sum_{i=1}^n \frac{\partial E}{\partial s_i}
 *         \frac{\partial s_i}{\partial x_j}
 *     = \sum_{i=1}^n \delta_i w_{ij}. @f]
 *  These equations consitute the essense of back_propagate().
 *
 *  Modifying sigmoid() (which computes @f$\theta@f$) and
 *  sigmoid_deriv() (which computes @f$\theta'@f$) is usually enough
 *  to get a different type of layer.
 *  @todo documentation
 */
class NNLayer : public LearnModel {
    mutable REAL stored_sigmoid;

public:
    typedef std::vector<REAL> WVEC; ///< weight vector
    typedef std::vector<REAL> DVEC; ///< derivative vector

protected:
    REAL w_min, w_max;
    WVEC w;   ///< weights and thresholds
    WVEC dw;  ///< deravatives: @a w -= lr * @a dw
    mutable DVEC sig_der;  // f'(wsum)

public:
    explicit NNLayer (UINT n_in = 0, UINT n_unit = 0);
    explicit NNLayer (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual NNLayer* create () const { return new NNLayer(); }
    virtual NNLayer* clone () const { return new NNLayer(*this); }

    UINT size () const { return n_output(); }

    void set_weight_range (REAL min, REAL max) {
        assert(min < max);
        w_min = min; w_max = max;
    }
    const WVEC& weight () const { return w; }
    void set_weight (const WVEC&);

    const WVEC& gradient () const { return dw; }
    void clear_gradient ();

    virtual void initialize ();
    virtual void train () { OBJ_FUNC_UNDEFINED("train"); }
    virtual Output operator() (const Input& x) const {
        Output y(n_output());
        feed_forward(x, y);
        return y;
    }

    void feed_forward (const Input&, Output&) const;
    void back_propagate (const Input&, const DVEC&, DVEC&);

protected:
    virtual REAL sigmoid (REAL) const;
    virtual REAL sigmoid_deriv (REAL) const;
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

} // namespace lemga

#ifdef  __NNLAYER_H__
#warning "This header file may conflict with another `nnlayer.h' file."
#endif
#define __NNLAYER_H__
#endif
