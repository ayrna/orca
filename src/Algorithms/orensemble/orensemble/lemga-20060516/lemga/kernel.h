// -*- C++ -*-
#ifndef __LEMGA_KERNEL_H__
#define __LEMGA_KERNEL_H__

/** @file
 *  @brief Kernels for SVM etc.
 *
 *  $Id: kernel.h 2611 2006-02-02 21:53:30Z ling $
 */

#include <cmath>
#include <numeric>
#include "learnmodel.h"

#define DOTPROD(x,y) std::inner_product(x.begin(), x.end(), y.begin(), .0)

namespace lemga {

// only for LIBSVM, see Kernel::set_params.
struct SVM_detail;

namespace kernel {

inline REAL norm_1 (const Input& u, const Input& v) {
    REAL sum(0);
    Input::const_iterator x = u.begin(), y = v.begin();
    for (; x != u.end(); ++x, ++y)
        sum += std::fabs(*x - *y);
    return sum;
}

inline REAL norm_2 (const Input& u, const Input& v) {
    REAL sum(0);
    Input::const_iterator x = u.begin(), y = v.begin();
    for (; x != u.end(); ++x, ++y) {
        REAL d = *x - *y;
        sum += d * d;
    }
    return sum;
}

/// The operator() gives the inner-product in the transformed space.
class Kernel : public Object {
public:
    virtual Kernel* create () const = 0;
    virtual Kernel* clone () const = 0;

    /// The inner-product of two input vectors.
    virtual REAL operator() (const Input&, const Input&) const = 0;
    /// Store a dataset in order to compute the kernel matrix.
    virtual void set_data (const pDataSet& pd) { ptd = pd; }
    /// The inner-product of two stored inputs with index @a i and @a j.
    virtual REAL matrix (UINT i, UINT j) const
    { return operator()(ptd->x(i), ptd->x(j)); }

    /// In order to keep the SVM interface simple and avoid
    /// member functions specific to kernels (e.g., set_gamma()),
    /// we use Kernel to pass kernel parameters to SVM_detail.
    virtual void set_params (SVM_detail*) const = 0;

protected:
    pDataSet ptd;
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

/// %Linear kernel @f$\left<u,v\right>@f$.
struct Linear : public Kernel {
    Linear () {}
    explicit Linear (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual Linear* create () const { return new Linear(); }
    virtual Linear* clone () const { return new Linear(*this); }

    virtual REAL operator() (const Input& a, const Input& b) const {
        return DOTPROD(a, b);
    }
    virtual void set_params (SVM_detail*) const;
};

/// %Polynomial kernel @f$(\gamma*\left<u,v\right>+c_0)^d@f$.
struct Polynomial : public Kernel {
    UINT degree;
    REAL gamma, coef0;

    Polynomial (UINT d = 3, REAL g = 0.5, REAL c0 = 0)
        : degree(d), gamma(g), coef0(c0) {};
    explicit Polynomial (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual Polynomial* create () const { return new Polynomial(); }
    virtual Polynomial* clone () const { return new Polynomial(*this); }

    virtual REAL operator() (const Input& a, const Input& b) const {
        return std::pow(gamma * DOTPROD(a, b) + coef0, (double) degree);
    }
    virtual void set_params (SVM_detail*) const;

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

/// %Stump kernel @f$-\left|u-v\right|_1@f$.
struct Stump : public Kernel {
    Stump () {}
    explicit Stump (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual Stump* create () const { return new Stump(); }
    virtual Stump* clone () const { return new Stump(*this); }

    virtual REAL operator() (const Input& a, const Input& b) const {
        return -norm_1(a, b);
    }
    virtual void set_params (SVM_detail*) const;
};

/// %Perceptron kernel @f$-\left|u-v\right|_2@f$.
struct Perceptron : public Kernel {
protected:
    std::vector<REAL> x_norm2; ///< cached inner-product of data input

public:
    Perceptron () {}
    explicit Perceptron (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual Perceptron* create () const { return new Perceptron(); }
    virtual Perceptron* clone () const { return new Perceptron(*this); }

    virtual REAL operator() (const Input& a, const Input& b) const {
        return -std::sqrt(norm_2(a, b));
    }

    virtual void set_data (const pDataSet& pd) {
        Kernel::set_data(pd);
        const UINT n = ptd->size();
        x_norm2.resize(n);
        for (UINT i = 0; i < n; ++i)
            x_norm2[i] = DOTPROD(ptd->x(i), ptd->x(i));
    }
    virtual REAL matrix (UINT i, UINT j) const {
        REAL n2 = x_norm2[i] + x_norm2[j] - 2*DOTPROD(ptd->x(i), ptd->x(j));
        return (n2 > 0)? -std::sqrt(n2) : 0;   // avoid -0.0
    }

    virtual void set_params (SVM_detail*) const;
};

/// %RBF (Gausssian) kernel @f$e^{-\gamma\left|u-v\right|_2^2}@f$.
struct RBF : public Perceptron {
    REAL gamma;
    explicit RBF (REAL g = 0.5) : gamma(g) {}
    explicit RBF (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual RBF* create () const { return new RBF(); }
    virtual RBF* clone () const { return new RBF(*this); }

    virtual REAL operator() (const Input& a, const Input& b) const {
        return std::exp(-gamma * norm_2(a, b));
    }

    virtual REAL matrix (UINT i, UINT j) const {
        REAL n2 = x_norm2[i] + x_norm2[j] - 2*DOTPROD(ptd->x(i), ptd->x(j));
        return std::exp(-gamma * n2);
    }

    virtual void set_params (SVM_detail*) const;

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

/// %Sigmoid kernel @f$\tanh(\gamma\left<u,v\right>+c_0)@f$.
struct Sigmoid : public Kernel {
    REAL gamma, coef0;
    Sigmoid (REAL g = 0.5, REAL c0 = 0) : gamma(g), coef0(c0) {};
    explicit Sigmoid (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual Sigmoid* create () const { return new Sigmoid(); }
    virtual Sigmoid* clone () const { return new Sigmoid(*this); }

    virtual REAL operator() (const Input& a, const Input& b) const {
        return std::tanh(gamma * DOTPROD(a, b) + coef0);
    }
    virtual void set_params (SVM_detail*) const;

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

}} // namespace lemga::kernel

#ifdef  __KERNEL_H__
#warning "This header file may conflict with another `kernel.h' file."
#endif
#define __KERNEL_H__
#endif
