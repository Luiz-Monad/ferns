# ----------------------------------------------------------------------------
#  Root CMake file for Ferns
# ----------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.20)
cmake_policy(VERSION 3.20)

enable_language(CXX C)
project(Ferns VERSION "1.0.0" LANGUAGES CXX C)

set(QVR_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(QVR_BIN_DIR ${CMAKE_CURRENT_BINARY_DIR})

set(QVR_VERSION_FILE ${CMAKE_CURRENT_SOURCE_DIR}/src/general.h)
set(QVR_VERSION_ID FRN)

# ----------------------------------------------------------------------------
# Build options
# ----------------------------------------------------------------------------

option(BUILD_SHARED_LIBS "Build shared libraries (.dll/.so) instead of static ones (.lib/.a)" OFF)

# ----------------------------------------------------------------------------
# Other 3rd-party libraries/tools
# ----------------------------------------------------------------------------

include(cmake/find_lib_thirdy.cmake)

# ----------------------------------------------------------------------------
# Features
# ----------------------------------------------------------------------------

include(portfile.cmake)

# ----------------------------------------------------------------------------
# Solution folders:
# ----------------------------------------------------------------------------

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set_property(GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER "CMakeTargets")

# ----------------------------------------------------------------------------
# Process subdirectories
# ----------------------------------------------------------------------------

add_subdirectory(src)

# ----------------------------------------------------------------------------
# Summary:
# ----------------------------------------------------------------------------

include(cmake/summary/dashboard.cmake)
