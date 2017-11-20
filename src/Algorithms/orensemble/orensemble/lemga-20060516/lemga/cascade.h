// -*- C++ -*-
#ifndef __LEMGA_AGGREGATING_CASCADE_H__
#define __LEMGA_AGGREGATING_CASCADE_H__

/** @file
 *  @brief Declare @link lemga::Cascade Cascade@endlink class
 *
 *  $Id: cascade.h 2664 2006-03-07 19:50:51Z ling $
 */

#include <utility>
#include "aggregating.h"

namespace lemga {

/** @brief Aggregate hypotheses in a cascade (sequential) way.
 *
 *  For classification problems, aggregating of hypotheses can be
 *  done in a cascade way. That is, a list of classifiers are trained
 *  from the training data; an unknown input is first classified
 *  using the first hypothesis in the list. If the first hypothesis
 *  cannot decide the classification with high reliability, the input
 *  is fed into the next one and so on. (See Cascade::operator() for
 *  details.) We can have as many hypotheses as the problem demands.
 *
 *  The ``reliability'' of a decision is usually determined by a
 *  concept named @em margin. There exist different definitions in
 *  literature, such as @f$yf(x)@f$ in %AdaBoost,
 *  @f$y(w\cdot x-t)/|w|@f$ in SVM. Despite of the differences in
 *  definitions, higher margins usually implicit more robustness to
 *  input disturbance and thus better generalization.
 *
 *  When margin is used in cascade to decide whether to go on to the
 *  next hypothesis, the real output @a y is unknown. A natual
 *  alternative is to use the ``sign'' part of the margin, i.e.,
 *  @f$f(x)@f$ in %AdaBoost and @f$(w\cdot x-t)/|w|@f$ in SVM, and
 *  take the magnitude as the margin. Similar concepts, such as
 *  belief in belief propagation and log-likelihood in coding, can
 *  also be used.
 *
 *  We use the name ``belief'' in this class for binary-class problems.
 *  Very positive and very negative beliefs indicate strong confidence
 *  in the predicting and thus high reliability.
 *
 *  @todo General definition of margin; More explanation of Cascade
 */
class Cascade : public Aggregating {
protected:
    std::vector<REAL> upper_margin; ///<
    std::vector<REAL> lower_margin; ///<

public:
    virtual Cascade* create () const = 0;
    virtual Cascade* clone () const = 0;

    /** @todo Unclear about the support of weghted data */
    virtual bool support_weighted_data () const { return true; }
    virtual void train () = 0;
    virtual Output operator() (const Input&) const;

    /// Belief at a specific pair of input and output
    virtual REAL belief (const LearnModel&,
                         const Input&, const Output&) const;

protected:
    virtual bool serialize (std::ostream&, ver_list&) const;
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID);
};

} // namespace lemga

#ifdef  __CASCADE_H__
#warning "This header file may conflict with another `cascade.h' file."
#endif
#define __CASCADE_H__
#endif
