#!/bin/bash -e
. /etc/profile.d/modules.sh
module load ci
module add gcc/${GCC_VERSION}
cd ${WORKSPACE}/${NAME}-${VERSION}/
make test

echo $?

make install PREFIX=${SOFT_DIR}-gcc-${GCC_VERSION}
mkdir -p ${REPO_DIR}
mkdir -p modules
(
cat <<MODULE_FILE
#%Module1.0
## $NAME modulefile
##
proc ModulesHelp { } {
    puts stderr "       This module does nothing but alert the user"
    puts stderr "       that the [module-info name] module is not available"
}

module-whatis   "$NAME $VERSION."
setenv       OPENBLAS_VERSION       $VERSION
setenv       OPENBLAS_DIR           /apprepo/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION-gcc-$GCC_VERSION
prepend-path LD_LIBRARY_PATH   $::env(OPENBLAS_DIR)/lib
prepend-path LDFLAGS           "-L$::env(OPENBLAS_DIR)/lib"
prepend-path CFLAGS            "-I$::env(OPENBLAS_DIR)/include"
MODULE_FILE
) > modules/$VERSION

mkdir -p ${LIBRARIES_MODULES}/${NAME}
cp modules/$VERSION ${LIBRARIES_MODULES}/${NAME}/${VERSION}-gcc-${GCC_VERSION}
