# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenCL"
version = v"2022.09.23"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/KhronosGroup/OpenCL-Headers.git", "4c50fabe3774bad4bdda9c1ca92c82574109a74a"),
    GitSource("https://github.com/KhronosGroup/OpenCL-ICD-Loader.git", "3dae4803532b11d74e4dc216ee72570c1a4bff24"),
    FileSource("https://patch-diff.githubusercontent.com/raw/KhronosGroup/OpenCL-Headers/pull/209.patch",
               "c3afd4ad0a37f0b61c0b8656ca4914002ba7994bba05aa2c47fde59b652289c9"),
    FileSource("https://patch-diff.githubusercontent.com/raw/KhronosGroup/OpenCL-ICD-Loader/pull/185.patch",
               "82725e3ec4e9fe333aeb53f75e13b74cef22c7cb662ee2af51108f0d764e1985")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

install_license ./OpenCL-Headers/LICENSE

patch ./OpenCL-Headers/tests/test_headers.c 209.patch
patch ./OpenCL-ICD-Loader/loader/icd_platform.h 185.patch

cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -S ./OpenCL-Headers -B ./OpenCL-Headers/build
cmake --build ./OpenCL-Headers/build --target install -j${nproc}

cmake -DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -S ./OpenCL-ICD-Loader -B ./OpenCL-ICD-Loader/build
cmake --build ./OpenCL-ICD-Loader/build --target install -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    FileProduct("include/CL/cl.h", :cl_h),
    LibraryProduct("libOpenCL", :libopencl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")
