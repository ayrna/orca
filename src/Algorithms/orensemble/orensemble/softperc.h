/**
   softperc.h: a perceptron model with sigmoid outputs
   (c) 2006-2007 Hsuan-Tien Lin
**/
#ifndef __LEMGA_SOFTPERC_H__
#define __LEMGA_SOFTPERC_H__

#include <vector>
#include <perceptron.h>

namespace lemga {

/** SoftPerc outputs tanh(scale * (w^T x + b))
 *  instead of sign(w^T x + b)
 */
class SoftPerc : public Perceptron {
private:
    REAL scale;

public:
    explicit SoftPerc (UINT n_in = 0) : Perceptron(n_in), scale(1.0) {}
    explicit SoftPerc (std::istream& is) { is >> *this; }

    void set_scale(REAL _scale) { assert(scale > 0); scale = _scale; };
    virtual const id_t& id () const;
    virtual SoftPerc* create () const { return new SoftPerc(); }
    virtual SoftPerc* clone () const { return new SoftPerc(*this); }

    virtual Output operator() (const Input&) const;

    virtual void train();

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);

};

} // namespace lemga

#ifdef  __SOFTPERC_H__
#warning "This header file may conflict with another `softperc.h' file."
#endif
#define __SOFTPERC_H__
#endif
