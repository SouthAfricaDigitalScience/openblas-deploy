#!/bin/bash -e
# this should be run after check-build finishes.
. /etc/profile.d/modules.sh
echo ${SOFT_DIR}
module add deploy
module add gcc/${GCC_VERSION}
echo ${SOFT_DIR}
cd ${WORKSPACE}/${NAME}-${VERSION}
echo "All tests have passed, will now build into ${SOFT_DIR}"
# cmake . \
# -G"Unix Makefiles" \
# -DCMAKE_INSTALL_PREFIX=${SOFT_DIR}-gcc-${GCC_VERSION}
# make -j 2
make clean
export NUM_CORES=1
export USE_OPENMP=1
make TARGET=NEHALEM
make install PREFIX=${SOFT_DIR}-gcc-${GCC_VERSION}
echo "Creating the modules file directory ${LIBRARIES_MODULES}"
mkdir -p ${LIBRARIES_MODULES}/${NAME}
(
cat <<MODULE_FILE
#%Module1.0
## $NAME modulefile
##
proc ModulesHelp { } {
    puts stderr "       This module does nothing but alert the user"
    puts stderr "       that the [module-info name] module is not available"
}

module-whatis   "$NAME $VERSION : See https://github.com/SouthAfricaDigitalScience/openblas-deploy"
setenv OPENBLAS_VERSION       $VERSION
setenv OPENBLAS_DIR           $::env(CVMFS_DIR)/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION-gcc-$GCC_VERSION
prepend-path LD_LIBRARY_PATH   $::env(OPENBLAS_DIR)/lib
prepend-path CFLAGS           "-I$::env(OPENBLAS_DIR)/include"
prepend-path CPPFLAGS           "-I$::env(OPENBLAS_DIR)/include"
prepend-path LDFLAGS          "-I$::env(OPENBLAS_DIR)/lib"
MODULE_FILE
) > ${LIBRARIES_MODULES}/${NAME}/${VERSION}-gcc-${GCC_VERSION}
module  avail ${NAME}
module  add ${NAME}/${VERSION}
