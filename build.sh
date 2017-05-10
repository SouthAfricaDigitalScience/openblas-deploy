#!/bin/bash -e
# OpenBLAS depoy scripts
. /etc/profile.d/modules.sh
module add ci
module add gcc/${GCC_VERSION}
SOURCE_FILE=${NAME}-${VERSION}.tar.gz

mkdir -p $WORKSPACE
mkdir -p $SRC_DIR
mkdir -p $SOFT_DIR

#  Download the source file

if [ ! -e ${SRC_DIR}/${SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${SOURCE_FILE}.lock
  echo "seems like this is the first build - let's get the source"
  # they have a wierd naming scheme so we're just going to keep this hardcoded here.
  wget http://downloads.sourceforge.net/project/openblas/v0.2.15/OpenBLAS%200.2.15%20version.tar.gz -O $SRC_DIR/$SOURCE_FILE
  echo "releasing lock"
  rm -v ${SRC_DIR}/${SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${SOURCE_FILE}
fi
mkdir -p ${WORKSPACE}/${NAME}-${VERSION}
tar xzf  ${SRC_DIR}/${SOURCE_FILE} -C ${WORKSPACE}/${NAME}-${VERSION} --skip-old-files --strip-components=1
cd ${WORKSPACE}/${NAME}-${VERSION}
# the makefile doesn't have an install option, so we need to use the special in-source makefile
# CMake apparently is experimental :-/
# cmake . \
# -G"Unix Makefiles" \
# -DCMAKE_INSTALL_PREFIX=${SOFT_DIR}-gcc-${GCC_VERSION} \
# -DUSE_OPENMP=1 \
# -DNUM_CORES=2
echo "making clean"

make clean
export NUM_CORES=1
export USE_OPENMP=1
export NO_PARALLEL_MAKE=1
make TARGET=NEHALEM
