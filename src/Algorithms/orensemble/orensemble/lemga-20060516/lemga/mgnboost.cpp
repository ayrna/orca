/** @file
 *  $Id: mgnboost.cpp 2664 2006-03-07 19:50:51Z ling $
 */

#include <assert.h>
#include "optimize.h"
#include "mgnboost.h"

REGISTER_CREATOR(lemga::MgnBoost);

namespace lemga {

void MgnBoost::train () {
    assert(!convex && grad_desc_view);
    Boosting::train();
}

void MgnBoost::train_gd () {
    _mgn_gd mgd(this);
    iterative_optimize(_line_search<_mgn_gd,BoostWgt,REAL,REAL>
                       (&mgd, convex? 1.0 : 0.5));
    update_cost_l(); // optional, just to be consistent with the def.
}

} // namespace lemga
