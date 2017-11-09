#include <iostream>
#include <fstream>
#include <lemga/object.h>
// Though we don't need other LEMGA header files here, we do
// need to link all modules.

bool show_lm (std::istream& is) {
    /* load the model */
    Object *p = Object::create(is);
    if (p == 0) return false;

    std::cout << "File loaded:\n" << *p;
    delete p;
    return true;
}

int main (unsigned int argc, char* argv[]) {
    bool ok;
    if (argc < 2) ok = show_lm(std::cin);
    else {
        std::ifstream fr(argv[1]);
        ok = show_lm(fr);
        fr.close();
    }
    if (!ok)
        std::cerr << argv[0] << ": model load error\n";
    return !ok;
}
