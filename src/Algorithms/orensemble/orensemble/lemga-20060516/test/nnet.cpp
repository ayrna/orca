/* $Id: nnet.cpp 1907 2004-12-11 00:51:14Z ling $ */

#include <iostream>
#include <fstream>
#include <lemga/random.h>
#include <lemga/nnlayer.h>
#include <lemga/feedforwardnn.h>

int main (unsigned int argc, char* argv[]) {
    if (argc < 6) {
        std::cerr << "Usage: " << argv[0] << " datafile n_train n_test"
                  << " #_input #_hidden ... #_output\n";
        return -1;
    }

    set_seed(0);

    /* constructing neural nets with layers */
    UINT n_in = atoi(argv[4]);
    lemga::FeedForwardNN nn;

    std::cout << "Neural network " << n_in;
    UINT l_in = n_in;
    for (UINT i = 5; i < argc; ++i) {
        UINT l_out = atoi(argv[i]);
        std::cout << 'x' << l_out;

        lemga::NNLayer l(l_in, l_out);
        l.set_weight_range(-0.2, 0.2);
        nn.add_top(l);

        l_in = l_out;
    }
    std::cout << " constructed\n";
    UINT n_out = l_in;

    /* open data file */
    std::ifstream fd(argv[1]);
    if (!fd.is_open()) {
        std::cerr << argv[0] << ": data file ("
                  << argv[1] << ") open error\n";
        return -2;
    }

    /* load training and test data */
    lemga::pDataSet trd = lemga::load_data(fd, atoi(argv[2]), n_in, n_out);
    lemga::pDataSet ted = lemga::load_data(fd, atoi(argv[3]), n_in, n_out);
    std::cout << trd->size() << " training samples and "
              << ted->size() << " test samples loaded\n";
    fd.close();

    /* train the neural network */
    nn.initialize();
    nn.set_train_data(trd);
    nn.set_train_method(nn.CONJUGATE_GRADIENT);
    nn.set_parameter(0.1, 1e-4, 1000);
    nn.train();

    /* save the neural network to a file */
    std::ofstream fw("nnet.lm");
    if (!(fw << nn)) {
        std::cerr << argv[0] << ": neural network file save error\n";
        return -3;
    }
    std::cout << "network saved\n";
    fw.close();

    /* load the network back */
    lemga::FeedForwardNN nn2;
    std::ifstream fr("nnet.lm");
    if (!(fr >> nn2)) {
        std::cerr << argv[0] << ": neural network file save error\n";
        return -3;
    }
    std::cout << "network loaded\n";
    fr.close();

    /* test the network */
    double tre = 0, tee = 0;
    for (UINT i = 0; i < trd->size(); ++i)
        tre += nn2.r_error(nn2(trd->x(i)), trd->y(i));
    for (UINT i = 0; i < ted->size(); ++i)
        tee += nn2.r_error(nn2(ted->x(i)), ted->y(i));
    std::cout << "training error: " << tre / trd->size()
              << ", test error: " << tee / ted->size() << "\n";

    return 0;
}
