
set(CD ${CMAKE_CURRENT_LIST_DIR})

# ----------------------------------------------------------------------------
# Thirdy party components.
# ----------------------------------------------------------------------------

if(TARGET frns.3rdparty)
  list(APPEND TGT_LIB frns.3rdparty)
endif()

# ----------------------------------------------------------------------------
# Main sources.
# ----------------------------------------------------------------------------

set(conf_hdrs_dir ${CD}/../include)
file(GLOB conf_hdrs ${conf_hdrs_dir}/*.h)
list(APPEND TGT_INC ${conf_hdrs_dir})

set(main_dir ${CD})
file(GLOB main_hdrs ${main_dir}/*.h)
file(GLOB main_srcs ${main_dir}/*.cpp)
list(APPEND TGT_INC ${main_dir})

set(pub_hdrs_dir ${CD})
file(GLOB pub_hdrs ${pub_hdrs_dir}/*.h)
list(APPEND TGT_PUB_INC ${pub_hdrs})
list(APPEND TGT_BUILD_INC ${pub_hdrs_dir})

source_group("Source" FILES ${main_srcs})
source_group("Include" FILES ${main_hdrs})
source_group("External Include" FILES ${conf_hdrs})
source_group("Public Include" FILES ${pub_hdrs})

# ----------------------------------------------------------------------------
# Main Target.
# ----------------------------------------------------------------------------

set(TGT Ferns)

add_library(
  ${TGT} STATIC
  ${pub_hdrs} ${conf_hdrs}
  ${main_srcs} ${main_hdrs}
)

target_include_directories(
  ${TGT} PRIVATE
  ${TGT_INC})

string(TOLOWER ${TGT} __LTGT)
target_include_directories(
  ${TGT} PUBLIC
  $<BUILD_INTERFACE:${TGT_BUILD_INC}>
  $<INSTALL_INTERFACE:include/${__LTGT}>)

target_compile_features(
  ${TGT} PRIVATE
  cxx_std_11)

target_link_libraries(
  ${TGT} PRIVATE
  ${TGT_LIB})

# ----------------------------------------------------------------------------
# Extra Target definitions.
# ----------------------------------------------------------------------------

#target_compile_definitions(${TGT} PRIVATE example)
#target_compile_definitions(${TGT} PUBLIC example)

# ----------------------------------------------------------------------------
# CMake Installation.
# ----------------------------------------------------------------------------

include(${QVR_ROOT_DIR}/cmake/targets.cmake)
qvr_install_target(
  ${TGT}
  PUB_INC ${TGT_PUB_INC}
  LIB ${TGT_LIB})
