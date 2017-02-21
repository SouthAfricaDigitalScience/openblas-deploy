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
setenv       OPENBLAS_VERSION           $VERSION
setenv       OPENBLAS_DIR                        /data/ci-build/$::env(SITE)/$::env(OS)/$::env(ARCH)/$::env(NAME)/$::env(VERSION)-gcc-$::env(GCC_VERSION)
prepend-path LD_LIBRARY_PATH        $::env(OPENBLAS_DIR)/lib
prepend-path LDFLAGS                         "-L$::env(OPENBLAS_DIR)/lib -lopenblas"
prepend-path CFLAGS                           "-I$::env(OPENBLAS_DIR)/include"
prepend-path CPPFLAGS                     "-I$::env(OPENBLAS_DIR)/include"
MODULE_FILE
) > modules/$VERSION

mkdir -p ${LIBRARIES_MODULES}/${NAME}
cp modules/$VERSION ${LIBRARIES_MODULES}/${NAME}/${VERSION}-gcc-${GCC_VERSION}

# check module availability

module  avail ${NAME}

module add ${NAME}/${VERSION}-gcc-${GCC_VERSION}
echo "LD_LIBRARY_PATH is $LD_LIBRARY_PATH"
echo "Testing cblas"
# get the file
wget https://gist.githubusercontent.com/xianyi/6930656/raw/1b5868547a5277729d33dac62678a66ff65256f3/test_cblas_dgemm.c
# Compile it
echo "compiling with gcc. using gcc -o cblas-test -I${OPENBLAS_DIR}/include -L${OPENBLAS_DIR}/lib test_cblas_dgemm.c -lopenblas -lpthread -lgfortran"
gcc -o cblas-test -I${OPENBLAS_DIR}/include -L${OPENBLAS_DIR}/lib test_cblas_dgemm.c -lopenblas -lpthread -lgfortran
echo "executing !"
# EXECUTE !
#  APPARENTLY this returns SIGUSR1 if executed properly, so we need to catch that.
  (
  set +e
  ./cblas-test > test.out
  if [ "$?" -eq "10"  ] ; then
    echo "Everything is fine"
    exit 0;
  fi
  )
echo "Testing FORTRAN interface in c"
#  Get the file
wget https://gist.githubusercontent.com/xianyi/5780018/raw/c1d93058a2f61b88b9dd4237d2cf4a963065070b/time_dgemm.c
# compile it
gcc -o time_dgemm -fopenmp time_dgemm.c ${OPENBLAS_DIR}/lib/libopenblas.a
# execute it
time ./time_dgemm 1000 1000 1000s > time_dgemm.out > test.out
