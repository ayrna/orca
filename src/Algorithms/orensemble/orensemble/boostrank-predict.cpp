/**
   boostrank-predict.cpp: main file for performing ordinal regression testing
   with thresholded ensemble models
   (c) 2006-2007 Hsuan-Tien Lin
**/
#include <iostream>
#include <fstream>
#include <set>

#include "aggrank.h"
#include "orboost.h"
#include "rankboost.h"

#include <object.h>
#include <stump.h>
#include <perceptron.h>

#include "softperc.h"

int main (int argc, char* argv[]) {
    if (argc < 7) {
        std::cerr << "Usage: " << argv[0] << " datafile n_test"
                  << " #_input modelfile iter valuefile\n";
        exit(-1);
    }

    /* open data file */
    std::ifstream fd(argv[1]);
    if (!fd.is_open()) {
        std::cerr << argv[0] << ": data file ("
                  << argv[1] << ") open error\n";
        exit(-2);
    }
    UINT n_test = atoi(argv[2]);
    UINT n_in = atoi(argv[3]);
    UINT n_out = 1;
    std::ifstream fm(argv[4]);
    if (!fm.is_open()) {
        std::cerr << argv[0] << ": model file ("
                  << argv[4] << ") open error\n";
        exit(-2);
    }
    UINT iter = atoi(argv[5]);
    std::ofstream fv(argv[6]);

    /* load test data */
    lemga::pDataSet ted = lemga::load_data(fd, n_test, n_in, n_out);
    fd.close();

    lemga::AggRank *pbag = (lemga::AggRank*) Object::create(fm);
    fm.close();
    
    UINT n_rank = pbag->get_n_rank();
    std::vector<lemga::Output> out(ted->size());
    std::vector< std::set<UINT> > group(n_rank);
    std::vector<REAL> tbl(n_rank * n_rank);

    REAL ae(0.0), ce(0.0), rl(0.0), tl(0.0);

    REAL n_crit(0.0);
    {
      std::vector<UINT> n_goal(n_rank);
      
      n_goal.clear();
      n_goal.insert(n_goal.begin(), n_rank, 0);
      for (UINT i = 0; i < ted->size(); ++i){
	UINT goal = (UINT)(ted->y(i)[0] - 1);
	n_goal[goal] ++;
      }

      REAL larger = ted->size();
      for(UINT k = 0; k < n_rank; k++){
	larger -= n_goal[k];
	n_crit += n_goal[k] * larger;
      }
    }

    for(UINT k = 0; k < n_rank; k++)
      group[k].clear();

    tbl.clear();
    tbl.insert(tbl.begin(), n_rank * n_rank, 0);
    
    for (UINT i = 0; i < ted->size(); ++i){
      out[i] = (*pbag)(ted->x(i), iter);      
      UINT goal = (UINT)(ted->y(i)[0] - 1);
      UINT pred = (UINT)(out[i][0] - 1);

      fv << out[i][0] << ' ' << out[i][1] << std::endl;

      group[pred].insert(i);
      tbl[pred * n_rank + goal]++;
    }

    for(UINT pred=0;pred<n_rank;pred++){
      for(UINT goal=0;goal<n_rank;goal++){
	if (pred != goal){
	  ce += tbl[pred*n_rank + goal];
	  ae += tbl[pred*n_rank + goal] * fabs(REAL(pred) - REAL(goal));
	}
      }
    }

    REAL tlt(0.0), rlt(0.0);
    for(UINT goal1=0;goal1<n_rank;goal1++){
      for(UINT goal2=goal1+1;goal2<n_rank;goal2++){
	//all pairs that goal1 < goal2 (critical pairs)

	for(UINT pred1=0;pred1<n_rank;pred1++){
	  for(UINT pred2=0;pred2<pred1;pred2++){
	    //pred1 > pred2: absolutely wrong
	    tlt += tbl[pred1*n_rank + goal1] * tbl[pred2*n_rank + goal2];
	    rlt += tbl[pred1*n_rank + goal1] * tbl[pred2*n_rank + goal2];
	  }
	}
      }
    }

    for(UINT pred=0;pred<n_rank;pred++){
      //check within every equal prediction group to see if missing critical pairs
      for(std::set<UINT>::iterator j = group[pred].begin(); 
	  j != group[pred].end(); ++j){
	for(std::set<UINT>::iterator k = group[pred].begin(); 
	    k != group[pred].end(); ++k){
	  UINT ij = (*j);
	  UINT ik = (*k);
	  if (ted->y(ij)[0] < ted->y(ik)[0]){
	    tlt += 0.5; //thresholded rank loss
	    
	    REAL diff = out[ij][1] - out[ik][1];
	    if (diff > 0)
	      rlt ++;
	    else if (diff == 0)
	      rlt += 0.5;
	  }
	}
      }
    }

    ae = ae / n_test;
    ce = ce / n_test;
    tl = tlt / n_crit;
    rl = rlt / n_crit;

    //std::cout << "Absolute Error: " << ae << std::endl;
    //std::cout << "Classification Error: " << ce << std::endl;
    //std::cout << "Raw Ranking Loss: " << rl << std::endl;
    //std::cout << "Thresholded Ranking Loss: " << tl << std::endl;
    return 0;
}
