/* $Id: bag.cpp 2664 2006-03-07 19:50:51Z ling $ */

#include <iostream>
#include <fstream>
#include <lemga/stump.h>
#include <lemga/bagging.h>

int main (unsigned int argc, char* argv[]) {
    if (argc < 5) {
        std::cerr << "Usage: " << argv[0] << " datafile n_train n_test"
                  << " #_bagging\n";
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
    lemga::Bagging bag;
    bag.set_base_model(st);

    /* train the bagging of stumps */
    bag.set_max_models(atoi(argv[4]));
    bag.set_train_data(trd);
    bag.train();

    /* save the bagging to a file */
    std::ofstream fw("bagstump.lm");
    if (!(fw << bag)) {
        std::cerr << argv[0] << ": bagging file save error\n";
        return -3;
    }
    std::cout << "bagging saved\n";
    fw.close();

    /* load the bagging back */
    lemga::Bagging bag2;
    std::ifstream fr("bagstump.lm");
    if (!(fr >> bag2)) {
        std::cerr << argv[0] << ": bagging file load error\n";
        return -3;
    }
    std::cout << "bagging loaded\n";
    fr.close();

    /* test the bagging */
    double tre = 0, tee = 0;
    for (UINT i = 0; i < trd->size(); ++i)
        tre += st.c_error(bag(trd->x(i)), trd->y(i));
    for (UINT i = 0; i < ted->size(); ++i)
        tee += st.c_error(bag2(ted->x(i)), ted->y(i));
    std::cout << "training error: " << tre / trd->size()
              << ", test error: " << tee / ted->size() << "\n";

    return 0;
}
