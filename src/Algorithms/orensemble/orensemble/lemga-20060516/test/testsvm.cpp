/* $Id: testsvm.cpp 2557 2006-01-19 00:43:17Z ling $ */

#include <iostream>
#include <fstream>
#include <lemga/random.h>
#include <lemga/crossval.h>
#include <lemga/svm.h>

int main (unsigned int argc, char* argv[]) {
    if (argc < 4) {
        std::cerr << "Usage: " << argv[0] << " datafile n_train n_test"
                  << "\n";
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

#if 1
    /* set up cross-validation */
    set_seed(0);
    lemga::vFoldCrossVal cv;
    cv.set_folds(5, 4); // folds = 5, repeating 4 times

    /* set up different kernels & C values */
    std::vector<lemga::kernel::Kernel*> ker;
    ker.push_back(new lemga::kernel::RBF(0.5));
    ker.push_back(new lemga::kernel::Stump);
    ker.push_back(new lemga::kernel::Perceptron);
    for (UINT i = 0; i < ker.size(); delete ker[i++]) {
        lemga::SVM svm(*ker[i]);
        for (int c = 0; c < 4; ++c) {
            svm.set_C(1 << c);
            cv.add_model(svm);
        }
    }
    cv.set_train_data(trd);
    cv.set_full_train(false);
    cv.train();

    // output the CV errors
    std::cout.precision(4);
    UINT nc = cv.size()/ker.size();
    for (UINT i = 0; i < nc; ++i)
        std::cout << "\tC=" << ((lemga::SVM&) cv.model(i)).C();
    for (UINT i = 0; i < cv.size(); ++i) {
        if (i % nc == 0)
            std::cout << '\n' <<
                ((lemga::SVM&) cv.model(i)).kernel().id().substr(15,7);
        std::cout << '\t' << 100*cv.error(i) << '%';
    }

    // train the best model
    lemga::pLearnModel plm = cv.best_model().clone();
    lemga::SVM& svm = (lemga::SVM&) *plm;
#else // OR if no validation is wanted, simply do
    lemga::kernel::RBF kernel(0.5);
    lemga::SVM svm(kernel);
    svm.set_C(10);
#endif

    std::cout << "\nTrain on the model with " << svm.kernel().id().substr(15)
              << " and C = " << svm.C() << '\n';
    svm.set_train_data(trd);
    svm.train();
    std::cout << "Total " << svm.n_support_vectors() << " support vectors."
              << " Please check with svm_train() output above.\n";
    std::cout << "training error: " << svm.train_c_error()*100
              << "%, test error: " << svm.test_c_error(ted)*100 << "%\n";

    return 0;
}
