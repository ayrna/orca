/** @file
 *  $Id: utility.cpp 2631 2006-02-08 21:58:14Z ling $
 */

#include <cmath>
#include <assert.h>
#include "utility.h"

typedef std::vector<REAL> RVEC;
typedef std::vector<RVEC> RMAT;

// from the Numerical Recipes in C
bool Cholesky_decomp (RMAT& A, RVEC& p) {
    const UINT n = A.size();
    assert(p.size() == n);
    for (UINT i = 0; i < n; ++i) {
        for (UINT j = i; j < n; ++j) {
            REAL sum = A[i][j];
            for (UINT k = 0; k < i; ++k)
                sum -= A[i][k] * A[j][k];
            if (i == j) {
                if (sum <= 0)
                    return false;
                p[i] = std::sqrt(sum);
            } else
                A[j][i] = sum / p[i];
        }
    }
    return true;
}

// from the Numerical Recipes in C
void Cholesky_linsol (const RMAT& A, const RVEC& p, const RVEC& b, RVEC& x) {
    const UINT n = A.size();
    assert(p.size() == n && b.size() == n);
    x.resize(n);

    for (UINT i = 0; i < n; ++i) {
        REAL sum = b[i];
        for (UINT k = 0; k < i; ++k)
            sum -= A[i][k] * x[k];
        x[i] = sum / p[i];
    }
    for (UINT i = n; i--;) {
        REAL sum = x[i];
        for (UINT k = i+1; k < n; ++k)
            sum -= A[k][i] * x[k];
        x[i] = sum / p[i];
    }
}

bool ldivide (RMAT& A, const RVEC& b, RVEC& x) {
    const UINT n = A.size();
    assert(b.size() == n);
    RVEC p(n);
    if (!Cholesky_decomp(A, p)) return false;
    Cholesky_linsol(A, p, b, x);
    return true;
}
