// -*- C++ -*-
#ifndef __LEMGA_COST_H__
#define __LEMGA_COST_H__

/** @file
 *  @brief Cost functions (functors) used in learning
 *
 *  $Id: cost.h 2537 2006-01-08 08:40:36Z ling $
 */

#include <cmath>
#include "object.h"

namespace lemga {
namespace cost {

template <typename _Num>
struct AdaCost {
    virtual ~AdaCost () { /* get rid of GCC 4.0 warnings */ }
    virtual _Num cost (const _Num& F, const _Num& y) const {
        assert(std::fabs(y*y-1) < INFINITESIMAL);
        return std::exp(-(F * y));
    }
    inline _Num operator() (const _Num& F, const _Num& y) const
    { return cost(F, y); }

    virtual _Num deriv1 (const _Num& F, const _Num& y) const {
        assert(std::fabs(y*y-1) < INFINITESIMAL);
        return -std::exp(- (F * y)) * y;
    }
};

/* A temporary workaround: Using real class instead of functor */
typedef AdaCost<REAL> Cost;

const Cost _cost = Cost();

struct exponential : public Cost {
    REAL lambda;
    exponential () : lambda(1) {};
    virtual REAL cost (const REAL& F, const REAL& y) const {
        return std::exp(-lambda*F*y);
    }
    virtual REAL deriv1 (const REAL& F, const REAL& y) const {
        return -lambda*y * std::exp(-lambda*F*y);
    }
};

struct logistic : public Cost {
    REAL lambda;
    logistic () : lambda(1) {};
    virtual REAL cost (const REAL& F, const REAL& y) const {
        return std::log(1 + std::exp(-lambda*F*y));
    }
    virtual REAL deriv1 (const REAL& F, const REAL& y) const {
        const REAL t = std::exp(-lambda*F*y);
        return -lambda*y * t / (1+t);
    }
};

struct sigmoid : public Cost {
    REAL lambda;
    sigmoid () : lambda(1) {};
    virtual REAL cost (const REAL& F, const REAL& y) const {
        return 1 - std::tanh(lambda*F*y);
    }
    virtual REAL deriv1 (const REAL& F, const REAL& y) const {
        const REAL t = std::tanh(lambda*F*y);
        return lambda*y * (t*t - 1);
    }
};

struct bisigmoid : public Cost {
    REAL lambda;
    REAL ratio;   ///< ratio = lambda_neg / lambda <= 1
    bisigmoid () : lambda(1), ratio(0.8) {};
    virtual REAL cost (const REAL& F, const REAL& y) const {
        const REAL m = lambda*F*y;
        if (m > 0) return 1 - std::tanh(m)/lambda;
        return 1 - std::tanh(ratio*m)/(ratio*lambda);
    }
    virtual REAL deriv1 (const REAL& F, const REAL& y) const {
        const REAL m = lambda*F*y;
        const REAL t = std::tanh(m>0? m:(ratio*m));
        return y * (t*t - 1);
    }
};

}} // namespace lemga::cost

#ifdef  __COST_H__  // check duplicate filenames
#warning "This header file may conflict with another `cost.h' file."
#endif
#define __COST_H__
#endif
