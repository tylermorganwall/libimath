## Fixes v3.1.9-3

This version fixes the issues with compiling on the CRAN 'blackswan' test environment, which resulted from failing to account for that build environment's use of aliases/symlinks to pass in the compiler cache tool 'ccache'. The prior version checked for 'ccache', but failed in the case where 'ccache' use was not explicit (as it called 'normalizePath()' after finding the compiler, which expanded the symlink):

$ ln -s $(which ccache) clang
$ ./clang -v
Apple clang version 15.0.0 (clang-1500.3.9.4)
$ Rscript -e 'normalizePath("./clang")'
[1] "/usr/local/Cellar/ccache/4.5.1/bin/ccache"

This version fixes that behavior.

(thanks to Ivan Krylov on r-package-devel for helping debug this issue)

### CHECK output

This version has been successfully checked on 30 runners on r-hub, all three win-builder environments, and mac-builder.

## Fixes

The configure script has been updated to account for the potential use of ccache when compiling the library.