/**
   orboost.h: implement the ORBoost algorithm (Lin and Li 2006)
   for ordinal regression
   (c) 2006-2007 Hsuan-Tien Lin
**/
#ifndef __LEMGA_AGGRANK_ORBOOST_H__
#define __LEMGA_AGGRANK_ORBOOST_H__

#include "aggrank.h"

namespace lemga {

  class ORBoost : public AggRank {
  public:
    enum {FORM_LR, FORM_FULL};

  protected:
    UINT form;
    bool ordered;
    UINT sub_iter;
    REAL reg_param;

  public:
    explicit ORBoost (UINT _n_rank = 2): AggRank(_n_rank), form(FORM_LR), ordered(true), sub_iter(1), reg_param(0.0) {}
    explicit ORBoost (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual ORBoost* create () const { return new ORBoost(); }
    virtual ORBoost* clone () const { return new ORBoost(*this); }

    void set_form (UINT _form) { form = _form; }
    void set_ordered (bool _ordered) { ordered = _ordered; }
    void set_sub_iter (UINT _sub_iter) { sub_iter = _sub_iter; }
    void set_reg_param (REAL _reg_param) { reg_param = _reg_param; }

  public:
    virtual void train ();

  private:
    void update_with_dec(vREAL& thres_now, vREAL& rholeft, vREAL& rhoright, REAL& sum_rhodiff, REAL& obj);
    REAL compute_w(pLearnModel plm, vREAL& rholeft, vREAL& rhoright);
  };

} // namespace lemga

#ifdef  __ORBOOST_H__
#warning "This header file may conflict with another `orboost.h' file."
#endif
#define __ORBOOST_H__
#endif
