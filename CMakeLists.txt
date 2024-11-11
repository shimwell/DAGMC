project(DAGMC)
cmake_minimum_required(VERSION 3.16 FATAL_ERROR)
enable_language(CXX)

# Set DAGMC version
set(DAGMC_MAJOR_VERSION 3)
set(DAGMC_MINOR_VERSION 2)
set(DAGMC_PATCH_VERSION 3)
set(DAGMC_VERSION ${DAGMC_MAJOR_VERSION}.${DAGMC_MINOR_VERSION}.${DAGMC_PATCH_VERSION})

if(MSVC)
  set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
endif()


# Set DAGMC Git SHA

# Set git SHA1 hash as a compile definition
find_package(Git)
if(GIT_FOUND AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
  execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    RESULT_VARIABLE DAGMC_GIT_SHA_SUCCESS
    OUTPUT_VARIABLE DAGMC_GIT_SHA
    ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
  if(NOT DAGMC_GIT_SHA_SUCCESS EQUAL "0")
    message(WARNING "Could not determine the commit SHA for DAGMC.")
    set(DAGMC_GIT_SHA "")
  endif()

  option(GIT_SUBMODULE "Check submodules during build" ON)
  if(GIT_SUBMODULE)
    message(STATUS "Submodule update")
    execute_process(COMMAND ${GIT_EXECUTABLE} "submodule" "update" "--init" "--recursive"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    RESULT_VARIABLE GIT_SUBMOD_RESULT)
    if(NOT GIT_SUBMOD_RESULT EQUAL 0)
      message(FATAL_ERROR "git submodule update --init --recursive failed with \
        ${GIT_SUBMOD_RESULT}, please checkout submodules")
    endif()
  endif()
endif()

# Check to see if submodules exist (by checking one)
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/pyne/pyne/readme.rst")
  message(FATAL_ERROR "The git submodules were not downloaded! GIT_SUBMODULE was \
    turned off or failed. Please update submodules and try again.")
endif()

# Make the scripts in the "cmake" directory available to CMake
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
include(DAGMC_macros)

dagmc_setup_build()

dagmc_setup_options()

if(BUILD_MCNP5 OR BUILD_MCNP6)
  enable_language(Fortran)
endif()

# find_package(MOAB REQUIRED)

if (NOT MOAB_FOUND)
  include(FetchContent)
  message(STATUS "MOAB not found. Fetching MOAB...")
  FetchContent_Declare(
    moab
    GIT_REPOSITORY https://bitbucket.org/fathomteam/moab.git
    GIT BRANCH master
    # GIT_TAG        5.5.1
  )
  FetchContent_MakeAvailable(moab)
  add_subdirectory(${moab_SOURCE_DIR} ${moab_BINARY_DIR}) # MOAB repository is not properly configured for a FetchContent build
  # Set MOAB_DIR to the fetched content
  set(MOAB_DIR ${moab_SOURCE_DIR})
  find_package(MOAB REQUIRED)
endif()

find_package(OpenMP)

dagmc_setup_flags()

if (BUILD_TESTS)
  enable_testing()
endif ()

add_subdirectory(src)

dagmc_make_configure_files()

message("")
