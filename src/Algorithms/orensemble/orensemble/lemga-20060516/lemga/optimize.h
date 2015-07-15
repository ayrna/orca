// -*- C++ -*-
#ifndef __LEMGA_OPTIMIZE_H__
#define __LEMGA_OPTIMIZE_H__

/** @file
 *  @brief Some generic optimization algorithms.
 *
 *  $Id: optimize.h 1917 2005-01-07 01:25:30Z ling $
 */

#include <assert.h>
#include <iostream>
#include <utility>
#include "vectorop.h"

namespace lemga {

using namespace op;

/** @brief Interface used in iterative optimization algorithms.
 *
 *  This template is used in joint with the generic optimization
 *  algorithm iterative_optimize(). It describes functions that a
 *  class have to provide in order to use iterative_optimize().
 *
 *  Some arithmetic operations on gradient are needed for optimization.
 *  The full set required consists of
 *   - @a u += @a v
 *   - -@a v
 *   - @a v *= @a r
 *   - inner_product<@a typename> (@a u, @a v)
 *  where @a u and @a v are weights/gradients and @a r the step length.
 *
 *  Using such interface improves the flexibility of code. However,
 *  there are always concerns about the performance. Here are
 *  several considerations for the sake of performance:
 *
 *  - The weight(s) is the variable to be ``searched'' in order to
 *    optimize the cost. It is assumed to be stored somewhere (say,
 *    in a derived class) and is not passed as a parameter to these
 *    functions.
 *  - direction() returns a const reference to a class member.
 *  - The inheritance of different methods doesn't mean the parent
 *    class could be changed without taking care of the classes
 *    derived from it. This is just used as a way to share functions.
 *  - step_lenth() return non-positive step length if the direction
 *    is improper. (It could have returned a pair<bool,REAL>.)
 *
 *  @todo Does making these functions pure virtual sacrifice
 *  the performance?
 */
template <class Dir, class Step>
struct _search {
    typedef Dir direction_type;
    typedef Step step_length_type;

    /// Initialize local variables.
    void initialize () {}
    /// Search direction at @a w.
    const Dir& direction () { return dir; }
    /// Should we go in direction @a d? How far?.
    std::pair<bool,Step> step_length (const Dir& d) {
        return std::make_pair(false, 0); }
    /// Update the weight.
    void update_weight (const Dir& d, const Step& s) {}
    /// Stopping criteria.
    bool satisfied () { return true; }
protected:
    Dir dir;
};

/// Main search routine.
template <class SEARCH>
void iterative_optimize (SEARCH s) {
    s.initialize();
    while (!s.satisfied()) {
        const typename SEARCH::direction_type&
            pd = s.direction();
        const std::pair<bool, typename SEARCH::step_length_type>
            stp = s.step_length(pd);

        if (!stp.first) break;
        s.update_weight(pd, stp.second);
    }
}

/** @brief Gradient descent.
 *  @todo Add options for on-line or batch mode; documentation
 *  Why use get_weight() and set_weight(), not update_weight()?
 *  (how much is the performance decrease)
 */
template <class LM, class Dir, class Step>
struct _gradient_descent : public _search<Dir,Step> {
    LM* plm;
    Step learning_rate;

    _gradient_descent (LM* lm, const Step& lr)
        : _search<Dir,Step>(), plm(lm), learning_rate(lr) {}

    void initialize () { stp_cnt = 0; w = plm->weight(); }

    const Dir& direction () {
        using namespace op;
        return (this->dir = -plm->gradient());
    }

    std::pair<bool,Step> step_length (const Dir&) {
        return std::make_pair(true, learning_rate);
    }

    void update_weight (Dir d, const Step& s) {
        using namespace op;
        w += (d *= s);
        ++stp_cnt; plm->set_weight(w);
    }

    bool satisfied () { return plm->stop_opt(stp_cnt, plm->cost()); }

protected:
    Dir w;
    unsigned int stp_cnt;
};

/** @brief Gradient descent with weight decay.
 *
 *  The cost function includes a regularization term which prefers
 *  smaller weight values. That is, the cost to be minimized is
 *  @f[ \hat{E} = E + \frac{\lambda}2 \Vert w\Vert^2. @f]
 *  The updating rule thus becomes @f[
 *    w \leftarrow w - \eta \frac{\partial\hat{E}}{\partial w}
 *     = (1-\eta\lambda)w - \eta\frac{\partial E}{\partial w}.
 *  @f]
 *  @f$\lambda@f$ usually ranges from 0.01 to 0.1.
 *
 *  @todo Well, I guess weight decay is more a term in the cost
 *  than an optimization technique. Though it is easy to add it
 *  here (as an optimization technique).
 */
template <class LM, class Dir, class Step>
struct _gd_weightdecay : public _gradient_descent<LM,Dir,Step> {
    Step decay;

    _gd_weightdecay (LM* lm, const Step& lr, const Step& dcy)
        : _gradient_descent<LM,Dir,Step>(lm,lr), decay(dcy) {}

    void update_weight (Dir d, const Step& s) {
        using namespace op;
        assert(s*decay < 1);
        this->w *= (1 - s*decay);
        this->w += (d *= s);
        ++this->stp_cnt; this->plm->set_weight(this->w);
    }
};

/** @brief Gradient descent with momentum.
 *
 *  With momentum, the weight change is accumulated: @f[
 *    \Delta w\leftarrow-\eta\frac{\partial E}{\partial w}+\mu\Delta w.
 *  @f]
 *  When the derivative is roughly constant, this speeds up the
 *  training by using an effectively larger learning rate @f[
 *    \Delta w \approx -\frac{\eta}{1-\mu}\frac{\partial E}{\partial w}.
 *  @f]
 *  When the derivative somehow ``fluctuates'', the momentum stablizes
 *  the optimization to some exent by effectively decreasing the
 *  learning rate.
 */
template <class LM, class Dir, class Step>
struct _gd_momentum : public _gradient_descent<LM,Dir,Step> {
    Step momentum;

    _gd_momentum (LM* lm, const Step& lr, const Step& m)
        : _gradient_descent<LM,Dir,Step>(lm,lr), momentum(m) {}

    const Dir& direction () {
        assert(momentum >= 0 && momentum < 1);
        using namespace op;
        if (this->stp_cnt > 0) {
            this->dir *= momentum;
            this->dir += -this->plm->gradient();
        }
        else this->dir = -this->plm->gradient();
        return this->dir;
    }
};

template <class LM, class Dir, class Step, class Cost>
struct _gd_adaptive : public _gradient_descent<LM,Dir,Step> {
    using _gradient_descent<LM,Dir,Step>::plm;
    using _gradient_descent<LM,Dir,Step>::learning_rate;
    using _gradient_descent<LM,Dir,Step>::w;
    using _gradient_descent<LM,Dir,Step>::stp_cnt;
    Step alpha, beta;

    _gd_adaptive (LM* lm, const Step& lr, const Step& a, const Step& b)
        : _gradient_descent<LM,Dir,Step>(lm,lr), alpha(a), beta(b) {}

    void initialize () {
        _gradient_descent<LM,Dir,Step>::initialize();
        old_cost = plm->cost();
    }

    std::pair<bool,Step> step_length (Dir d) {
        assert(alpha >= 1 && beta < 1);
        using namespace op;

        Step lr = learning_rate;

        d *= learning_rate;
        Dir wd = w;
        plm->set_weight(wd += d);
        Cost c = plm->cost();
        if (c < old_cost)
            learning_rate *= alpha;
        else {
            do {
                learning_rate *= beta;
                d *= beta; wd = w;
                plm->set_weight(wd += d);
                c = plm->cost();
            } while (!(c < old_cost) && learning_rate > 1e-6);
            lr = learning_rate;
        }

        const bool cont = (c < old_cost);
        if (cont) old_cost = c;
        else plm->set_weight(w);
        return std::make_pair(cont, lr);
    }

    void update_weight (Dir d, const Step& s) {
        ++stp_cnt;
        using namespace op;
        w += (d *= s);
        // DO NOT set_weight; done in step_length()
    }

    bool satisfied  () { return plm->stop_opt(stp_cnt, old_cost); }

protected:
    Cost old_cost;
};

namespace details {

template <class LM, class Dir, class Step, class Cost>
Step line_search (LM& lm, const Dir& w, Cost& cst3,
                  const Dir& dir, Step step) {
    using namespace op;
    assert(w == lm.weight());
    cst3 = lm.cost();
    Step stp3 = 0;

    Dir d = dir, wd = w; d *= step;
    lm.set_weight(wd += d); Cost cst5 = lm.cost();
    while (cst5 > cst3 && step > 2e-7) {
        //std::cout << '-';
        step *= 0.5; d *= 0.5; wd = w;
        lm.set_weight(wd += d); cst5 = lm.cost();
    }

    if (cst5 > cst3) {
        std::cerr << "\tWarning: not a descending direction\n";
        lm.set_weight(w);   // undo
        return 0;
    }

    Step stp1, stp5 = step;
    do {
        //std::cout << '*';
        step += step;
        stp1 = stp3;
        stp3 = stp5; cst3 = cst5;
        stp5 += step;
        d = dir; d *= stp5; wd = w;
        lm.set_weight(wd += d); cst5 = lm.cost();
    } while (cst5 < cst3);

    while (stp3 > stp1*1.01 || stp5 > stp3*1.01) {
        //std::cout << '.';
        Step stp2 = (stp1 + stp3) / 2;
        Step stp4 = (stp3 + stp5) / 2;
        d = dir; d *= stp2; wd = w;
        lm.set_weight(wd += d); Cost cst2 = lm.cost();
        d = dir; d *= stp4; wd = w;
        lm.set_weight(wd += d); Cost cst4 = lm.cost();

        if (cst4 < cst2 && cst4 < cst3) {
            stp1 = stp3;
            stp3 = stp4; cst3 = cst4;
        }
        else if (cst2 < cst3) {
            stp5 = stp3;
            stp3 = stp2; cst3 = cst2;
        }
        else {
            stp1 = stp2;
            stp5 = stp4;
        }
    }
    //std::cout << "\tcost = " << cst3 << ", step = " << stp3 << '\n';
    return stp3;
}

} // namespace lemga::details

template <class LM, class Dir, class Step, class Cost>
struct _line_search : public _gradient_descent<LM,Dir,Step> {
    using _gradient_descent<LM,Dir,Step>::plm;
    using _gradient_descent<LM,Dir,Step>::learning_rate;
    using _gradient_descent<LM,Dir,Step>::w;
    using _gradient_descent<LM,Dir,Step>::stp_cnt;

    _line_search (LM* lm, const Step& lr)
        : _gradient_descent<LM,Dir,Step>(lm,lr) {}

    void initialize () {
        _gradient_descent<LM,Dir,Step>::initialize();
        cost_w = plm->cost();
    }

    std::pair<bool,Step> step_length (const Dir& d) {
        const Step stp =
            details::line_search(*plm, w, cost_w, d, learning_rate);
        return std::make_pair((stp>0), stp);
    }

    bool satisfied () { return plm->stop_opt(stp_cnt, cost_w); }

protected:
    Cost cost_w;
};

template <class LM, class Dir, class Step, class Cost>
struct _conjugate_gradient : public _line_search<LM,Dir,Step,Cost> {
    using _gradient_descent<LM,Dir,Step>::plm;
    using _gradient_descent<LM,Dir,Step>::w;
    using _gradient_descent<LM,Dir,Step>::stp_cnt;
    using _search<Dir,Step>::dir;

    _conjugate_gradient (LM* lm, const Step& lr)
        : _line_search<LM,Dir,Step,Cost>(lm,lr) {}

    const Dir& direction () {
        // get g
        const Dir g = plm->gradient();
        const Step g_norm = op::inner_product<Step>(g, g);

        using namespace op;
        // get d
        if (stp_cnt == 0)
            dir = -g;
        else {
            const Step g_dot_old = op::inner_product<Step>(g, g_old);
            assert(g_norm_old > 0);
            Step beta = (g_norm - g_dot_old) / g_norm_old;
            if (beta < 0) beta = 0;

            dir *= beta;
            dir += -g;
        }

        g_old = g;
        g_norm_old = g_norm;

        return dir;
    }

private:
    Dir g_old;
    Step g_norm_old;
};

} // namespace lemga

#ifdef  __OPTIMIZE_H__
#warning "This header file may conflict with another `optimize.h' file."
#endif
#define __OPTIMIZE_H__
#endif
