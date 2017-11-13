/** @file
 *  $Id: ordinal_ble.cpp 2782 2006-05-15 19:25:35Z ling $
 */

#include <cmath>
#include "ordinal_ble.h"

REGISTER_CREATOR(lemga::Ordinal_BLE);

namespace lemga {

#define OUT2RANK(y)  ((UINT) ((y) - .5))
#define RANK2OUT(r)  ((r) + 1)
#define VALIDRANK(y) ((y) > .9 && std::fabs((y)-1-OUT2RANK(y)) < INFINITESIMAL)
#define nrank  (out_tab.size())
#define n_hyp  (ext_tab.size())

bool Ordinal_BLE::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(LearnModel, os, vl, 1);

    if (!(os << nrank << ' ' << n_hyp << ' ' << n_ext << ' '
             << full_ext << ' ' << (lm != 0) << '\n'))
        return false;

    for (UINT i = 0; i < nrank; ++i) {
        assert(out_tab[i].size() == n_hyp);
        for (UINT j = 0; j < n_hyp; ++j)
            os << out_tab[i][j] << ' ';
        if (n_hyp) os << '\n';
    }
    for (UINT i = 0; i < n_hyp; ++i) {
        assert(ext_tab[i].size() == n_ext);
        for (UINT j = 0; j < n_ext; ++j)
            os << ext_tab[i][j] << ' ';
        if (n_ext) os << '\n';
    }

    if (lm != 0) {
        assert(_n_in == 0 || lm->valid_dimensions(_n_in+n_ext, 1));
        return (os << *lm);
    }
    return os;
}

bool Ordinal_BLE::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(LearnModel, is, vl, 1, v);
    assert(v > 0);

    lm = 0; ptd = 0; ptw = 0; ext_d = 0; ext_w = 0;
    d_nrank = 0; reset_data = true;

    UINT nr, nh, fe, tr;
    if (!(is >> nr >> nh >> n_ext >> fe >> tr) || fe > 1 || tr > 1)
        return false;
    full_ext = fe;

    out_tab.resize(nr); ext_tab.resize(nh);
    for (UINT i = 0; i < nrank; ++i) {
        out_tab[i].resize(n_hyp);
        for (UINT j = 0; j < n_hyp; ++j)
            is >> out_tab[i][j];
    }
    for (UINT i = 0; i < n_hyp; ++i) {
        ext_tab[i].resize(n_ext);
        for (UINT j = 0; j < n_ext; ++j)
            is >> ext_tab[i][j];
    }

    if (tr) {
        lm = (LearnModel*) Object::create(is);
        if (lm == 0 || !(_n_in == 0 || lm->valid_dimensions(_n_in+n_ext, 1)))
            return false;
    }
    return true;
}

Ordinal_BLE::Ordinal_BLE (const Ordinal_BLE& o)
    : LearnModel(o), lm(0), full_ext(o.full_ext),
      out_tab(o.out_tab), ext_tab(o.ext_tab), n_ext(o.n_ext),
      ext_d(o.ext_d), ext_w(o.ext_w), d_nrank(o.d_nrank),
      reset_data(o.reset_data)
{
    if (o.lm != 0) lm = o.lm->clone();
}

const Ordinal_BLE& Ordinal_BLE::operator= (const Ordinal_BLE& o) {
    if (&o == this) return *this;

    LearnModel::operator=(o);
    lm = 0; full_ext = o.full_ext;
    out_tab = o.out_tab; ext_tab = o.ext_tab; n_ext = o.n_ext;
    ext_d = o.ext_d; ext_w = o.ext_w; d_nrank = o.d_nrank;
    reset_data = o.reset_data;
    if (o.lm != 0) lm = o.lm->clone();

    return *this;
}

void Ordinal_BLE::set_model (const LearnModel& l) {
    lm = l.clone();
    reset_data = true;
}

void Ordinal_BLE::set_full_extension (bool f) {
    assert(f); //??? only deal with full-extension for now
    if (full_ext ^ f) { // full_ext will be changed
        ext_d = 0; ext_w = 0;
    }
    full_ext = f;
}

void Ordinal_BLE::set_tables (const ECOC_TABLE& ecc, const EXT_TABLE& ext) {
    out_tab = ecc; ext_tab = ext;
    assert(nrank > 1 && n_hyp > 0);
    n_ext = ext_tab[0].size();
#ifndef NDEBUG
    for (UINT i = 0; i < nrank; ++i)
        assert(out_tab[i].size() == n_hyp);
    for (UINT i = 0; i < n_hyp; ++i)
        assert(ext_tab[i].size() == n_ext);
#endif
    local_d.resize(nrank);
}

void Ordinal_BLE::set_tables (BLE_TYPE bt, UINT nr) {
    ECOC_TABLE ecc(nr);
    EXT_TABLE ext;

    switch (bt) {
    case MULTI_THRESHOLD:
        assert(nr > 1);
        for (UINT i = 0; i < nr; ++i) {
            ecc[i].resize(nr-1, -1);
            for (UINT j = 0; j < i; ++j)
                ecc[i][j] = 1;
        }
        ext.resize(nr-1);
        for (UINT i = 0; i < nr-1; ++i) {
            ext[i].resize(nr-1, 0);
            ext[i][i] = 1;
        }
        break;

    default:
        assert(false);
    }

    set_tables(ecc, ext);
}

REAL Ordinal_BLE::c_error (const Output& out, const Output& y) const {
    assert(n_output() == 1 && VALIDRANK(out[0]) && VALIDRANK(y[0]));
    return OUT2RANK(out[0]) != OUT2RANK(y[0]);
}

REAL Ordinal_BLE::r_error (const Output& out, const Output& y) const {
    assert(n_output() == 1 && VALIDRANK(out[0]) && VALIDRANK(y[0]));
    return std::fabs(out[0] - y[0]);
}

void Ordinal_BLE::set_train_data (const pDataSet& pd, const pDataWgt& pw) {
    pDataSet old_ptd = ptd;
    LearnModel::set_train_data(pd, pw);
    if (old_ptd == ptd) return;

    ext_d = 0; ext_w = 0;
    UINT old_nr = d_nrank;

    // let's be sure that the labels are 1-K (nrank)
    std::vector<bool> has_example;
    UINT nr = 0;
    for (UINT i = 0; i < n_samples; ++i) {
        REAL y = ptd->y(i)[0];
        if (!VALIDRANK(y)) {
            std::cerr << "Ordinal_BLE: Error: "
                      << "Label (" << y << ") is not a valid rank.\n";
            std::exit(-1);
        }
        UINT r = OUT2RANK(y);
        if (r >= has_example.size())
            has_example.resize(r+1, false);
        nr += !has_example[r];
        has_example[r] = true;
    }
    d_nrank = has_example.size();
    if (nr < d_nrank) {
        std::cerr << "Ordinal_BLE: Warning: " << "Missing rank(s) ";
        for (UINT r = 0; r < d_nrank; ++r)
            if (!has_example[r]) {
                std::cerr << RANK2OUT(r);
                if (++nr < d_nrank) std::cerr << ", ";
            }
        std::cerr << ".\n";
    }

    if (old_nr > 0 && old_nr != d_nrank)
        std::cerr << "Ordinal_BLE: Warning: "
                  << "Number of ranks changed from " << old_nr
                  << " to " << d_nrank << ".\n";
}

void Ordinal_BLE::extend_data () {
    //??? full extension only
    assert(n_hyp > 0 && ptd != 0 && n_samples > 0);

    DataSet* rd = new DataSet;
    DataWgt* rw = new DataWgt;
    rw->reserve(n_samples * n_hyp);

    // don't assume _n_in has been set
    UINT nin = ptd->x(0).size();
    Input rx(nin + n_ext);
    for (UINT i = 0; i < n_samples; ++i) {
        const Input& x = ptd->x(i);
        const UINT r = OUT2RANK(ptd->y(i)[0]);
        assert(x.size() == nin && r < nrank);
        const REAL wgt = (*ptw)[i] / n_hyp;

        for (UINT j = 0; j < n_hyp; ++j) {
            REAL ry;
            extend_example(x, r, j, rx, ry);
            rd->append(rx, Output(1, ry));
            rw->push_back(wgt);
        }
    }

    ext_d = rd; ext_w = rw;
    reset_data = true;
}

void Ordinal_BLE::train () {
    assert(ptd != 0 && ptw != 0);
    assert(lm != 0);
    if (nrank == 0) // set the default tables
        set_tables(BLE_DEFAULT, d_nrank);

    assert(nrank > 0 && n_hyp > 0);
    if (d_nrank > nrank) {
        std::cerr << "Ordinal_BLE: Error: "
                  << "More ranks in the data than in the ECC matrix.\n";
        std::exit(-1);
    } else if (d_nrank < nrank)
        std::cerr << "Ordinal_BLE: Warning: "
                  << "Less ranks in the data than in the ECC matrix.\n";

    set_dimensions(*ptd);
    if (ext_d == 0) extend_data();
    assert(ext_d != 0 && ext_w != 0);

    if (reset_data)
        lm->set_train_data(ext_d, ext_w);
    reset_data = false;
    lm->train();
}

void Ordinal_BLE::reset () {
    LearnModel::reset();
    if (lm != 0) lm->reset();
}

#define GET_BEST_RANK(distance_to_rank_r)       \
    REAL dmin = INFINITY; UINT rmin = UINT(-1); \
    for (UINT r = 0; r < nrank; ++r) {          \
        REAL dr = distance_to_rank_r;           \
        assert(dr < INFINITY/10);               \
        if (dr < dmin) { dmin = dr; rmin = r; } \
    }

Output Ordinal_BLE::operator() (const Input& x) const {
    assert(valid_dimensions(x.size(), 1));
    const std::vector<REAL> d = distances(x);
    GET_BEST_RANK(d[r]);
    return Output(1, RANK2OUT(rmin));
}

/** @arg t: hypothesis index */
void Ordinal_BLE::extend_input (const Input& x, UINT t, Input& ext_x) const {
    UINT n_in = x.size();
    assert(t < n_hyp && ext_tab[t].size() == n_ext);
    assert(ext_x.size() == n_in + n_ext);
    //ext_x.resize(n_in + n_ext);
    std::copy(x.begin(), x.end(), ext_x.begin());
    std::copy(ext_tab[t].begin(), ext_tab[t].end(), ext_x.begin()+n_in);
}

void Ordinal_BLE::extend_example (const Input& x, UINT r, UINT t,
                                  Input& ext_x, REAL& ext_y) const
{
    assert(r < nrank && out_tab[r].size() == n_hyp);
    extend_input(x, t, ext_x);
    ext_y = out_tab[r][t];
}

REAL Ordinal_BLE::ECOC_distance (const Output& o,
                                 const ECOC_VECTOR& cw) const {
    assert(o.size() == n_hyp && n_hyp <= cw.size());
    REAL d = 0;
    for (UINT i = 0; i < n_hyp; ++i)
        d += std::exp(- o[i] * cw[i]);
    return d;
}

const std::vector<REAL>& Ordinal_BLE::distances (const Input& x) const {
    UINT nin = x.size();
    assert(lm != 0 && lm->exact_dimensions(nin+n_ext, 1));
    Input rx(nin + n_ext);
    Output out(n_hyp);
    for (UINT j = 0; j < n_hyp; ++j) {
        extend_input(x, j, rx);
        out[j] = (*lm)(rx)[0];
    }
    std::vector<REAL>& d = local_d;
    assert(local_d.size() == nrank);
    for (UINT i = 0; i < nrank; ++i)
        d[i] = ECOC_distance(out, out_tab[i]);
    return d;
}

} // namespace lemga
