/**
   aggrank.h: an abstract class for general thresholded ensembles
   (c) 2006-2007 Hsuan-Tien Lin
**/
#ifndef __LEMGA_AGGREGATING_AGGRANK_H__
#define __LEMGA_AGGREGATING_AGGRANK_H__

#include <aggregating.h>


namespace lemga {

    typedef std::vector<REAL> vREAL;

    class AggRank : public Aggregating {
    public:
	enum {THRES_EXPLOSS, THRES_EXPLOSS_ORDERED, 
	      THRES_ABSLOSS, THRES_CLALOSS};
	enum {INIT_ZERO, INIT_NAIVE, INIT_RAND};

    protected:
	UINT n_rank;

#define n_thres (n_rank - 1)

	vREAL lm_wgt;
	vREAL thres; //of size (n_iter+1) * n_thres

	vREAL dec_value;

	UINT thres_mode;
	UINT init_mode;

    public:
	explicit AggRank (UINT _n_rank = 2): 
	    thres_mode(THRES_ABSLOSS), init_mode(INIT_ZERO) {
	    set_n_rank(_n_rank); 
	}
	explicit AggRank (std::istream& is) { is >> *this; }

	virtual AggRank* create () const = 0;
	virtual AggRank* clone () const = 0;
	virtual bool support_weighted_data () const { return false; }

	REAL model_weight (UINT n) const { return lm_wgt[n]; }
	REAL threshold (UINT iter, UINT k) const {
	    assert(k > 0 && k <= n_thres && iter <= n_in_agg); 
	    return thres[iter * n_thres + (k-1)]; 
	}
	UINT get_n_rank () const { return n_rank; }

	void set_n_rank (UINT _n_rank) { 
	    assert(_n_rank >= 1); n_rank = _n_rank; 
	}
	void set_init_mode (UINT _init_mode) { init_mode = _init_mode; }
	void set_thres_mode (UINT _thres_mode) { thres_mode = _thres_mode; }
    protected:
	virtual bool serialize (std::ostream&, ver_list&) const;
	virtual bool unserialize (std::istream&, ver_list&,
				  const id_t& = NIL_ID);
    public:
	virtual Output operator() (const Input&, UINT) const;
	virtual Output operator() (const Input& _in) const { 
	    return operator()(_in, n_in_agg); 
	}

	virtual void reset();
	virtual void train () = 0;
	virtual void set_reg_param (REAL) = 0;
    protected:
	//should be in a level of boosting rather than aggregating
	pLearnModel learn_weak(const vREAL& rhopos, 
					const vREAL& rhoneg, 
					const REAL sum_rhodiff);
	void recompute_dec();
	void compute_thres(vREAL::iterator it);
	void compute_thres_exploss(vREAL& th, bool ordered, bool full);
	void compute_thres_dploss(vREAL& th, bool do_abs);
    };
} // namespace lemga

#ifdef  __AGGRANK_H__
#warning "This header file may conflict with another `aggrank.h' file."
#endif
#define __AGGRANK_H__
#endif
