/** @file
 *  $Id: aggregating.cpp 2664 2006-03-07 19:50:51Z ling $
 */

#include <assert.h>
#include "aggregating.h"

namespace lemga {

/** Delete learning models stored in @a lm. This is only used in
 *  operator= and load().
 *  @note @a lm_base is not deleted since load() will need it
 *  @todo make it public under the name clear()? Or remove it
 */
void Aggregating::reset () {
    LearnModel::reset();
    lm.clear(); n_in_agg = 0;
    assert(lm_base == 0 || valid_dimensions(*lm_base));
}

/** @note Brand new models are used in the new born object. Thus
 *  any future change to the learning models @a a will not affect
 *  this model.
 */
Aggregating::Aggregating (const Aggregating& a)
    : LearnModel(a), lm_base(a.lm_base),
      n_in_agg(a.n_in_agg), max_n_model(a.max_n_model)
{
    const UINT lms = a.lm.size();
    assert(n_in_agg <= lms);
    for (UINT i = 0; i < lms; ++i)
        lm.push_back(a.lm[i]->clone());
}

/** @copydoc Aggregating(const Aggregating&) */
const Aggregating& Aggregating::operator= (const Aggregating& a) {
    if (&a == this) return *this;

    LearnModel::operator=(a);
    lm_base = a.lm_base;
    n_in_agg = a.n_in_agg;
    max_n_model = a.max_n_model;

    const UINT lms = a.lm.size();
    assert(n_in_agg <= lms);
    lm.clear();
    for (UINT i = 0; i < lms; ++i)
        lm.push_back(a.lm[i]->clone());

    return *this;
}

bool Aggregating::serialize (std::ostream& os, ver_list& vl) const {
    SERIALIZE_PARENT(LearnModel, os, vl, 1);

    if (!(os << lm.size() << ' ' << (lm_base != 0) << '\n'))
        return false;
    if (lm_base != 0)
        if (!(os << *lm_base)) return false;
    for (UINT i = 0; i < lm.size(); ++i)
        if (!(os << *lm[i])) return false;

    return true;
}

bool Aggregating::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
    if (d != id() && d != NIL_ID) return false;
    UNSERIALIZE_PARENT(LearnModel, is, vl, 1, v);

    if (v == 0) /* Take care of _n_in and _n_out */
        if (!(is >> _n_in >> _n_out)) return false;

    UINT t3, t4;
    if (!(is >> t3 >> t4) || t4 > 1) return false;

    if (!t4) lm_base = 0;
    else {
        if (v == 0) { /* ignore a one-line comment */
            char c; is >> c;
            assert(c == '#');
            is.ignore(100, '\n');
        }
        LearnModel* p = (LearnModel*) Object::create(is);
        lm_base = p;
        if (p == 0 || !valid_dimensions(*p)) return false;
    }

    lm.clear();
    for (UINT i = 0; i < t3; ++i) {
        LearnModel* p = (LearnModel*) Object::create(is);
        lm.push_back(p);
        if (p == 0 || !exact_dimensions(*p)) return false;
    }
    n_in_agg = t3;

    return true;
}

/** @brief Set the base learning model.
 *  @todo Allowed to call when !empty()?
 */
void Aggregating::set_base_model (const LearnModel& blm) {
    assert(valid_dimensions(blm));
    lm_base = blm.clone();
}

/** @brief Specify the number of hypotheses used in aggregating.
 *  @return @c false if @a n is larger than size().
 *
 *  Usually all the hypotheses are used in aggregating. However, a
 *  smaller number @a n can also be specified so that only the first
 *  @a n hypotheses are used.
 */
bool Aggregating::set_aggregation_size (UINT n) {
    if (n <= size()) {
        n_in_agg = n;
        return true;
    }
    return false;
}

void Aggregating::set_train_data (const pDataSet& pd, const pDataWgt& pw) {
    LearnModel::set_train_data(pd, pw);
    // Note: leave the compatibility check of the base learner to training.
    for (UINT i = 0; i < lm.size(); ++i)
        if (lm[i] != 0)
            lm[i]->set_train_data(ptd, ptw);
}

}
