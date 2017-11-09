/** @file
 *  $Id: svm.cpp 2782 2006-05-15 19:25:35Z ling $
 */

#include <assert.h>
#include <cmath>
#include "../../libsvm-2.81/svm.h"
#include "svm.h"

REGISTER_CREATOR(lemga::SVM);

// In order to access nSV, we have to copy svm_model here.
// Comments removed. Please see svm.cpp for details.
// Any direct use of svm_model is marked with /* direct access svm_model */
struct svm_model {
    svm_parameter param;
    int nr_class;
    int l;
    svm_node **SV;
    double **sv_coef;
    double *rho;
    double *probA;
    double *probB;
    int *label;
    int *nSV;
    int free_sv;
};

namespace lemga {

typedef struct svm_node* p_svm_node;

#ifndef NDEBUG
static bool param_equal (const struct svm_parameter& a,
                         const struct svm_parameter& b) {
    struct svm_parameter a2 = a, b2 = b;
    a2.C = b2.C = 0;
    return !std::memcmp(&a2, &b2, sizeof(struct svm_parameter));
}
#endif

struct SVM_detail {
    struct svm_parameter param;
    struct svm_problem prob;
    struct svm_model *model;
    struct svm_node *x_space;
    UINT n_class;
    int *labels;
    bool trained; // the wrapper was not loaded from file (ONLY FOR DEBUG)

    SVM_detail ();
    ~SVM_detail () {
        clean_model(); clean_data(); svm_destroy_param(&param); }
    bool fill_svm_problem (const pDataSet&, const pDataWgt&);
    bool train (const pDataSet&, const pDataWgt&);
    void clean_model ();
    void clean_data ();
};

SVM_detail::SVM_detail () : model(0), x_space(0), trained(false) {
    // default LIBSVM parameters, copied from svm-train.c
    param.svm_type = C_SVC;
    param.degree = 3;
    param.gamma = 0;
    param.coef0 = 0;
    param.nu = 0.5;
    param.cache_size = 128;
    param.eps = 1e-3;
    param.p = 0.1;
    param.shrinking = 1;
    param.probability = 0;
    param.nr_weight = 0;
    param.weight_label = NULL;
    param.weight = NULL;
}

void SVM_detail::clean_model () {
    trained = false;
    if (!model) return;
    svm_destroy_model(model);
    delete[] labels;
    model = 0;
}

void SVM_detail::clean_data () {
    if (!x_space) return;
    delete[] prob.x; delete[] prob.y;
    delete[] prob.W;
    delete[] x_space; x_space = 0;
}

p_svm_node fill_svm_node (const Input& x, struct svm_node *pool) {
    for (UINT j = 0; j < x.size(); ++j, ++pool) {
        pool->index = j+1;
        pool->value = x[j];
    }
    pool->index = -1;
    return ++pool;
}

bool SVM_detail::fill_svm_problem (const pDataSet& ptd, const pDataWgt& ptw) {
    assert(ptd->size() == ptw->size());
    const UINT n_samples = ptd->size();
    if (n_samples == 0 || ptd->y(0).size() != 1) return false;
    const UINT n_in = ptd->x(0).size();

    clean_data();
    prob.l = n_samples;
    prob.x = new p_svm_node[n_samples];
    prob.y = new double[n_samples];
    prob.W = new double[n_samples];
    x_space = new struct svm_node[n_samples*(n_in+1)];
    if (!x_space) return false;

    struct svm_node *psn = x_space;
    for (UINT i = 0; i < n_samples; ++i) {
        prob.x[i] = psn;
        prob.y[i] = ptd->y(i)[0];
        psn = fill_svm_node(ptd->x(i), psn);
        prob.W[i] = (*ptw)[i] * n_samples;
    }
    return true;
}

bool SVM_detail::train (const pDataSet& ptd, const pDataWgt& ptw) {
    if (!fill_svm_problem(ptd, ptw)) {
        std::cerr << "Error in filling SVM problem (training data)\n";
        return false;
    }
    const char* error_msg = svm_check_parameter(&prob,&param);
    if (error_msg) {
        std::cerr << "Error: " << error_msg << '\n';
        return false;
    }

    clean_model();
    model = svm_train(&prob, &param);
    trained = true;
    n_class = svm_get_nr_class(model);
    labels = new int[n_class];
    svm_get_labels(model, labels);
    return true;
}

namespace kernel {

void Linear::set_params (SVM_detail* sd) const {
    sd->param.kernel_type = ::LINEAR;
}

void Polynomial::set_params (SVM_detail* sd) const {
    sd->param.kernel_type = ::POLY;
    sd->param.degree = degree;
    sd->param.gamma = gamma;
    sd->param.coef0 = coef0;
}

void RBF::set_params (SVM_detail* sd) const {
    sd->param.kernel_type = ::RBF;
    sd->param.gamma = gamma;
}

void Sigmoid::set_params (SVM_detail* sd) const {
    sd->param.kernel_type = ::SIGMOID;
    sd->param.gamma = gamma;
    sd->param.coef0 = coef0;
}

void Stump::set_params (SVM_detail* sd) const {
    sd->param.kernel_type = ::STUMP;
}

void Perceptron::set_params (SVM_detail* sd) const {
    sd->param.kernel_type = ::PERCEPTRON;
}

} // namespace kernel

bool SVM::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(LearnModel, os, vl, 1);

    // we will not save the detail
    assert(sv.size() == coef.size());
    assert(ker != 0 || sv.size() == 0);
    if (!(os << (ker != 0) << ' ' << regC << ' ' << sv.size() << '\n'))
        return false;
    // the kernel
    if (ker != 0)
        if (!(os << *ker)) return false;
    // support vectors and coefficients
    for (UINT i = 0; i < sv.size(); ++i) {
        assert(sv[i].size() == _n_in);
        for (UINT j = 0; j < _n_in; ++j)
            if (!(os << sv[i][j] << ' ')) return false;
        if (!(os << coef[i] << '\n')) return false;
    }
    // the bias
    return (os << coef0 << '\n');
}

bool SVM::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(LearnModel, is, vl, 1, v);
    assert(v > 0);

    assert(detail != 0);
    reset_model();
    if (ker != 0) delete ker; ker = 0;

    UINT has_kernel, nsv;
    if (!(is >> has_kernel >> regC >> nsv) || has_kernel > 1 || regC < 0)
        return false;
    if (!has_kernel && nsv > 0) return false;

    if (has_kernel) {
        kernel::Kernel* k = (kernel::Kernel*) Object::create(is);
        if (k == 0) return false;
        set_kernel(*k); // don't directly assign the kernel
        delete k;
    }
    sv.resize(nsv); coef.resize(nsv);
    for (UINT i = 0; i < nsv; ++i) {
        Input svi(_n_in);
        for (UINT j = 0; j < _n_in; ++j)
            if (!(is >> svi[j])) return false;
        sv[i].swap(svi);
        if (!(is >> coef[i])) return false;
    }
    return (is >> coef0);
}

SVM::SVM (UINT n_in) : LearnModel(n_in, 1), ker(0), regC(1), coef0(0) {
    detail = new struct SVM_detail;
}

SVM::SVM (const kernel::Kernel& k, UINT n_in)
    : LearnModel(n_in, 1), ker(0), regC(1), coef0(0) {
    detail = new struct SVM_detail;
    set_kernel(k);
}

SVM::SVM (const SVM& s) : LearnModel(s),
    ker(0), regC(s.regC), sv(s.sv), coef(s.coef), coef0(s.coef0) {
    detail = new struct SVM_detail;
    if (s.ker != 0) set_kernel(*s.ker);
    assert(param_equal(detail->param, s.detail->param));
}

SVM::SVM (std::istream& is) : LearnModel(), ker(0) {
    detail = new struct SVM_detail;
    is >> *this;
}

SVM::~SVM () {
    delete detail;
    if (ker != 0) delete ker;
}

const SVM& SVM::operator= (const SVM& s) {
    if (&s == this) return *this;
    assert(ker != s.ker);

    delete detail;
    if (ker != 0) delete ker; ker = 0;

    LearnModel::operator=(s);
    regC = s.regC;
    sv = s.sv; coef = s.coef; coef0 = s.coef0;
    detail = new struct SVM_detail;
    if (s.ker != 0) set_kernel(*s.ker);
    assert(param_equal(detail->param, s.detail->param));
    return *this;
}

REAL SVM::kernel (const Input& x1, const Input& x2) const {
    assert(ker != 0);
#ifndef NDEBUG
    assert(detail);
    struct svm_node sx1[n_input()+1], sx2[n_input()+1];
    fill_svm_node(x1, sx1);
    fill_svm_node(x2, sx2);
    REAL svmk = svm_kernel(sx1, sx2, detail->param);
#endif
    REAL k = (*ker)(x1, x2);
    assert(std::fabs(svmk - k) < EPSILON);
    return k;
}

void SVM::set_kernel (const kernel::Kernel& k) {
    if (&k == ker) return;

    if (ker != 0) {
        delete ker;
        reset_model();  // since kernel is also used for testing
    }
    ker = k.clone();
    ker->set_params(detail);
}

void SVM::initialize () {
    reset_model();
}

void SVM::reset_model () {
    detail->clean_model(); detail->clean_data();
    sv.clear(); coef.clear(); coef0 = 0;
}

void SVM::train () {
    assert(ptd && n_samples == ptd->size());
    assert(ker != 0);
    set_dimensions(*ptd);

    reset_model();
    detail->param.C = regC;
    if (!detail->train(ptd, ptw)) exit(-1);
    assert(detail && detail->model && detail->x_space);
    assert(detail->n_class > 0 && detail->n_class <= 2);

    // copy the trained model to local
    /* direct access svm_model */
    const UINT nsv = detail->model->l;
    sv.resize(nsv); coef.resize(nsv);
    bool flip = false; // whether to flip coefficients and bias
    if (detail->n_class == 1) {
        assert(nsv == 0);
        coef0 = detail->labels[0];
    } else {
        flip = (detail->labels[0] < detail->labels[1]);
        REAL rho = detail->model->rho[0];
        coef0 = flip? rho : -rho;
    }
    for (UINT i = 0; i < nsv; ++i) {
        svm_node *SVi = detail->model->SV[i];
        Input svi(_n_in, 0);
        for (; SVi->index != -1; ++SVi) {
            assert(SVi->index > 0 && (UINT) SVi->index <= _n_in);
            svi[SVi->index-1] = SVi->value;
        }
        sv[i].swap(svi);
        REAL ci = detail->model->sv_coef[0][i];
        coef[i] = flip? -ci : ci;
    }

#ifdef NDEBUG
    // destroy the original model (but keep the param) to save memory
    detail->clean_model(); detail->clean_data();
#endif
}

REAL SVM::margin_of (const Input& x, const Input& y) const {
    assert(std::fabs(std::fabs(y[0]) - 1) < INFINITESIMAL);
    return signed_margin(x) * y[0];
}

REAL SVM::signed_margin (const Input& x) const {
    assert(x.size() == n_input());
    assert(ker != 0);

    const UINT nsv = n_support_vectors();
    REAL sum = bias();
    for (UINT i = 0; i < nsv; ++i)
        sum += support_vector_coef(i) * (*ker)(support_vector(i), x);

#ifndef NDEBUG
    assert(detail);
    if (!detail->trained) return sum;

    assert(detail->model && detail->x_space);
    struct svm_node sx[n_input()+1];
    fill_svm_node(x, sx);
    double m = detail->labels[0];
    if (nsv > 0) {
        svm_predict_values(detail->model, sx, &m);
        if (detail->labels[0] < detail->labels[1]) m = -m;
    }
    assert(std::fabs(sum - m) < EPSILON);
#endif

    return sum;
}

REAL SVM::w_norm () const {
    assert(ker != 0);
    const UINT nsv = n_support_vectors();

    REAL sum = 0;
    for (UINT i = 0; i < nsv; ++i) {
        for (UINT j = i; j < nsv; ++j) {
            REAL ip = (*ker)(support_vector(i), support_vector(j))
                * support_vector_coef(i) * support_vector_coef(j);
            sum += ip + (i==j? 0 : ip);
#ifndef NDEBUG
            assert(detail);
            if (!detail->trained) continue;

            assert(detail->model && detail->x_space);
            /* direct access svm_model */
            REAL ve = svm_kernel(detail->model->SV[i],
                                 detail->model->SV[j], detail->param)
                * detail->model->sv_coef[0][i] * detail->model->sv_coef[0][j];
            assert(std::fabs(ip - ve) < EPSILON);
#endif
        }
    }
    assert(sum >= 0);
    return std::sqrt(sum);
}

Output SVM::operator() (const Input& x) const {
    assert(x.size() == n_input());

    REAL y = (signed_margin(x) > 0? 1 : -1);
#ifndef NDEBUG
    assert(detail);
    if (!detail->trained) return Output(1, y);

    assert(detail->model && detail->x_space);
    struct svm_node sx[n_input()+1];
    fill_svm_node(x, sx);
    REAL l = svm_predict(detail->model, sx);
    assert(std::fabs(y - l) < INFINITESIMAL);
#endif

    return Output(1, y);
}

} // namespace lemga
