#define R_NO_REMAP

#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Print.h> 
#include <R_ext/Memory.h> 

#include <Imath/ImathConfig.h>

SEXP C_print_imath_version(void) {
    const char version[] = IMATH_VERSION_STRING;
    Rprintf("Imath version %s", version);
    return(R_NilValue);
}

//=== registration ===========================================================

static const R_CallMethodDef CallEntries[] = {
    {"C_print_imath_version",   (DL_FUNC) &C_print_imath_version,   0},
    {NULL, NULL, 0}
};

void R_init_libdeflatewrapper(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
