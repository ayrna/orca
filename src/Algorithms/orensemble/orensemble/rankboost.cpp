/**
   rankboost.cpp: efficiently implement the RankBoost 
   algorithm (Freund et al. 2003) for ordinal regression
   (c) 2006-2007 Hsuan-Tien Lin
**/
#include <assert.h>
#include <cmath>
#include <limits>

#include "rankboost.h"

REGISTER_CREATOR(lemga::RankBoost);

namespace lemga {
  void RankBoost::train() {
    //rankboost, efficient implementation, early stop if inf

    set_dimensions(*ptd);

    std::cerr << "Entering RankBoost Training" << std::endl;
    
    recompute_dec();

    vREAL rhopos(n_samples);
    vREAL rhoneg(n_samples);    
    REAL sum_rhodiff, obj;

    update_with_dec(rhopos, rhoneg, sum_rhodiff, obj);

    // https://github.com/ayrna/orca/issues/13
    //std::cerr << "Iteration " << 0 << "/" << max_n_model << " : Obj = " << obj << std::endl;

    thres.resize((max_n_model+1) * n_thres);

    for (UINT i = 1; i <= max_n_model; ++i) {      
      pLearnModel plm = learn_weak(rhopos, rhoneg, sum_rhodiff);
      REAL w = compute_w(plm);
      if (std::isnan(w))
	w = 0; //this happens when plm is a constant classifier
	
      int infflag = std::isinf(w);

      if (infflag)
	w = infflag * std::numeric_limits<REAL>::max();

      for(UINT j = 0; j < n_samples; ++j) {
	REAL o = plm->get_output(j)[0];
	dec_value[j] += o * w;
      }
      update_with_dec(rhopos, rhoneg, sum_rhodiff, obj);

      // https://github.com/ayrna/orca/issues/13
      // std::cerr << "Iteration " << i << "/" << max_n_model << " : Obj = " << obj << std::endl;
      lm.push_back(plm); lm_wgt.push_back(w);
      n_in_agg++;
      compute_thres(thres.begin() + (n_in_agg*n_thres));

      if (infflag){
	thres.resize((n_in_agg+1) * n_thres);
	return;
      }
      plm->set_train_data(ptd);
    }
  }

  void RankBoost::update_with_dec(vREAL& rhopos, vREAL& rhoneg, REAL& sum_rhodiff, REAL& obj){
    //rhopos[i]: weights that desire h_i positive = exp(-g_i) sum_(y_j < y_i) exp(g_j)
    //rhoneg[i]: weights that desire h_i negative = exp(g_i) sum_(y_j > y_i) exp(-g_j)
    //the later terms would be computed in lower[y_i] and upper[y_i] first
    //obj = sum_{y_j < y_i} exp(g_j - g_i) = sum rhopos[i] = sum rhoneg[j]

    vREAL lower(n_rank), upper(n_rank);
    {
      //final goal
      //lower[k-1] = \sum_{y_j < k} exp(g_j)
      //upper[k-1] = \sum_{y_j > k} exp(-g_j)
    
      //first compute 
      //lower[k-1] = \sum_{y_j = k} exp(g_j)
      //upper[k-1] = \sum_{y_j = k} exp(-g_j)
      for(UINT j = 0; j < n_samples; ++j){
	UINT goal = (UINT)(ptd->y(j)[0] - 1);
	lower[goal] += exp(dec_value[j]);
	upper[goal] += exp(-dec_value[j]);
      }
      REAL sum;

      //a summation for lower
      sum = 0.0;
      for(UINT k = 0; k < n_rank; ++k){
	REAL tmp = lower[k];
	lower[k] = sum;
	sum += tmp;
      }
      
      //a summation for upper
      sum = 0.0;
      for(UINT k = n_rank; k > 0; --k){
	REAL tmp = upper[k-1];
	upper[k-1] = sum;
	sum += tmp;
      }
    }

    obj = 0.0;
    sum_rhodiff = 0.0;
    for(UINT j = 0; j < n_samples; ++j){
      UINT goal = (UINT)(ptd->y(j)[0] - 1);
      rhopos[j] = exp(-dec_value[j]) * lower[goal];
      rhoneg[j] = exp(dec_value[j]) * upper[goal];
      sum_rhodiff += fabs(rhopos[j] - rhoneg[j]);
      obj += 0.5 * (rhopos[j] + rhoneg[j]);
    }      
  }

  REAL RankBoost::compute_w(pLearnModel plm){
    /** Method 3 of RankBoost:
	for r in [-2, 2]
	r = sum_{y_i < y_j} exp(-(dec_value[j]-dec_value[i])) * (oj - oi) * 0.5
	sumd = sum_{y_i < y_j} exp(-(dec_value[j]-dec_value[i]))
    **/
    
    REAL r(0.0);
    vREAL exppos(n_rank), expneg(n_rank);
    vREAL sumpos(n_rank), sumneg(n_rank);
    REAL sumd(0.0);
    
    for(UINT j = 0; j < n_samples; ++j) {
      REAL o = plm->get_output(j)[0];
      UINT goal = (UINT)(ptd->y(j)[0] - 1);
      
      exppos[goal] += o * exp(dec_value[j]);
      expneg[goal] += o * exp(-dec_value[j]);
      
      sumpos[goal] += exp(dec_value[j]);
      sumneg[goal] += exp(-dec_value[j]);
    }    
    
    for(UINT yi = 0; yi < n_rank; yi++){
      for(UINT yj = yi+1; yj < n_rank; yj++){
	//now y_i < y_j
	r += expneg[yj] * sumpos[yi] - exppos[yi] * sumneg[yj];
	sumd += sumpos[yi] * sumneg[yj];
      }
    }
    r *= 0.5; //shrink from [-2, 2] to [-1, 1];
    return 0.25 * log((sumd + r) / (sumd - r));    
  }
} //namespace lemga
