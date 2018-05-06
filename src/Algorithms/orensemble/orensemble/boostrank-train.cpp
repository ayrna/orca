/**
   boostrank-train.cpp: main file for performing ordinal regression training
   with various thresholded ensemble algorithms
   (c) 2006-2007 Hsuan-Tien Lin
**/
#include <iostream>
#include <fstream>

#include "aggrank.h"
#include "orboost.h"
#include "rankboost.h"
#include <nnlayer.h>
#include <feedforwardnn.h>

#include <stump.h>
#include <perceptron.h>

#include "softperc.h"

void exit_error(char** argv) {
  std::cerr << "Usage: " << argv[0] << " trainfile n_train"
	    << " #_input bag base n_rank iter modelfile\n"
	    << "bag : 10 = RankBoost, cla_thres, reg_param=0.0\n"
	    << "      11 = RankBoost, cla_thres, reg_param=1e-32\n"
	    << "      20 = RankBoost, abs_thres, reg_param=0.0\n"
	    << "      21 = RankBoost, abs_thres, reg_param=1e-32\n"
	    << "      30 = ORBoost, FORM_LR, ordered, sub_iter=1, reg_param=0.0\n"
	    << "      31 = ORBoost, FORM_LR, ordered, sub_iter=1, reg_param=1e-32\n"
	    << "      40 = ORBoost, FORM_FULL, ordered, sub_iter=1, reg_param=0.0\n"
	    << "      41 = ORBoost, FORM_FULL, ordered, sub_iter=1, reg_param=1e-32\n"
	    << "base: 100 = stump (without constant)\n"
	    << "      200 = perc200 with special bias\n"
	    << "      201 = perc200 with special bias, scale=1\n"
	    << "      204 = perc200 with special bias, scale=4\n"
	    << "      3HH = neural net, number of hidden neurons=HH\n";
  exit(-1);
}

int main (int argc, char* argv[]) {
  if (argc < 9)
    exit_error(argv);

  /* open data file */
  std::ifstream fd(argv[1]);
  if (!fd.is_open()) {
    std::cerr << argv[0] << ": training data file ("
	      << argv[1] << ") open error\n";
    exit(-2);
  }
  UINT n_train = atoi(argv[2]);  
  UINT n_in = atoi(argv[3]);
  UINT n_out = 1;
  UINT bag = atoi(argv[4]);
  UINT base = atoi(argv[5]);
  UINT n_rank = atoi(argv[6]);
  UINT n_iter = atoi(argv[7]);
  std::ofstream fm(argv[8]);

  /* load training data */
  lemga::DataSet *trd = lemga::load_data(fd, n_train, n_in, n_out);
  fd.close();


  lemga::LearnModel *pst = 0;

  switch(base){
  case 100:
    {
      lemga::Stump* p = new lemga::Stump(n_in);
      pst = p;
      break;
    }
  case 200:
    {
      lemga::Perceptron* p = new lemga::Perceptron(n_in);
      p->set_parameter(0, 0, 200);
      p->set_train_method(lemga::Perceptron::RAND_COOR_DESCENT_BIAS);
      pst = p;
      break;
    }
  case 201:
    {
      lemga::SoftPerc* p = new lemga::SoftPerc(n_in);
      p->set_parameter(0, 0, 200);
      p->set_train_method(lemga::Perceptron::RAND_COOR_DESCENT_BIAS);
      p->set_scale(1);
      pst = p;
      break;
    }
  case 204:
    {
      lemga::SoftPerc* p = new lemga::SoftPerc(n_in);
      p->set_parameter(0, 0, 200);
      p->set_train_method(lemga::Perceptron::RAND_COOR_DESCENT_BIAS);
      p->set_scale(4);
      pst = p;
      break;
    }
  default:
    if(base/300==1)
    {
      lemga::FeedForwardNN* p = new lemga::FeedForwardNN();
      lemga::NNLayer l(n_in, base%300);
      l.set_weight_range(-1, 1);
      p->add_top(l);
      lemga::NNLayer lout(base%300,1);
      lout.set_weight_range(-1, 1);
      p->add_top(lout);
      p->set_train_method(lemga::FeedForwardNN::CONJUGATE_GRADIENT);
      p->set_parameter(0.1, 1e-7, 200); // 1e-10, 2000
      p->initialize();
      pst = p;
      break;
    }
    else
    {
      std::cerr << base << " is not a correct base learner\n";
      exit(-1);
    }
  }


  lemga::AggRank *pbag = 0;
  
  switch(bag/10){
  case 1:
    {
      lemga::RankBoost* p = new lemga::RankBoost(n_rank);
      p->set_thres_mode(lemga::AggRank::THRES_CLALOSS);
      pbag = p;
      break;
    }
  case 2:
    {
      lemga::RankBoost* p = new lemga::RankBoost(n_rank);
      p->set_thres_mode(lemga::AggRank::THRES_ABSLOSS);
      pbag = p;
      break;
    }
  case 3:
    {
      lemga::ORBoost* p = new lemga::ORBoost(n_rank);
      p->set_sub_iter(1);
      p->set_ordered(true);
      p->set_form(lemga::ORBoost::FORM_LR);      
      pbag = p;
      break;
    }
  case 4:
    {
      lemga::ORBoost* p = new lemga::ORBoost(n_rank);
      p->set_sub_iter(1);
      p->set_ordered(true);
      p->set_form(lemga::ORBoost::FORM_FULL);      
      pbag = p;
      break;
    }
  }

  if (bag % 10 == 1)
    pbag->set_reg_param(1e-32);
  else
    pbag->set_reg_param(0.0);

  pbag->set_base_model(*pst);
  pbag->set_max_models(n_iter);
  pbag->reset();

  pbag->set_train_data(trd);
  pbag->train();

  fm << (*pbag);
  fm.close();

  // let C++ free things
  return 0;
}
