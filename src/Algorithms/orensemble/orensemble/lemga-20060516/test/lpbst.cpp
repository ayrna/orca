/* $Id: lpbst.cpp 2664 2006-03-07 19:50:51Z ling $ */

#include <iostream>
#include <fstream>
#include <lemga/stump.h>
#include <lemga/adaboost.h>
#include <lemga/lpboost.h>

int main (unsigned int argc, char* argv[]) {
    if (argc < 5) {
        std::cerr << "Usage: " << argv[0] << " datafile n_train n_test"
                  << " #_boost\n";
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
    lemga::pDataSet ted = lemga::load_data(fd, atoi(argv[3]));
    std::cout << trd->size() << " training samples and "
              << ted->size() << " test samples loaded\n";
    fd.close();

    /* set base model */
    lemga::Stump st;
    lemga::AdaBoost ada;
    lemga::LPBoost lpb;
    ada.set_base_model(st);
    lpb.set_base_model(st);

    /* train the AdaBoost of stumps */
    ada.set_max_models(atoi(argv[4]));
    ada.set_train_data(trd);
    ada.train();

    /* train the LPBoost of stumps */
    lpb.set_max_models(atoi(argv[4]));
    lpb.set_C(10);
    lpb.set_train_data(trd);
    lpb.train();

    std::cout << "Minimal margin: AdaBoost "
              << ada.min_margin() / ada.margin_norm()
              << ", LPBoost "
              << lpb.min_margin() / lpb.margin_norm() << '\n';

    /* test the performance */
    double ada_tre(0), ada_tee(0), lpb_tre(0), lpb_tee(0);
    for (UINT i = 0; i < trd->size(); ++i) {
        ada_tre += st.c_error(ada(trd->x(i)), trd->y(i));
        lpb_tre += st.c_error(lpb(trd->x(i)), trd->y(i));
    }
    for (UINT i = 0; i < ted->size(); ++i) {
        ada_tee += st.c_error(ada(ted->x(i)), ted->y(i));
        lpb_tee += st.c_error(lpb(ted->x(i)), ted->y(i));
    }
    std::cout << "training error: AdaBoost " << 100*ada_tre/trd->size()
              << "%,\tLPBoost " << 100*lpb_tre/trd->size() << "%\n";
    std::cout << "    test error: AdaBoost " << 100*ada_tee/ted->size()
              << "%,\tLPBoost " << 100*lpb_tee/ted->size() << "%\n";

    return 0;
}
