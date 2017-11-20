/**
   orboost.cpp: implement the ORBoost algorithm (Lin and Li 2006)
   for ordinal regression
   (c) 2006-2007 Hsuan-Tien Lin
**/
#include <assert.h>
#include <cmath>
#include <limits>

#include "orboost.h"

REGISTER_CREATOR(lemga::ORBoost);

namespace lemga {
  void ORBoost::train() {
    //steepest coordinate decent on (h, w). Then iteratively update (thres, w) for sub_iter times

    set_dimensions(*ptd);

    std::cerr << "Entering ORBoost Training" << std::endl;


    vREAL thres_now(n_rank+1);
    vREAL rhopos(n_samples);
    vREAL rhoneg(n_samples);
    REAL sum_rhodiff, obj;

    recompute_dec();

    thres_now[0] = - std::numeric_limits<REAL>::infinity();
    thres_now[n_rank] = std::numeric_limits<REAL>::infinity();

    compute_thres_exploss(thres_now, ordered, form == FORM_FULL);
    for(UINT k = 1; k <= n_thres; ++k){
      thres[(n_in_agg*n_thres) + k-1] = thres_now[k];
    }

    update_with_dec(thres_now, rhopos, rhoneg, sum_rhodiff, obj);
    // Issue https://github.com/ayrna/orca/issues/13
    //std::cerr << "Iteration " << 0 << "/" << max_n_model << " : Obj = " << obj << std::endl;

    thres.resize((max_n_model+1) * n_thres);
    for (UINT i = 1; i <= max_n_model; ++i) {      
      pLearnModel plm = learn_weak(rhopos, rhoneg, sum_rhodiff);	
      REAL ww(0.0);
      int infflag;

      for(UINT z=0;z<sub_iter;z++){
	REAL w = compute_w(plm, rhopos, rhoneg);
	if (std::isnan(w))
	  w = 0;
	
	infflag = std::isinf(w);

	if (infflag)
	  w = infflag * std::numeric_limits<REAL>::max();

	for(UINT j = 0; j < n_samples; ++j) {
	  REAL o = plm->get_output(j)[0];

	  dec_value[j] += o * w;

	}
	ww += w;

	compute_thres_exploss(thres_now, ordered, form == FORM_FULL);

	update_with_dec(thres_now, rhopos, rhoneg, sum_rhodiff, obj);

	if (infflag)
	  break;
      }

      infflag = std::isinf(ww);

      if (infflag)
	ww = infflag * std::numeric_limits<REAL>::max();
     
      // Issue: https://github.com/ayrna/orca/issues/1i3 
      //std::cerr << "Iteration " << i << "/" << max_n_model << " : Obj = " << obj << std::endl;
      lm.push_back(plm); lm_wgt.push_back(ww);
      n_in_agg++;
      for(UINT k = 1; k <= n_thres; ++k)
	thres[(n_in_agg*n_thres) + k-1] = thres_now[k];

      if (infflag){
	thres.resize((n_in_agg+1) * n_thres);
	return;
      }
      plm->set_train_data(ptd);
    }
  }

  REAL ORBoost::compute_w(pLearnModel plm, vREAL& rhopos, vREAL& rhoneg){
    REAL wp(reg_param), wn(reg_param);
    for(UINT j = 0; j < n_samples; ++j) {
      REAL o = plm->get_output(j)[0];

      if (o >= 0){
	wn += rhopos[j] * o;
	wp += rhoneg[j] * o;
      }
      else{
	wp += rhopos[j] * (-o);
	wn += rhoneg[j] * (-o);
      }
    }
    /**
       for o in [0, 1]
          exp(w * o) <= (e^+w - 1)*  o + 1
       for o in [-1, 0]
          exp(w * o) <= (e^-w - 1)* -o + 1
    **/

    return 0.5 * log(wn / wp);
  }

  void ORBoost::update_with_dec(vREAL& thres_now, vREAL& rhopos, vREAL& rhoneg, REAL& sum_rhodiff, REAL& obj){
    sum_rhodiff = 0.0;
    obj = 0.0;

    for(UINT j = 0; j < n_samples; ++j) {
      UINT goal = (UINT)ptd->y(j)[0];
      if (form == FORM_LR){
	rhopos[j] = exp(- dec_value[j] + thres_now[goal-1]);
	rhoneg[j] = exp(dec_value[j] - thres_now[goal]);
      }
      else{ //FORM_FULL
	rhopos[j] = 0.0;
	rhoneg[j] = 0.0;
	for(UINT k = 1; k <= goal-1; ++k)
	  rhopos[j] += exp(- dec_value[j] + thres_now[k]);
	for(UINT k = goal; k < n_rank; ++k)
	  rhoneg[j] += exp(dec_value[j] - thres_now[k]);
      }
      sum_rhodiff += fabs(rhopos[j] - rhoneg[j]);
      obj += (rhopos[j] + rhoneg[j]);
    }
  }
} //namespace lemga
