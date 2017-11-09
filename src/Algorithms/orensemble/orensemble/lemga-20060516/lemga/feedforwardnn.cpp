/** @file
 *  $Id: feedforwardnn.cpp 2664 2006-03-07 19:50:51Z ling $
 */

#include <assert.h>
#include "feedforwardnn.h"
#include "optimize.h"

REGISTER_CREATOR(lemga::FeedForwardNN);

namespace lemga {

void FeedForwardNN::free_space () {
    for (UINT i = 1; i <= n_layer; ++i) {
        assert(layer[i] != NULL);
        delete layer[i];
    }
    layer.resize(1);
    n_layer = 0;
}

FeedForwardNN::FeedForwardNN ()
    : LearnModel(0,0), n_layer(0),
      online_learn(false), train_method(GRADIENT_DESCENT),
      learn_rate(0.01), min_cst(0), max_run(500)
{
    layer.push_back(NULL);
    /** @todo Online learning is not implemented */
}

FeedForwardNN::FeedForwardNN (const FeedForwardNN& nn)
    : LearnModel(nn), n_layer(nn.n_layer), _y(nn._y), _dy(nn._dy),
      online_learn(nn.online_learn), train_method(nn.train_method),
      learn_rate(nn.learn_rate), min_cst(nn.min_cst), max_run(nn.max_run)
{
    assert(n_layer+1 == nn.layer.size());
    layer.push_back(NULL);
    for (UINT i = 1; i <= n_layer; ++i)
        layer.push_back(nn.layer[i]->clone());
}

FeedForwardNN::~FeedForwardNN () {
    free_space();
}

const FeedForwardNN& FeedForwardNN::operator= (const FeedForwardNN& nn) {
    if (&nn == this) return *this;
    LearnModel::operator=(nn);

    free_space();
    n_layer = nn.n_layer;
    _y = nn._y;
    _dy = nn._dy;
    online_learn = nn.online_learn;
    train_method = nn.train_method;
    learn_rate = nn.learn_rate;
    min_cst = nn.min_cst;
    max_run = nn.max_run;

    assert(n_layer+1 == nn.layer.size());
    for (UINT i = 1; i <= n_layer; ++i)
        layer.push_back(nn.layer[i]->clone());

    return *this;
}

bool FeedForwardNN::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(LearnModel, os, vl, 1);

    if (!(os << n_layer << '\n')) return false;
    if (!(os << online_learn << ' ' << learn_rate << ' '
          << min_cst << ' ' << max_run << '\n')) return false;

    for (UINT i = 1; i <= n_layer; ++i)
        if (!(os << *layer[i])) return false;
    return true;
}

bool
FeedForwardNN::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(LearnModel, is, vl, 1, v);

    UINT tmp_layer;
    if (!(is >> tmp_layer) || tmp_layer == 0) return false;

    std::vector<UINT> lsize;
    if (v == 0) {
        lsize.resize(tmp_layer+1);
        for (UINT i = 0; i <= tmp_layer; ++i)
            if (!(is >> lsize[i]) || lsize[i] == 0) return false;
    }

    int online;
    if (!(is >> online >> learn_rate >> min_cst >> max_run))
        return false;
    if (online > 1 || learn_rate <= 0 || min_cst < 0 || max_run < 1)
        return false;
    online_learn = (online != 0);

    // free the old model !!!
    const UINT n_in_got = _n_in, n_out_got = _n_out;
    free_space();
    _y.clear();
    _dy.clear();

    for (UINT i = 0; i < tmp_layer; ++i) {
        NNLayer* pl = (NNLayer*) Object::create(is);
        if (pl == 0) return false;

        if (v == 0) {
            if (pl->n_input() != lsize[i] || pl->n_output() != lsize[i+1])
                return false;
        }
        else {
            static UINT last_output;
            if (i > 0 && pl->n_input() != last_output) return false;
            last_output = pl->n_output();
        }

        add_top(*pl); delete pl;
    }
    if (v > 0)
        if (n_in_got != _n_in || n_out_got != _n_out) return false;

    return true;
}

void FeedForwardNN::add_top (const NNLayer& nl) {
    assert(n_layer+1 == layer.size());
    assert(n_output() == nl.n_input() || n_layer == 0);
    if (n_layer == 0) {
        assert(_y.empty() && _dy.empty());
        _n_in = nl.n_input();
        _y.push_back(Output(_n_in));
        _dy.push_back(Output(_n_in));
    }

    n_layer++;
    _n_out = nl.n_output();
    layer.push_back(nl.clone());
    _y.push_back(Output(nl.n_output()));
    _dy.push_back(Output(nl.n_output()));
}

void FeedForwardNN::initialize () {
    for (UINT i = 1; i <= n_layer; ++i)
        layer[i]->initialize();
}

void FeedForwardNN::train () {
    assert(n_layer > 0);
    assert(ptd != NULL && ptw != NULL);

    switch (train_method) {
    case GRADIENT_DESCENT:
        iterative_optimize(_gradient_descent<FeedForwardNN,WEIGHT,REAL>
                           (this, learn_rate));
        break;
    case LINE_SEARCH:
        iterative_optimize(_line_search<FeedForwardNN,WEIGHT,REAL,REAL>
                           (this, learn_rate));
        break;
    case CONJUGATE_GRADIENT:
        iterative_optimize
            (_conjugate_gradient<FeedForwardNN,WEIGHT,REAL,REAL>
             (this, learn_rate));
        break;
    case WEIGHT_DECAY:
        iterative_optimize(_gd_weightdecay<FeedForwardNN,WEIGHT,REAL>
                           (this, learn_rate, 0.01));
        break;
    case ADAPTIVE_LEARNING_RATE:
        iterative_optimize(_gd_adaptive<FeedForwardNN,WEIGHT,REAL,REAL>
                           (this, learn_rate, 1.15, 0.5));
        break;
    default:
        assert(0);
    }
}

void FeedForwardNN::log_cost (UINT epoch, REAL cst) {
    if (logf != NULL)
        fprintf(logf, "%lu %g %g\n", epoch, learn_rate, cst);

    if (epoch % 20 == 1)
        printf("epoch %lu, cost = %g\n", epoch, cst);
}

Output FeedForwardNN::operator() (const Input& x) const {
    assert(n_layer > 0);
    assert(x.size() == n_input());

    forward(x);
    return _y[n_layer];
}

FeedForwardNN::WEIGHT FeedForwardNN::weight () const {
    WEIGHT wgt;
    for (UINT i = 1; i <= n_layer; ++i)
        wgt.push_back(layer[i]->weight());
    return wgt;
}

void FeedForwardNN::set_weight (const WEIGHT& wgt) {
    assert(wgt.size() == n_layer);
    for (UINT i = 1; i <= n_layer; ++i)
        layer[i]->set_weight(wgt[i-1]);
}

Output FeedForwardNN::_cost_deriv (const Output& F, const Output& y) const {
    assert(F.size() == n_output() && y.size() == n_output());

    Output d(_n_out);
    for (UINT i = 0; i < _n_out; ++i)
        d[i] = F[i] - y[i];
    return d;
}

REAL FeedForwardNN::cost (UINT idx) const {
    return _cost(get_output(idx), ptd->y(idx));
}

REAL FeedForwardNN::cost () const {
    assert(ptd != NULL && ptw != NULL);
    const UINT n = ptd->size();
    REAL cst = 0;
    for (UINT i = 0; i < n; ++i)
        cst += cost(i) * (*ptw)[i];
    return cst;
}

FeedForwardNN::WEIGHT FeedForwardNN::gradient (UINT idx) const {
    assert(ptd != NULL);
    assert(n_layer > 0);

    clear_gradient();

    forward(_y[0] = ptd->x(idx));
    _dy[n_layer] = _cost_deriv(_y[n_layer], ptd->y(idx));
    for (UINT i = n_layer; i; --i)
        layer[i]->back_propagate(_y[i-1], _dy[i], _dy[i-1]);

    WEIGHT grad;
    for (UINT i = 1; i <= n_layer; ++i)
        grad.push_back(layer[i]->gradient());
    return grad;
}

FeedForwardNN::WEIGHT FeedForwardNN::gradient () const {
    assert(ptd != NULL && ptw != NULL);
    assert(n_layer > 0);

    clear_gradient();

    const UINT n = ptd->size();
    for (UINT idx = 0; idx < n; idx++) {
        forward(_y[0] = ptd->x(idx));

        _dy[n_layer] = _cost_deriv(_y[n_layer], ptd->y(idx));
        assert(_dy[n_layer].size() == _n_out);
        const REAL w = (*ptw)[idx] * n;
        for (UINT j = 0; j < _n_out; ++j)
            _dy[n_layer][j] *= w;

        for (UINT i = n_layer; i; --i)
            layer[i]->back_propagate(_y[i-1], _dy[i], _dy[i-1]);
    }

    WEIGHT grad;
    for (UINT i = 1; i <= n_layer; ++i)
        grad.push_back(layer[i]->gradient());
    return grad;
}

void FeedForwardNN::clear_gradient () const {
    for (UINT i = 1; i <= n_layer; ++i)
        layer[i]->clear_gradient();
}

bool FeedForwardNN::stop_opt (UINT step, REAL cst) {
    log_cost(step, cst);
    return (step >= max_run || cst < min_cst);
}

} // namespace lemga
