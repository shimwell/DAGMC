message("")

# Find MOAB cmake config file
# Only used to determine the location of the HDF5 with which MOAB was built
set(MOAB_SEARCH_DIRS)
file(GLOB MOAB_SEARCH_DIRS ${MOAB_SEARCH_DIRS} "${MOAB_DIR}/lib*/cmake/MOAB")
string(REPLACE "\n" ";" MOAB_SEARCH_DIRS "${MOAB_SEARCH_DIRS}")
find_path(MOAB_CMAKE_CONFIG
  NAMES MOABConfig.cmake
  PATHS ${MOAB_SEARCH_DIRS}
  NO_DEFAULT_PATH
)
if (MOAB_CMAKE_CONFIG)
  set(MOAB_CMAKE_CONFIG ${MOAB_CMAKE_CONFIG}/MOABConfig.cmake)
  message(STATUS "MOAB_CMAKE_CONFIG: ${MOAB_CMAKE_CONFIG}")
  include(${MOAB_CMAKE_CONFIG})
elseif (DDL_INSTALL_DEPS)
  message(STATUS "MOAB will be downloaded and built")
  include(ExternalProject)
  # Configure MOAB
  if(NOT MOAB_VERSION)
    set(MOAB_VERSION "5.5.1")
  endif()
  set(CMAKE_INSTALL_LIBDIR "lib")
  SET(MOAB_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/moab")
  set(MOAB_ROOT "${CMAKE_BINARY_DIR}/moab")
  set(MOAB_INCLUDE_DIRS "${MOAB_INSTALL_PREFIX}/include")
  set(MOAB_LIBRARY_DIRS "${MOAB_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
  set(MOAB_LIBRARIES_SHARED "")
  ExternalProject_Add(MOAB_ep
    PREFIX ${MOAB_ROOT}   
    GIT_REPOSITORY https://bitbucket.org/fathomteam/moab.git
    GIT_TAG ${MOAB_VERSION}
    CMAKE_ARGS
      -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
      -DBUILD_SHARED_LIBS:BOOL=ON
      -DENABLE_HDF5:BOOL=ON
      -DHDF5_ROOT:PATH=${HDF5_ROOT}
      -DEIGEN3_DIR:PATH=${EIGEN3_INCLUDE_DIRS}
      -DENABLE_BLASLAPACK:BOOL=OFF
      -DENABLE_FORTRAN:BOOL=OFF
      -DCMAKE_MACOSX_RPATH:BOOL=ON
    DOWNLOAD_EXTRACT_TIMESTAMP true
    BUILD_BYPRODUCTS "${MOAB_LIBRARY_DIRS}/*${CMAKE_SHARED_LIBRARY_SUFFIX}*"
    # Set devel space as install prefix
    INSTALL_DIR "${MOAB_INSTALL_PREFIX}"
  )
  add_library(MOAB INTERFACE)
  # list(APPEND CMAKE_MODULE_PATH ${MOAB_LIBRARY_DIRS}/cmake)
  message(STATUS "CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}") 
  message(STATUS "MOAB_LIBRARY_DIRS=${MOAB_LIBRARY_DIRS}") 
  message(STATUS "MOAB_LIBRARY_DIRS=${MOAB_LIBRARY_DIRS}")
  target_include_directories(MOAB SYSTEM INTERFACE ${MOAB_INCLUDE_DIRS})
  target_link_libraries(MOAB INTERFACE ${MOAB_INSTALL_PREFIX}/lib64/libMOAB.so)
  add_dependencies(MOAB MOAB_ep)
  install(TARGETS MOAB LIBRARY DESTINATION ${MOAB_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}
                      PUBLIC_HEADER DESTINATION ${INSTALL_INCLUDE_DIR})

  include_directories(${MOAB_INCLUDE_DIRS})
  link_directories(${MOAB_LIBRARY_DIRS})
  include_directories(${EIGEN3_INCLUDE_DIRS})
else ()
  message(FATAL_ERROR "Could not find MOAB. Set -DMOAB_DIR=<MOAB_DIR> when running cmake or use the $MOAB_DIR environment variable.")
endif ()

# Find HDF5
set(ENV{PATH} "${HDF5_DIR}:$ENV{PATH}")
set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_SHARED_LIBRARY_SUFFIX})
find_package(HDF5 REQUIRED)
# Remove HDF5 transitive dependencies that are system libraries
list(FILTER HDF5_LIBRARIES EXCLUDE REGEX ".*lib(pthread|dl|m).*")
set(HDF5_LIBRARIES_SHARED ${HDF5_LIBRARIES})
# CMake doesn't let you find_package(HDF5) twice so we have to do this instead
if (BUILD_STATIC_LIBS)
  string(REPLACE ${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_STATIC_LIBRARY_SUFFIX}
         HDF5_LIBRARIES_STATIC "${HDF5_LIBRARIES_SHARED}")
endif ()
if (NOT BUILD_SHARED_LIBS)
  set(HDF5_LIBRARIES_SHARED)
endif ()
set(HDF5_LIBRARIES)

message(STATUS "HDF5_INCLUDE_DIRS: ${HDF5_INCLUDE_DIRS}")
message(STATUS "HDF5_LIBRARIES_SHARED: ${HDF5_LIBRARIES_SHARED}")
message(STATUS "HDF5_LIBRARIES_STATIC: ${HDF5_LIBRARIES_STATIC}")

include_directories(${HDF5_INCLUDE_DIRS})
if(MSVC)
    set(BUILD_STATIC_LIBS TRUE)
    set(BUILD_SHARED_LIBS OFF)
endif()
# Find MOAB library (shared)
if (BUILD_SHARED_LIBS)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_SHARED_LIBRARY_SUFFIX})
  find_library(MOAB_LIBRARIES_SHARED
    NAMES MOAB
    HINTS ${MOAB_LIBRARY_DIRS}
    NO_DEFAULT_PATH
  )
  list(APPEND MOAB_LIBRARIES_SHARED)
endif ()

# Find MOAB library (static)
if (BUILD_STATIC_LIBS)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_STATIC_LIBRARY_SUFFIX})
  find_library(MOAB_LIBRARIES_STATIC
    NAMES MOAB
    HINTS ${MOAB_LIBRARY_DIRS}
    NO_DEFAULT_PATH
  )
  list(APPEND MOAB_LIBRARIES_STATIC)
endif ()

message(STATUS "MOAB_INCLUDE_DIRS: ${MOAB_INCLUDE_DIRS}")
message(STATUS "MOAB_LIBRARY_DIRS: ${MOAB_LIBRARY_DIRS}")
message(STATUS "MOAB_LIBRARIES_SHARED: ${MOAB_LIBRARIES_SHARED}")
message(STATUS "MOAB_LIBRARIES_STATIC: ${MOAB_LIBRARIES_STATIC}")

if (MOAB_INCLUDE_DIRS AND (MOAB_LIBRARIES_SHARED OR NOT BUILD_SHARED_LIBS) AND
    (MOAB_LIBRARIES_STATIC OR NOT BUILD_STATIC_LIBS))
  message(STATUS "Found MOAB")
else()
  # message(FATAL_ERROR "Could not find MOAB")
endif ()

include_directories(${MOAB_INCLUDE_DIRS})
