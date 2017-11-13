/**
   softperc.cpp: a perceptron model with sigmoid outputs
   (c) 2006-2007 Hsuan-Tien Lin
   (some code copied from perceptron.cpp in LEMGA (c) Ling Li)
**/
#include <assert.h>
#include <cmath>
#include <numeric>
#include "softperc.h"

REGISTER_CREATOR(lemga::SoftPerc);

#define INPUT_SUM(w,x)  \
    std::inner_product(x.begin(), x.end(), w.begin(), w.back())

namespace lemga {

Output SoftPerc::operator() (const Input& x) const {
    assert(x.size() == n_input());
    REAL sum = INPUT_SUM(wgt, x);
    return Output(1, tanh(scale * sum));
}

typedef std::vector<REAL> RVEC;
typedef std::vector<RVEC> RMAT;

#define DOTPROD(x,y) std::inner_product(x.begin(), x.end(), y.begin(), .0)
// The version without bias
#define DOTPROD_NB(x,y) std::inner_product(x.begin(),x.end()-1,y.begin(),.0)

inline void normalize (RVEC& v, REAL thr = 0) {
    REAL s = DOTPROD(v, v);
    assert(s > 0);
    if (s <= thr) return;
    s = 1 / std::sqrt(s);
    for (RVEC::iterator p = v.begin(); p != v.end(); ++p)
        *p *= s;
}

void SoftPerc::train() {
    Perceptron::train();
    normalize(wgt);
}

bool SoftPerc::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(Perceptron, os, vl, 1);

    return (os << scale << '\n');
}

bool SoftPerc::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(Perceptron, is, vl, 1, v);

    return (is >> scale);
}

} // namespace lemga
