/** @file
 *  $Id: perceptron.cpp 2891 2006-11-08 03:17:31Z ling $
 */

// "Fixed bias" means we still use the bias term, but do not change it.
// This is to simulate a perceptron without the bias term. An alternative
// is to modify the dset_distract (for RCD) and those update rules (for
// other algorithms) to not add "1" to input vectors. Although this approach
// is simpler (to implement), it causes extra troubles with saving/loading
// or importing from SVM.

#define STUMP_DOUBLE_DIRECTIONS    0

#include <assert.h>
#include <cmath>
#include <numeric>
#include "random.h"
#include "utility.h"
#include "stump.h"
#include "perceptron.h"

REGISTER_CREATOR(lemga::Perceptron);

typedef std::vector<REAL> RVEC;
typedef std::vector<RVEC> RMAT;

#define DOTPROD(x,y) std::inner_product(x.begin(), x.end(), y.begin(), .0)
// The version without bias
#define DOTPROD_NB(x,y) std::inner_product(x.begin(),x.end()-1,y.begin(),.0)

inline RVEC randvec (UINT n) {
    RVEC x(n);
    for (UINT i = 0; i < n; ++i)
        x[i] = 2*randu() - 1;
    return x;
}

inline RVEC coorvec (UINT n, UINT c) {
    RVEC x(n, 0);
    x[c] = 1;
    return x;
}

inline void normalize (RVEC& v, REAL thr = 0) {
    REAL s = DOTPROD(v, v);
    assert(s > 0);
    if (s <= thr) return;
    s = 1 / std::sqrt(s);
    for (RVEC::iterator p = v.begin(); p != v.end(); ++p)
        *p *= s;
}

RMAT randrot (UINT n, bool bias_row = false, bool conjugate = true) {
    RMAT m(n);
    if (bias_row)
        m.back() = coorvec(n, n-1);

    for (UINT i = 0; i+bias_row < n; ++i) {
        m[i] = randvec(n);
        if (bias_row) m[i][n-1] = 0;
        if (!conjugate) continue;

        // make m[i] independent
        for (UINT k = 0; k < i; ++k) {
            REAL t = DOTPROD(m[i], m[k]);
            for (UINT j = 0; j < n; ++j)
                m[i][j] -= t * m[k][j];
        }
        // normalize m[i]
        normalize(m[i]);
    }
    return m;
}

namespace lemga {

/// Update the weight @a wgt along the direction @a dir.
/// If necessary, the whole @a wgt will be negated.
void update_wgt (RVEC& wgt, const RVEC& dir, const RMAT& X, const RVEC& y) {
    const UINT dim = wgt.size();
    assert(dim == dir.size());
    const UINT n_samples = X.size();
    assert(n_samples == y.size());

    RVEC xn(n_samples), yn(n_samples);
#if STUMP_DOUBLE_DIRECTIONS
    REAL bias = 0;
#endif
    for (UINT i = 0; i < n_samples; ++i) {
        assert(X[i].size() == dim);
        const REAL x_d = DOTPROD(X[i], dir);
        REAL x_new = 0, y_new = 0;
        if (x_d != 0) {
            y_new = (x_d > 0)? y[i] : -y[i];
            REAL x_w = DOTPROD(X[i], wgt);
            x_new = x_w / x_d;
        }
#if STUMP_DOUBLE_DIRECTIONS
        else
            bias += (DOTPROD(X[i], wgt) > 0)? y[i] : -y[i];
#endif
        xn[i] = x_new; yn[i] = y_new;
    }

#if STUMP_DOUBLE_DIRECTIONS
    REAL th1, th2;
    bool ir, pos;
    Stump::train_1d(xn, yn, bias, ir, pos, th1, th2);
    const REAL w_d_new = -(th1 + th2) / 2;
#else
    const REAL w_d_new = - Stump::train_1d(xn, yn);
#endif

    for (UINT j = 0; j < dim; ++j)
        wgt[j] += w_d_new * dir[j];

#if STUMP_DOUBLE_DIRECTIONS
    if (!pos)
        for (UINT j = 0; j < dim; ++j)
            wgt[j] = -wgt[j];
#endif

    // use a big threshold to reduce the # of normalization
    normalize(wgt, 1e10);
}

void dset_extract (const pDataSet& ptd, RMAT& X, RVEC& y) {
    UINT n = ptd->size();
    X.resize(n); y.resize(n);
    for (UINT i = 0; i < n; ++i) {
        X[i] = ptd->x(i);
        X[i].push_back(1);
        y[i] = ptd->y(i)[0];
    }
}

inline void dset_mult_wgt (const pDataWgt& ptw, RVEC& y) {
    UINT n = y.size();
    assert(ptw->size() == n);
    for (UINT i = 0; i < n; ++i)
        y[i] *= (*ptw)[i];
}

Perceptron::Perceptron (UINT n_in)
    : LearnModel(n_in, 1), wgt(n_in+1,0), resample(0),
      train_method(RCD_BIAS), learn_rate(0.002), min_cst(0),
      max_run(1000), with_fld(false), fixed_bias(false)
{
}

Perceptron::Perceptron (const SVM& s)
    : LearnModel(s), wgt(_n_in+1,0), resample(0),
      train_method(RCD_BIAS), learn_rate(0.002), min_cst(0),
      max_run(1000), with_fld(false), fixed_bias(false)
{
    assert(s.kernel().id() == kernel::Linear().id());

    const UINT nsv = s.n_support_vectors();
    for (UINT i = 0; i < nsv; ++i) {
        const Input sv = s.support_vector(i);
        const REAL coef = s.support_vector_coef(i);
        assert(sv.size() == _n_in);
        for (UINT k = 0; k < _n_in; ++k)
            wgt[k] += coef * sv[k];
    }
    wgt.back() = s.bias();
}

bool Perceptron::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(LearnModel, os, vl, 1);
    for (UINT i = 0; i <= _n_in; ++i)
        if (!(os << wgt[i] << ' ')) return false;
    return (os << '\n');
}

bool Perceptron::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(LearnModel, is, vl, 1, v);

    wgt.resize(_n_in+1);
    for (UINT i = 0; i <= _n_in; ++i)
        if (!(is >> wgt[i])) return false;
    return true;
}

void Perceptron::set_weight (const WEIGHT& w) {
    assert(w.size() > 1);
    set_dimensions(w.size()-1, 1);
    wgt = w;
}

void Perceptron::initialize () {
    if (ptd != 0) set_dimensions(*ptd);
    assert(_n_in > 0);
    wgt.resize(_n_in + 1);
    for (UINT i = 0; i < _n_in + (fixed_bias? 0:1); ++i)
        wgt[i] = randu() * 0.1 - 0.05; // small random numbers
}

Perceptron::WEIGHT Perceptron::fld () const {
    assert(ptd != 0 && ptw != 0);

    // get the mean
    Input m1(_n_in, 0), m2(_n_in, 0);
    REAL w1 = 0, w2 = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        const Input& x = ptd->x(i);
        REAL y = ptd->y(i)[0];
        REAL w = (*ptw)[i];

        if (y > 0) {
            w1 += w;
            for (UINT k = 0; k < _n_in; ++k)
                m1[k] += w * x[k];
        } else {
            w2 += w;
            for (UINT k = 0; k < _n_in; ++k)
                m2[k] += w * x[k];
        }
    }
    assert(w1 > 0 && w2 > 0 && std::fabs(w1+w2-1) < EPSILON);
    for (UINT k = 0; k < _n_in; ++k) {
        m1[k] /= w1; m2[k] /= w2;
    }

    // get the covariance
    RMAT A(_n_in, RVEC(_n_in, 0));
    RVEC diff(_n_in);
    for (UINT i = 0; i < n_samples; ++i) {
        const Input& x = ptd->x(i);
        REAL y = ptd->y(i)[0];
        REAL w = (*ptw)[i];

        if (y > 0)
            for (UINT k = 0; k < _n_in; ++k)
                diff[k] = x[k] - m1[k];
        else
            for (UINT k = 0; k < _n_in; ++k)
                diff[k] = x[k] - m2[k];
        // we only need the upper triangular part
        for (UINT j = 0; j < _n_in; ++j)
            for (UINT k = j; k < _n_in; ++k)
                A[j][k] += w * diff[j] * diff[k];
    }

    for (UINT k = 0; k < _n_in; ++k)
        diff[k] = m1[k] - m2[k];

    RVEC w;
    bool not_reg = true;
    while (!ldivide(A, diff, w)) {
        assert(not_reg); not_reg = false; // should only happen once
        REAL tr = 0;
        for (UINT j = 0; j < _n_in; ++j)
            tr += A[j][j];
        const REAL gamma = 1e-10; // see [Friedman 1989]
        const REAL adj = gamma/(1-gamma) * tr/_n_in;
        for (UINT j = 0; j < _n_in; ++j)
            A[j][j] += adj;
#if VERBOSE_OUTPUT
        std::cerr << "LDA: The class covariance matrix estimate is "
            "regularized by\n\tan eigenvalue shinkage parameter "
                  << gamma << '\n';
#endif
    }

    w.push_back(- (DOTPROD(m1,w) * w2 + DOTPROD(m2,w) * w1));
    return w;
}

inline UINT randcdf (REAL r, const RVEC& cdf) {
    UINT b = 0, e = cdf.size()-1;
    while (b+1 < e) {
        UINT m = (b + e) / 2;
        if (r < cdf[m]) e = m;
        else b = m;
    }
    return b;
}

void Perceptron::train () {
    assert(ptd != 0 && ptw != 0 && ptd->size() == n_samples);
    set_dimensions(*ptd);
    const UINT dim = _n_in+1;
    // but what is updated might be of a smaller size
    const UINT udim = _n_in + (fixed_bias? 0:1);

    RVEC cdf;
    if (resample) {
        cdf.resize(n_samples+1);
        cdf[0] = 0;
        for (UINT i = 0; i < n_samples; ++i)
            cdf[i+1] = cdf[i] + (*ptw)[i];
        assert(cdf[n_samples]-1 > -EPSILON && cdf[n_samples]-1 < EPSILON);
    }

    wgt.resize(dim);
    const REAL bias_save = wgt.back();
    if (with_fld) wgt = fld();
    if (fixed_bias)
        wgt.back() = bias_save;

    RMAT X; RVEC Y;
    dset_extract(ptd, X, Y);

#define RAND_IDX() (resample? randcdf(randu(),cdf) : UINT(randu()*n_samples))
#define SAMPWGT(i) (resample? 1 : (*ptw)[i]*n_samples)
#define GET_XYO(i)         \
    const Input& x = X[i]; \
    const REAL y = Y[i];   \
    const REAL o = DOTPROD(wgt,x)

    log_error(0);
    switch (train_method) {
    case PERCEPTRON:
    case ADALINE:
        for (UINT i = 0; i < max_run; ++i) {
            for (UINT j = 0; j < n_samples; ++j) {
                const UINT idx = RAND_IDX();
                GET_XYO(idx);
                if (y * o > 0) continue;
                REAL deriv = (train_method == PERCEPTRON? y : (y - o));
                REAL adj = learn_rate * SAMPWGT(idx) * deriv;

                for (UINT k = 0; k < udim; ++k)
                    wgt[k] += adj * x[k];
            }
            log_error(i+1);
        }
        break;

    case POCKET_RATCHET:
    case POCKET: {
        bool ratchet = (train_method == POCKET_RATCHET);
        RVEC best_w(wgt);
        REAL run = 0, err = train_c_error();
        bool err_valid = true;
        REAL best_run = run, best_err = err;
        for (UINT i = 0; i < max_run; ++i) {
            for (UINT j = 0; j < n_samples; ++j) {
                const UINT idx = RAND_IDX();
                GET_XYO(idx);

                if (y * o > 0) {
                    run += SAMPWGT(idx);
                    if (run > best_run) {
                        if (!err_valid) err = train_c_error();
                        err_valid = true;
                        if (!ratchet || err < best_err) {
                            best_run = run;
                            best_err = err;
                            best_w = wgt;
                        }
                        if (err <= 0) break;
                    }
                } else {
                    run = 0;
                    err_valid = false;

                    const REAL adj = SAMPWGT(idx) * y;
                    for (UINT k = 0; k < udim; ++k)
                        wgt[k] += adj * x[k];
                }
            }
            wgt.swap(best_w); log_error(i+1, best_err); wgt.swap(best_w);
        }
        wgt.swap(best_w);
    }
        break;

    case AVE_PERCEPTRON_RAND:
    case AVE_PERCEPTRON: {
        assert(train_method != AVE_PERCEPTRON || !resample);
        RVEC ave_wgt(dim, 0);
        REAL run = 0;
        for (UINT i = 0; i < max_run; ++i) {
            for (UINT j = 0; j < n_samples; ++j) {
                const UINT idx = (train_method == AVE_PERCEPTRON)?
                    j : RAND_IDX();
                GET_XYO(idx);
                if (y * o > 0)
                    run += SAMPWGT(idx);
                else {
                    for (UINT k = 0; k < dim; ++k)
                        ave_wgt[k] += run * wgt[k];

                    const REAL adj = SAMPWGT(idx) * y;
                    for (UINT k = 0; k < udim; ++k)
                        wgt[k] += adj * x[k];
                    run = SAMPWGT(idx);
                }
            }
            RVEC tmp_wgt(ave_wgt);
            for (UINT k = 0; k < dim; ++k)
                tmp_wgt[k] += run * wgt[k];
            wgt.swap(tmp_wgt); log_error(i+1); wgt.swap(tmp_wgt);
        }
        for (UINT k = 0; k < dim; ++k)
            wgt[k] = ave_wgt[k] + run * wgt[k];
    }
        break;

    case ROMMA_AGG_RAND:
    case ROMMA_AGG:
    case ROMMA_RAND:
    case ROMMA: {
        bool fixed = (train_method == ROMMA || train_method == ROMMA_AGG);
        assert(!fixed || !resample);
        REAL bnd = (train_method == ROMMA || train_method == ROMMA_RAND)?
            0 : (1-EPSILON);
        for (UINT i = 0; i < max_run; ++i) {
            for (UINT j = 0; j < n_samples; ++j) {
                const UINT idx = fixed? j : RAND_IDX();
                GET_XYO(idx); const REAL& w_x = o;
                if (y * w_x > bnd) continue;

                REAL w_w = DOTPROD(wgt, wgt);
                REAL x_x = 1 + DOTPROD(x, x);
                REAL x2w2 = x_x * w_w;
                REAL deno = x2w2 - w_x*w_x;
                REAL c = (x2w2 - y*w_x) / deno;
                REAL d = w_w * (y - w_x) / deno;

                wgt[0] = c*wgt[0] + d;
                for (UINT k = 0; k < _n_in; ++k)
                    wgt[k+1] = c*wgt[k+1] + d*x[k];
            }
            log_error(i+1);
        }
    }
        break;

    case SGD_HINGE:
    case SGD_MLSE: {
        const REAL C = 0; // C is lambda

        for (UINT i = 0; i < max_run; ++i) {
            for (UINT j = 0; j < n_samples; ++j) {
                const UINT idx = RAND_IDX();
                GET_XYO(idx);

                if (y*o < 1) {
                    REAL shrink = 1 - C * learn_rate;
                    REAL deriv = (train_method == SGD_HINGE? y : (y - o));
                    REAL adj = learn_rate * SAMPWGT(idx) * deriv;
                    for (UINT k = 0; k < udim; ++k)
                        wgt[k] = shrink * wgt[k] + adj * x[k];
                }
            }
            log_error(i+1);
        }
    }
        break;

#undef RAND_IDX
#undef SAMPWGT
#define CYCLE(r)  (((r)+dim-1) % udim)
#define UPDATE_WGT(d) update_wgt(wgt, d, X, Y)
#define INIT_RCD() {                      \
    dset_mult_wgt(ptw, Y);                \
}

    case COORDINATE_DESCENT: {
        INIT_RCD();
        for (UINT r = 0; r < max_run; ++r) {
            UPDATE_WGT(coorvec(dim, CYCLE(r)));
            log_error(r+1);
        }
    }
        break;

    case FIXED_RCD:
    case FIXED_RCD_CONJ:
    case FIXED_RCD_BIAS:
    case FIXED_RCD_CONJ_BIAS: {
        bool bias_row = (train_method == FIXED_RCD_BIAS ||
                         train_method == FIXED_RCD_CONJ_BIAS);
        bool conjugate = (train_method == FIXED_RCD_CONJ ||
                          train_method == FIXED_RCD_CONJ_BIAS);
        RMAT A = randrot(dim, bias_row || fixed_bias, conjugate);

        INIT_RCD();
        for (UINT r = 0; r < max_run; ++r) {
            UPDATE_WGT(A[CYCLE(r)]);
            log_error(r+1);
        }
    }
        break;

    case RCD:
    case RCD_CONJ:
    case RCD_BIAS:
    case RCD_CONJ_BIAS: {
        bool bias_row = (train_method == RCD_BIAS ||
                         train_method == RCD_CONJ_BIAS);
        bool conjugate = (train_method == RCD_CONJ ||
                          train_method == RCD_CONJ_BIAS);
        RMAT A;

        INIT_RCD();
        for (UINT r = 0; r < max_run; ++r) {
            const UINT c = CYCLE(r);
            if (c == CYCLE(0))
                A = randrot(dim, bias_row || fixed_bias, conjugate);
            UPDATE_WGT(A[c]);
            log_error(r+1);
        }
    }
        break;

    case RCD_GRAD_BATCH_RAND:
    case RCD_GRAD_BATCH:
    case RCD_GRAD_RAND:
    case RCD_GRAD: {
        bool online = (train_method == RCD_GRAD ||
                       train_method == RCD_GRAD_RAND);
        bool wrand = (train_method == RCD_GRAD_RAND ||
                      train_method == RCD_GRAD_BATCH_RAND);
        // gradient of sum weight*y*<w,x> over all unsatisfied examples
        INIT_RCD();
        for (UINT r = 0; r < max_run; ++r) {
            RVEC dir(dim, 0);
            if (r % 5 == 0 && wrand) {
                dir = randvec(dim);
            } else if (online) {
                UINT idx, cnt = 0;
                REAL o;
                do {
                    ++cnt;
                    idx = UINT(randu() * n_samples);
                    o = DOTPROD(wgt, X[idx]);
                } while (Y[idx] * o > 0 && cnt < 2*n_samples);
                // if we've tried too many times, just use any X
                dir = X[idx];
            } else {
                bool no_err = true;
                for (UINT j = 0; j < n_samples; ++j) {
                    GET_XYO(j);
                    if (y * o > 0) continue;
                    no_err = false;
                    for (UINT k = 0; k < udim; ++k)
                        dir[k] += y * x[k];
                }
                if (no_err) break;
            }

            if (fixed_bias)
                dir.back() = 0;
            UPDATE_WGT(dir);
            log_error(r+1);
        }
    }
        break;

    case RCD_GRAD_MIXED_BATCH_INITRAND:
    case RCD_GRAD_MIXED_BATCH:
    case RCD_GRAD_MIXED_INITRAND:
    case RCD_GRAD_MIXED: {
        bool online = (train_method == RCD_GRAD_MIXED ||
                       train_method == RCD_GRAD_MIXED_INITRAND);
        bool init_rand = (train_method == RCD_GRAD_MIXED_INITRAND ||
                          train_method == RCD_GRAD_MIXED_BATCH_INITRAND);

        INIT_RCD();
        for (UINT r = 0; r < max_run; ++r) {
            RVEC dir(dim, 0);
            if (init_rand)
                dir = randvec(dim);
            UINT cnt = 0;

            for (UINT j = 0; j < n_samples; ++j) {
                UINT idx = (online? UINT(randu() * n_samples) : j);
                GET_XYO(idx);
                if (y * o > 0) continue;
                ++cnt;
                REAL adj = y*n_samples * randu();
                for (UINT k = 0; k < udim; ++k)
                    dir[k] += adj * x[k];
            }
            //if (cnt == 0 && !online) break;

            if (cnt == 0 && !init_rand)
                dir = randvec(dim);
            if (fixed_bias)
                dir.back() = 0;
            UPDATE_WGT(dir);
            log_error(r+1);
        }
    }
        break;

    case RCD_MIXED: {
        INIT_RCD();
        RMAT A;
        for (UINT r = 0; r < max_run; ++r) {
            UINT c = r % (2*udim);
            RVEC dir;
            if (c < udim)
                dir = coorvec(dim, CYCLE(c));
            else {
                if (c == udim) A = randrot(dim, fixed_bias, false);
                dir = A[c-udim]; // CYCLE doesn't change anything
            }
            UPDATE_WGT(dir);
            log_error(r+1);
        }
    }
        break;

    default:
        assert(false);
    }

    assert(!fixed_bias || train_method == AVE_PERCEPTRON_RAND ||
           train_method == AVE_PERCEPTRON || wgt.back() == bias_save);
}

#define INPUT_SUM(w,x)  \
    std::inner_product(x.begin(), x.end(), w.begin(), w.back())

Output Perceptron::operator() (const Input& x) const {
    assert(x.size() == n_input());
    REAL sum = INPUT_SUM(wgt, x);
    return Output(1, (sum>=0)? 1 : -1);
}

REAL Perceptron::margin_of (const Input& x, const Output& y) const {
    assert(std::fabs(std::fabs(y[0]) - 1) < INFINITESIMAL);
    return INPUT_SUM(wgt, x) * y[0];
}

REAL Perceptron::w_norm () const {
    REAL s = DOTPROD_NB(wgt, wgt);
    return std::sqrt(s);
}

void Perceptron::log_error (UINT, REAL err) const {
    if (logf != NULL) {
        if (err < 0) err = train_c_error();
        fprintf(logf, "%g ", err);
    }
}

} // namespace lemga
