/** @file
 *  $Id: learnmodel.cpp 2664 2006-03-07 19:50:51Z ling $
 */

#include <assert.h>
#include <cmath>
#include <sstream>
#include <stdio.h>
#include "learnmodel.h"

namespace lemga {

/** A local helper for load_data */
static DataSet*
load_data (DataSet* pd, std::istream& is, UINT n, UINT in, UINT out) {
    for (UINT i = 0; i < n; ++i) {
        Input x(in);
        Output y(out);
        for (UINT j = 0; j < in; ++j)
            if (!(is >> x[j])) return pd;
        for (UINT j = 0; j < out; ++j)
            if (!(is >> y[j])) return pd;

        pd->append(x, y);
    }
    return pd;
}

/** Each sample consists of first the input and then the output.
 *  Numbers are separated by spaces.
 *  @param is the input stream
 *  @param n gives the number of samples
 *  @param in is the dimension of input
 *  @param out is the dimension of output
 *  @todo documentation: why separate function
 */
DataSet* load_data (std::istream& is, UINT n, UINT in, UINT out) {
    DataSet* pd = new DataSet();
    return load_data(pd, is, n, in, out);
}

/** An easier-to-use version, where the output dimension is fixed
 *  at 1, and the input dimension is auto-detected. This version
 *  requires that each row of stream @a is should be a sample.
 */
DataSet* load_data (std::istream& is, UINT n) {
    assert(n > 0);
    /* read the first line and infer the input dimension */
    Input x;
    do {
        char line[1024*10];
        is.getline(line, 1024*10);
        std::istringstream iss(line);
        REAL xi;
        while (iss >> xi)
            x.push_back(xi);
    } while (x.empty() && !is.eof());
    if (x.empty()) return 0;

    Output y(1, x.back());
    x.pop_back();

    DataSet* pd = new DataSet();
    pd->append(x, y);
    return load_data(pd, is, n-1, x.size(), 1);
}

/** @param n_in is the dimension of input.
 *  @param n_out is the dimension of output. */
LearnModel::LearnModel (UINT n_in, UINT n_out)
    : Object(), _n_in(n_in), _n_out(n_out), n_samples(0), logf(NULL)
{ /* empty */ }

bool LearnModel::serialize (std::ostream& os,
                            ver_list& vl) const {
    SERIALIZE_PARENT(Object, os, vl, 1);
    return (os << _n_in << ' ' << _n_out << '\n');
}

bool LearnModel::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    assert(d == NIL_ID);
    UNSERIALIZE_PARENT(Object, is, vl, 1, v);
    _n_in = 0; _n_out = 0;
    ptd = 0; ptw = 0; n_samples = 0;
    if (v == 0) return true;
    return (is >> _n_in >> _n_out);
}

/** @param out is the output from the learned hypothesis.
 *  @param y is the real output.
 *  @return Regression error between @a out and @a y.
 *  A commonly used measure is the squared error.
 */
REAL LearnModel::r_error (const Output& out, const Output& y) const {
    assert(out.size() == n_output());
    assert(y.size() == n_output());

    REAL err = 0;
    for (UINT i = 0; i < _n_out; ++i) {
        REAL dif = out[i] - y[i];
        err += dif * dif;
    }
    return err / 2;
}

/** @param out is the output from the learned hypothesis.
 *  @param y is the real output.
 *  @return Classification error between @a out and @a y.
 *  The error measure is not necessary symmetric. A commonly used
 *  measure is @a out != @a y.
 */
REAL LearnModel::c_error (const Output& out, const Output& y) const {
    assert(n_output() == 1);
    assert(std::fabs(std::fabs(y[0]) - 1) < INFINITESIMAL);
    return (out[0]*y[0] <= 0);
}

REAL LearnModel::train_r_error () const {
    assert(ptw != 0);
    REAL err = 0;
    for (UINT i = 0; i < n_samples; ++i)
        err += (*ptw)[i] * r_error(get_output(i), ptd->y(i));
    return err;
}

REAL LearnModel::train_c_error () const {
    assert(ptw != 0);
    REAL err = 0;
    for (UINT i = 0; i < n_samples; ++i)
        err += (*ptw)[i] * c_error(get_output(i), ptd->y(i));
    return err;
}

REAL LearnModel::test_r_error (const pDataSet& pd) const {
    UINT n = pd->size();
    REAL err = 0;
    for (UINT i = 0; i < n; ++i)
        err += r_error((*this)(pd->x(i)), pd->y(i));
    return err / n;
}

REAL LearnModel::test_c_error (const pDataSet& pd) const {
    UINT n = pd->size();
    REAL err = 0;
    for (UINT i = 0; i < n; ++i)
        err += c_error((*this)(pd->x(i)), pd->y(i));
    return err / n;
}

/** If the learning model/algorithm can only do training using uniform
 *  sample weight, i.e., support_weighted_data() returns @c false, a
 *  ``boostrapped'' copy of the original data set will be generated and
 *  used in the following training. The boostrapping is done by randomly
 *  pick samples (with replacement) w.r.t. the given weight @a pw.
 *
 *  In order to make the life easier, when support_weighted_data() returns
 *  @c true, a null @a pw will be replaced by a uniformly distributed
 *  probability vector. So we have the following invariant
 *  @invariant support_weighted_data() == (@a ptw != 0)
 *
 *  @param pd gives the data set.
 *  @param pw gives the sample weight, whose default value is 0.
 *  @sa support_weighted_data(), train()
 */
void LearnModel::set_train_data (const pDataSet& pd, const pDataWgt& pw) {
    n_samples = pd->size();
    assert(n_samples > 0);
    assert(!pw || n_samples == pw->size());
    if (support_weighted_data()) {
        ptd = pd;
        ptw = (pw != 0)? pw : new DataWgt(n_samples, 1.0 / n_samples);
    } else {
        ptd = (!pw)? pd : pd->random_sample(*pw, n_samples);
        ptw = 0;
    }
    assert(support_weighted_data() == (ptw != 0));
#ifndef NDEBUG
    // assert: ptw is a probability vector
    if (ptw != 0) {
        REAL wsum = 0;
        for (UINT i = 0; i < n_samples; i++) {
            assert((*ptw)[i] >= 0);
            wsum += (*ptw)[i];
        }
        assert(wsum-1 > -EPSILON && wsum-1 < EPSILON);
    }
#endif
    if (!exact_dimensions(*pd)) {
        std::cerr << id() << "::set_train_data: Error: "
            "Wrong input/output dimensions.\n";
        exit(-1);
    }
}

void LearnModel::reset () {
    _n_in = _n_out = 0;
}

REAL LearnModel::margin_of (const Input&, const Output&) const {
    OBJ_FUNC_UNDEFINED("margin_of");
}

REAL LearnModel::min_margin () const {
    REAL min_m = INFINITY;
    for (UINT i = 0; i < n_samples; ++i) {
        // assume all examples count (in computing the minimum)
        assert((*ptw)[i] > INFINITESIMAL);
        REAL m = margin(i);
        if (min_m > m) min_m = m;
    }
    return min_m;
}

bool LearnModel::valid_dimensions (UINT nin, UINT nout) const {
    return (nin == 0 || _n_in == 0 || nin == _n_in) &&
        (nout == 0 || _n_out == 0 || nout == _n_out);
}

void LearnModel::set_dimensions (UINT nin, UINT nout) {
    assert(valid_dimensions(nin, nout));
    if (nin > 0) _n_in = nin;
    if (nout > 0) _n_out = nout;
}

} // namespace lemga
