/**
   rankboost.h: efficiently implement the RankBoost 
   algorithm (Freund et al. 2003) for ordinal regression
   (c) 2006-2007 Hsuan-Tien Lin
**/
#ifndef __LEMGA_AGGRANK_RANKBOOST_H__
#define __LEMGA_AGGRANK_RANKBOOST_H__

#include "aggrank.h"

namespace lemga {

  class RankBoost : public AggRank {
  protected:
    REAL reg_param;

  public:
    explicit RankBoost (UINT _n_rank = 2): AggRank(_n_rank), reg_param(0.0) { }
    explicit RankBoost (std::istream& is) { is >> *this; }

    virtual const id_t& id () const;
    virtual RankBoost* create () const { return new RankBoost(); }
    virtual RankBoost* clone () const { return new RankBoost(*this); }

    void set_reg_param(REAL _reg_param) { reg_param = _reg_param; }

  public:
    virtual void train ();

  private:
    void update_with_dec(vREAL& rhopos, vREAL& rhoneg, REAL& sum_rhodiff, REAL& obj);
    REAL compute_w(pLearnModel plm);
  };

} // namespace lemga

#ifdef  __ADARANK_H__
#warning "This header file may conflict with another `adarank.h' file."
#endif
#define __ADARANK_H__
#endif
