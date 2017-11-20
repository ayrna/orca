/**
   aggrank.cpp: an abstract class for general thresholded ensembles
   (c) 2006-2007 Hsuan-Tien Lin
**/
#include <assert.h>
#include <cmath>
#include <map>
#include <limits>

#include "aggrank.h"

namespace lemga {
    /** basics **/
    bool AggRank::serialize (std::ostream& os, ver_list& vl) const {
	SERIALIZE_PARENT(Aggregating, os, vl, 1);    
	assert(lm_wgt.size() == lm.size());
	for (UINT i = 0; i < lm_wgt.size(); ++i)
	    os << lm_wgt[i] << ' ';
	if (!lm_wgt.empty()) os << '\n';
	os << n_rank << '\n';
	UINT t=0;
	for (UINT i = 0; i <= lm.size(); i++){
	    for (UINT k = 1; k < n_rank; k++)
		os << thres[t++] << ' ';
	    os << '\n';
	}

	if (t > 0) os << '\n';
	return true;
    }

    bool AggRank::unserialize (std::istream& is, ver_list& vl, const id_t& d) {
	if (d != id() && d != NIL_ID) return false;
	UNSERIALIZE_PARENT(Aggregating, is, vl, 1, v);
    
	const UINT n = lm.size();
	lm_wgt.resize(n);
	for (UINT i = 0; i < n; ++i)
	    if (!(is >> lm_wgt[i])) return false;

	if (!set_aggregation_size(n)) return false;

	UINT _n_rank;
	if (!(is >> _n_rank))
	    return false;
	set_n_rank(_n_rank);
	thres.resize((n+1) * (n_thres));
	UINT t=0;
	for (UINT i = 0; i <= n; i++)
	    for (UINT k = 1; k < n_rank; k++)
		if (!(is >> thres[t++])) return false;

	return true;
    }

    Output AggRank::operator() (const Input& x, UINT iter) const {
	//y[1] is the decision value, and y[0] is the prediction
	assert(_n_out == 1);
	Output y(2, 0);

	if (iter > n_in_agg) iter = n_in_agg;
    
	for (UINT i = 0; i < iter; ++i) {
	    Output out = (*lm[i])(x);

	    y[1] += (out[0] * lm_wgt[i]);
	}

	UINT rank = 1;
	UINT idx = iter * n_thres;
	for(UINT k = 1; k < n_rank; k++)
	    if (y[1] >= thres[idx++]) rank++;
	y[0] = rank;
    
	return y;
    }
    
    /** initialize routine **/
    void AggRank::reset() {
	//clear the trained results, but retain other settings
	Aggregating::reset();
	assert(n_rank >= 2);
	lm_wgt.clear();
	thres.resize(n_thres);
	for (UINT k = 0; k < n_thres; ++k){
	    switch(init_mode){
	    case INIT_NAIVE:
		thres[k] = 1.0 + k - 0.5 * n_rank;
		break;
	    case INIT_ZERO:
		thres[k] = 0.0;
		break;
	    case INIT_RAND:
		if (k > 0)
		    thres[k] = thres[k-1] + randuc();
		else
		    thres[k] = randuc();
		break;
	    }
	}

	dec_value.resize(n_samples);
	for (UINT j = 0; j < n_samples; ++j)
	    dec_value[j] = 0;
    }

    pLearnModel AggRank::learn_weak(const vREAL& rhopos, const vREAL& rhoneg, 
				    const REAL sum_rhodiff) {
	// rhopos: the sample weights supporting the prediction to be positive
	// rhoneg: the sample weights supporting the prediction to be negative
	DataSet* btd = new DataSet();
	DataWgt* btw = new DataWgt();    

	for(UINT j = 0; j < n_samples; ++j) {
	    if (rhopos[j] >= rhoneg[j])
		btd->append(ptd->x(j), 
			    Output(1, +1));
	    else
		btd->append(ptd->x(j), 
			    Output(1, -1));
	    btw->push_back(fabs(rhopos[j] - rhoneg[j]) / sum_rhodiff);
	}

	LearnModel *plm = lm_base->clone();
    
	plm->set_train_data(btd, btw);
	plm->train();
	return plm;
    }

    void AggRank::recompute_dec() {    
	dec_value.resize(n_samples);

	for (UINT j = 0; j < n_samples; ++j){
	    dec_value[j] = 0.0;
	    for (UINT i = 0; i < n_in_agg; ++i) {
		Output out = (*lm[i])(ptd->x(j));	
		dec_value[j] += (out[0] >= 0)? lm_wgt[i] : -lm_wgt[i];
	    }
	}
    }

    void AggRank::compute_thres(vREAL::iterator it) {
	vREAL thres_now(n_rank+1);
	thres_now[0] = -std::numeric_limits<REAL>::max();
	thres_now[n_rank] = std::numeric_limits<REAL>::max();

	switch(thres_mode){
	case THRES_EXPLOSS:
	    compute_thres_exploss(thres_now, false, false);
	    break;
	case THRES_EXPLOSS_ORDERED:
	    compute_thres_exploss(thres_now, true, false);
	    break;
	case THRES_ABSLOSS:
	    compute_thres_dploss(thres_now, true);
	    break;
	case THRES_CLALOSS:
	    compute_thres_dploss(thres_now, false);
	    break;
	default:
	    assert(thres_mode < THRES_CLALOSS);
	}

	for(UINT k = 1; k < n_rank; ++k)
	    (*it++)=thres_now[k];
    }

    void AggRank::compute_thres_exploss(vREAL& th, bool ordered, bool full){
	assert(th[n_rank] >= std::numeric_limits<REAL>::max());

	vREAL wp(n_rank+1), wn(n_rank+1);

	for(UINT j = 0; j < n_samples; ++j) {
	    int o = (int)ptd->y(j)[0];
	    if (full){
		for(int k=1; k <= o-1; ++k)
		    wp[k] += exp(-dec_value[j]);
		for(int k=o; k <= (int)n_rank-1; ++k)
		    wn[k] += exp(dec_value[j]);
	    }
	    else{
		wp[o-1] += exp(-dec_value[j]);
		wn[o] += exp(dec_value[j]);
	    }
	}
    
	for(UINT k = n_rank-1; k > 0; --k){
	    th[k] = 0.5 * log(wn[k] / wp[k]);
	    //clip th in the good region
	    if (std::isnan(th[k]))
		th[k] = th[k+1];	    
	    if (std::isinf(th[k]))
		th[k] = std::isinf(th[k]) * std::numeric_limits<REAL>::max();

	    if (ordered && th[k] > th[k+1]){
		UINT kk;
		REAL wwn(wn[k]), wwp(wp[k]);
	
		for(kk = k+1; ; kk++){
		    assert(kk <= n_rank-1); 
		    // if th[n_rank] = INFTY, 
		    // then the assertion should be true
		    wwn += wn[kk];
		    wwp += wp[kk];
		    th[kk] = 0.5 * log(wwn / wwp);
		    if (std::isnan(th[kk]))
			th[kk] = th[kk+1];

		    if (th[kk] <= th[kk+1])
			break;
		}
		//update from k to kk
		while(kk > k){
		    kk--;
		    th[kk] = th[kk+1];
		}
	    }
	}
    }

    void AggRank::compute_thres_dploss(vREAL& th, bool do_abs){
	std::map<REAL, std::vector<UINT> > declbl;
	std::vector<vREAL> cost;
	std::map<REAL, std::vector<UINT> >::iterator it;
	vREAL threserr(n_rank+1);
	for(UINT j = 0; j < n_samples; ++j)
	    declbl[dec_value[j]].push_back((UINT)(ptd->y(j)[0]));

	it = declbl.begin();
	cost.resize(declbl.size());
	cost[0].resize(n_rank * 2 + 1);
	cost[0][0] = it->first;
	for(UINT k = 1; k <= n_rank; ++k){
	    REAL loss = 0;
	    for(std::vector<UINT>::iterator in = it->second.begin(); 
		in != it->second.end(); in++)
		if (*in != k) loss += (do_abs ? fabs(REAL(*in) - REAL(k)) : 1);

	    cost[0][k] = loss;
	    cost[0][k+n_rank] = -1;
	}

	++it;
	for(UINT n = 1; it != declbl.end(); it++, n++){
	    REAL bestloss = std::numeric_limits<REAL>::infinity();
	    REAL bestidx = -1;
	    cost[n].resize(n_rank * 2 + 1);
	    cost[n][0] = it->first;
	    for(UINT k = 1; k <= n_rank; ++k){
		if (cost[n-1][k] < bestloss){
		    bestloss = cost[n-1][k];
		    bestidx = k;
		}
		REAL loss = bestloss;
		for(std::vector<UINT>::iterator in = it->second.begin(); 
		    in != it->second.end(); in++)
		    if (*in != k) 
			loss += (do_abs ? fabs(REAL(*in) - REAL(k)) : 1);
		cost[n][k] = loss;
		cost[n][k+n_rank] = bestidx;
	    }
	}
    
	UINT bestidx = 1;
	UINT nCost = cost.size();
	for(UINT k = 1; k <= n_rank; ++k){
	    if (cost[nCost-1][k] < cost[nCost-1][bestidx])
		bestidx = k;
	}
	for(UINT j = bestidx; j < n_rank; ++j)
	    th[j] = std::numeric_limits<REAL>::max();

	for(UINT n = nCost-1; n > 0; n--){
	    UINT nextidx = (UINT)(cost[n][bestidx + n_rank]);
	    if (bestidx != nextidx){
		for(UINT j = nextidx; j < bestidx; ++j)
		    th[j] = (cost[n][0] + cost[n-1][0]) * 0.5;
		bestidx = nextidx;	    
	    }
	}    
	for(UINT j = 1; j < bestidx; ++j)
	    th[j] = -std::numeric_limits<REAL>::max();
    }
} //namespace lemga
