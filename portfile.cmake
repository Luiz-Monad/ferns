cmake_policy(SET CMP0011 NEW) #Included scripts do automatic cmake_policy() PUSH and POP.
cmake_policy(SET CMP0057 NEW) #Support new if() IN_LIST operator.
cmake_policy(SET CMP0074 NEW) #find_package() uses <PackageName>_ROOT variables.
enable_language(CXX C)

include("$ENV{VCPKG_ROOT}/scripts/cmake/vcpkg_common_definitions.cmake")
include("$ENV{VCPKG_ROOT}/scripts/cmake/vcpkg_check_features.cmake")

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
  set(BUILD_SHARED_LIBS ON)
endif()
