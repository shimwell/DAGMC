#!/bin/bash

set -ex

source ${docker_env}

rm -rf ${moab_build_dir}/bld ${moab_install_dir}
mkdir -p ${moab_build_dir}/bld
cd ${moab_build_dir}
git clone --depth 1 https://bitbucket.org/fathomteam/moab -b ${branch}
cd bld
cmake ../moab -DENABLE_HDF5=ON -DHDF5_ROOT=${hdf5_install_dir} \
              -DENABLE_BLASLAPACK=OFF \
              -DENABLE_FORTRAN=OFF \
              -DCMAKE_INSTALL_PREFIX=${moab_install_dir} \
              -DCMAKE_C_COMPILER=${CC} \
              -DCMAKE_CXX_COMPILER=${CXX} \
              -DBUILD_SHARED_LIBS=OFF
make -j${ci_jobs}
make install
rm -rf *
cmake ../moab -DENABLE_HDF5=ON -DHDF5_ROOT=${hdf5_install_dir} \
              -DENABLE_PYMOAB=ON \
              -DENABLE_BLASLAPACK=OFF \
              -DENABLE_FORTRAN=OFF \
              -DCMAKE_INSTALL_PREFIX=${moab_install_dir} \
              -DCMAKE_C_COMPILER=${CC} \
              -DCMAKE_CXX_COMPILER=${CXX} \
              -DBUILD_SHARED_LIBS=ON \
              -DCMAKE_INSTALL_RPATH=${hdf5_install_dir}/lib:${moab_install_dir}/lib
make -j${ci_jobs}
make install
cd
rm -rf ${moab_build_dir}
