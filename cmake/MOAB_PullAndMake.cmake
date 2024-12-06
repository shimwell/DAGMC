# this Macro sets up the download and build of MOAB using ExternalProject
# few tweak are done in src/dagmc/CMakeLists.txt and src/PyNE/CMakelists.txt 
# to make sure that MOAB is built before DAGMC.
MACRO (moab_pull_make moab_version)
    message(STATUS "MOAB will be downloaded and built")
    include(ExternalProject)
    message("HDF5_ROOT: ${HDF5_ROOT}")
    SET(MOAB_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/moab")
    set(MOAB_ROOT "${CMAKE_BINARY_DIR}/moab")
    set(MOAB_INCLUDE_DIRS "${MOAB_INSTALL_PREFIX}/include")
    set(MOAB_LIBRARY_DIRS "${MOAB_INSTALL_PREFIX}/lib")
    message("MOAB_LIBRARY_DIRS: ${MOAB_LIBRARY_DIRS}")
    MEsSAGE("CMAKE_SHARED_LIBRARY_SUFFIX: ${CMAKE_SHARED_LIBRARY_SUFFIX}")
    set(MOAB_LIBRARIES_SHARED "")
    ExternalProject_Add(MOAB_ep
      PREFIX ${MOAB_ROOT}   
      GIT_REPOSITORY https://bitbucket.org/fathomteam/moab.git
      GIT_TAG ${moab_version}
      CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
        -DBUILD_SHARED_LIBS:BOOL=ON
        -DENABLE_HDF5:BOOL=ON
        -DHDF5_ROOT:PATH=${HDF5_ROOT}
        -DCMAKE_INSTALL_RPATH=${HDF5_ROOT}/lib:${MOAB_INSTALL_PREFIX}/lib
        -DENABLE_BLASLAPACK:BOOL=OFF
        -DENABLE_FORTRAN:BOOL=OFF
        -DENABLE_PYMOAB:BOOL=OFF 
      DOWNLOAD_EXTRACT_TIMESTAMP true
      BUILD_BYPRODUCTS "${MOAB_LIBRARY_DIRS}/*${CMAKE_SHARED_LIBRARY_SUFFIX}*"
      INSTALL_DIR "${MOAB_INSTALL_PREFIX}"
    )
    # Setup a interface library for MOAB based on ExternalProoject MOAB_EP
    add_library(MOAB INTERFACE)

    target_include_directories(MOAB SYSTEM INTERFACE ${MOAB_INCLUDE_DIRS})
    target_link_libraries(MOAB INTERFACE ${MOAB_LIBRARY_DIRS}/libMOAB${CMAKE_SHARED_LIBRARY_SUFFIX})
    add_dependencies(MOAB MOAB_ep)
    install(TARGETS MOAB LIBRARY DESTINATION ${MOAB_LIBRARY_DIRS}
                        PUBLIC_HEADER DESTINATION ${INSTALL_INCLUDE_DIR})
    include_directories(${MOAB_INCLUDE_DIRS})
    link_directories(${MOAB_LIBRARY_DIRS})
    find_package(Eigen3 REQUIRED NO_MODULE)
    include_directories(${EIGEN3_INCLUDE_DIRS})

ENDMACRO(moab_pull_make)
