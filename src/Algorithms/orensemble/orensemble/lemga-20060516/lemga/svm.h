// -*- C++ -*-
#ifndef __LEMGA_SVM_H__
#define __LEMGA_SVM_H__

/** @file
 *  @brief A LEMGA interface to LIBSVM.
 *
 *  $Id: svm.h 2664 2006-03-07 19:50:51Z ling $
 */

#include "learnmodel.h"
#include "kernel.h"

namespace lemga {

/// Hide LIBSVM details so other files don't need to include LIBSVM header.
struct SVM_detail;

class SVM : public LearnModel {
private:
    SVM_detail *detail;
    kernel::Kernel *ker;
    // Why not var_shared_ptr? because kernel is not meant to be shared
    REAL regC;              // regularization parameter C
    std::vector<Input> sv;  // support vectors
    std::vector<REAL> coef; // @f$y_i\alpha_i@f$
    REAL coef0;             // the bias

public:
    explicit SVM (UINT n_in = 0);
    explicit SVM (const kernel::Kernel&, UINT n_in = 0);
    SVM (const SVM&);
    explicit SVM (std::istream&);
    virtual ~SVM ();
    const SVM& operator= (const SVM&);

    virtual const id_t& id () const;
    virtual SVM* create () const { return new SVM(); }
    virtual SVM* clone () const { return new SVM(*this); }

    REAL C () const { return regC; }
    void set_C (REAL c) { regC = c; }
    UINT n_support_vectors () const { return sv.size(); }
    const Input& support_vector (UINT i) const { return sv[i]; }
    /// @return @f$y_i\alpha_i@f$
    REAL support_vector_coef (UINT i) const { return coef[i]; }
    REAL bias () const { return coef0; }
    const kernel::Kernel& kernel () const { return *ker; }
    REAL kernel (const Input&, const Input&) const;
    void set_kernel (const kernel::Kernel&);

    virtual bool support_weighted_data () const { return true; }
    virtual void initialize ();
    virtual void train ();

    virtual Output operator() (const Input&) const;
    virtual REAL margin_norm () const { return w_norm(); }
    virtual REAL margin_of (const Input&, const Output&) const;
    REAL w_norm () const;

protected:
    /// Gives the signed belief for 2-class problems
    /// (positive belief means the larger label)
    REAL signed_margin (const Input&) const;
    void reset_model ();
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

} // namespace lemga

#ifdef  __SVM_H__
#warning "This header file may conflict with another `svm.h' file."
#endif
#define __SVM_H__
#endif
