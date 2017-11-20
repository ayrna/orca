/** @file
 *  Register kernel creators.
 *  $Id: kernel.cpp 2551 2006-01-17 04:31:27Z ling $
 */

#include "kernel.h"

REGISTER_CREATOR2(lemga::kernel::Linear,     k_lin);
REGISTER_CREATOR2(lemga::kernel::Polynomial, k_pol);
REGISTER_CREATOR2(lemga::kernel::Stump,      k_stu);
REGISTER_CREATOR2(lemga::kernel::Perceptron, k_per);
REGISTER_CREATOR2(lemga::kernel::RBF,        k_rbf);
REGISTER_CREATOR2(lemga::kernel::Sigmoid,    k_sig);

namespace lemga {
namespace kernel {

bool Kernel::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(Object, os, vl, 1);
    return os;
}

bool Kernel::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(Object, is, vl, 1, v);
    assert(v > 0);
    return true;
}

bool Polynomial::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(Kernel, os, vl, 1);
    return (os << degree << ' ' << gamma << ' ' << coef0 << '\n');
}

bool
Polynomial::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(Kernel, is, vl, 1, v);
    assert(v > 0);
    return (is >> degree >> gamma >> coef0) && (gamma > 0);
}

bool RBF::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(Kernel, os, vl, 1);
    return (os << gamma << '\n');
}

bool RBF::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(Kernel, is, vl, 1, v);
    assert(v > 0);
    return (is >> gamma) && (gamma > 0);
}

bool Sigmoid::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(Kernel, os, vl, 1);
    return (os << gamma << ' ' << coef0 << '\n');
}

bool Sigmoid::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(Kernel, is, vl, 1, v);
    assert(v > 0);
    return (is >> gamma >> coef0) && (gamma > 0);
}

}} // namespace lemga::kernel
