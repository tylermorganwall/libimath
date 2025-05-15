---
output: github_document
---

# Imath

<!-- badges: start -->
[![R-CMD-check](https://github.com/username/imath/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/username/imath/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Static build of Academy Software Foundation's [`Imath`](https://github.com/AcademySoftwareFoundation/Imath) C++ library for R. Imath is a basic, light-weight, and efficient C++ representation of 2D and 3D vectors, matrices, and other mathematical objects, functions, and data types common in computer graphics applications, including the `half` 16-bit floating-point type. It is not a generic linear algebra library (like Eigen), but rather one specialized for 2D and 3D transformations common in computer graphics.

The installed package includes a **static** copy of the C++ library (along with CMake config files) so you can use Imath functionality in your package without requiring the user to separately install Imath as a system dependency. This package does not provide an R API--rather, it simply makes the `Imath` C++ library available to other R packages.

`Imath` is maintained by the OpenEXR project, a part of the Academy Software Foundation (ASWF).

## Features

The `Imath` library provides:

- **Vectors**: 2D, 3D, and 4D vector representations and operations
- **Matrices**: 2x2, 3x3, and 4x4 matrix operations
- **Half Float**: 16-bit floating point type and operations
- **Quaternions**: Quaternion operations for rotations
- **Bounding Boxes**: 2D and 3D bounding box representations
- **Colors**: RGB and RGBA color representations
- **Euler Angles**: Angle representation operations
- **Transformations**: Functions for coordinate transformations

For detailed information on the Imath API, please refer to the [Imath documentation](https://imath.readthedocs.io/).

---

## Installation

```r
# once released on CRAN
install.packages("tylermorganwall/libimath")

# development version
remotes::install_github("tylermorganwall/libimath")
```

No external libraries are required—the `Imath` static library is built and installed during the R package install.

---

## Using the bundled static library in your own packages

The package installs:

```
lib/<R_ARCH>/libImath-3_2.a        # static archive (version 3.2)
lib/<R_ARCH>/cmake/Imath/*         # CMake config files
include/Imath/*                    # public headers
```

`R_ARCH` can be obtained in R via `Sys.info()[["machine"]]`.

### Makevars-style linkage

The version (3_2) is appended after the library name: add this to link the static library.

```make
## configure
IMATH_DIR=$(Rscript -e 'cat(system.file("lib", Sys.info()[["machine"]], package = "libimath"))')
CPPFLAGS += -I$(IMATH_DIR)/../include
PKG_LIBS += -L$(IMATH_DIR) -lImath-3_2
```

### CMake consumers

Call this R code in your configure step to determine the location of the CMake config files:

```r
IMATH_LIB_ARCH = normalizePath(sprintf(
  "%s/%s",
  system.file(
    "lib",
    package = "libimath",
    mustWork = TRUE
  ),
  Sys.info()[["machine"]]
))

IMATH_CMAKE_CONFIG = file.path(IMATH_LIB_ARCH, "cmake", "Imath")
```
