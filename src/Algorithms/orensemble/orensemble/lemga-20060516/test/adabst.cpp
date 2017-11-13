/* $Id: adabst.cpp 2664 2006-03-07 19:50:51Z ling $ */

#include <iostream>
#include <fstream>
#include <lemga/pulse.h>
#include <lemga/adaboost.h>
#include <lemga/mgnboost.h>

int main (unsigned int argc, char* argv[]) {
    if (argc < 5) {
        std::cerr << "Usage: " << argv[0] << " datafile n_train n_test"
                  << " #_AdaBoost\n";
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
    lemga::Pulse st;
    st.set_max_transitions(3);
    lemga::AdaBoost ada;
    lemga::MgnBoost mgn;
    ada.set_base_model(st);
    mgn.set_base_model(st);

    /* train the AdaBoost of pulses */
    ada.set_max_models(atoi(argv[4]));
    ada.set_train_data(trd);
    ada.train();

    /* train the MgnBoost of pulses */
    mgn.set_max_models(atoi(argv[4]));
    mgn.set_train_data(trd);
    mgn.train();

    std::cout << "Minimal margin: AdaBoost "
              << ada.min_margin() / ada.margin_norm()
              << ", arc-gv "
              << mgn.min_margin() / mgn.margin_norm() << '\n';

    /* save the AdaBoost to a file */
    std::ofstream fw("adapulse.lm");
    if (!(fw << ada)) {
        std::cerr << argv[0] << ": AdaBoost file save error\n";
        return -3;
    }
    std::cout << "AdaBoost saved\n";
    fw.close();

    /* load the AdaBoost back */
    lemga::AdaBoost ad2;
    std::ifstream fr("adapulse.lm");
    if (!(fr >> ad2)) {
        std::cerr << argv[0] << ": AdaBoost file load error\n";
        return -3;
    }
    std::cout << "AdaBoost loaded\n";
    fr.close();

    /* test the AdaBoost */
    double ada_tre(0), ada_tee(0), mgn_tre(0), mgn_tee(0);
    for (UINT i = 0; i < trd->size(); ++i) {
        ada_tre += st.c_error(ad2(trd->x(i)), trd->y(i));
        mgn_tre += st.c_error(mgn(trd->x(i)), trd->y(i));
    }
    for (UINT i = 0; i < ted->size(); ++i) {
        ada_tee += st.c_error(ad2(ted->x(i)), ted->y(i));
        mgn_tee += st.c_error(mgn(ted->x(i)), ted->y(i));
    }
    std::cout << "training error: AdaBoost " << ada_tre / trd->size()
              << ",\tarc-gv " << mgn_tre / trd->size() << '\n';
    std::cout << "    test error: AdaBoost " << ada_tee / ted->size()
              << ",\tarc-gv " << mgn_tee / ted->size() << '\n';

    return 0;
}
