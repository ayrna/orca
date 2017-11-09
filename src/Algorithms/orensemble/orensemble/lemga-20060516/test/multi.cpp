/* $Id: multi.cpp 2891 2006-11-08 03:17:31Z ling $ */

#include <iostream>
#include <fstream>
#include <lemga/perceptron.h>
#include <lemga/adaboost.h>
#include <lemga/multiclass_ecoc.h>

int main (unsigned int argc, char* argv[]) {
    if (argc < 4) {
        std::cerr << "Usage: " << argv[0] << " datafile n_train n_test\n";
        return -1;
    }

    /* open data file */
    std::ifstream fd(argv[1]);
    if (!fd.is_open()) {
        std::cerr << argv[0] << ": data file ("
                  << argv[1] << ") open error\n";
        return -2;
    }

    /* load training and test data */
    lemga::pDataSet trd = lemga::load_data(fd, atoi(argv[2]));
    const UINT n_in = trd->x(0).size();
    lemga::pDataSet ted = lemga::load_data(fd, atoi(argv[3]), n_in, 1);
    std::cout << trd->size() << " training samples and "
              << ted->size() << " test samples loaded\n";
    fd.close();

    /* base model */
    set_seed(0); // perceptron learning may need this
    lemga::Perceptron p;
    p.set_parameter(0.002, 0, 500);
    p.set_train_method(p.RCD_BIAS);
    p.set_weight(lemga::Input(n_in+1,0));
    //p.start_with_fld();

    lemga::AdaBoost agg;
    agg.set_base_model(p);
    // no AdaBoost init, to keep the initial perceptron zero weight
    agg.set_max_models(50);

    /* ECOC model */
    lemga::MultiClass_ECOC mult;
    mult.set_base_model(agg);
    mult.set_ECOC_table(lemga::ONE_VS_ALL);
    mult.set_train_data(trd);
    mult.train();

    std::ofstream fw("multi-perc.lm");
    if (!(fw << mult)) {
        std::cerr << argv[0] << ": MultiClass file save error\n";
        return -3;
    }
    std::cout << "MultiClass saved\n";
    fw.close();

    /* test the performance */
    double tre(0), tee(0);
    for (UINT i = 0; i < trd->size(); ++i)
        tre += mult.c_error(mult(trd->x(i)), trd->y(i));
    for (UINT i = 0; i < ted->size(); ++i)
        tee += mult.c_error(mult(ted->x(i)), ted->y(i));

    std::cout << "training error: " << 100*tre/trd->size()
              << "%,\ttest error: " << 100*tee/ted->size() << "%\n";

    return 0;
}
