
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
list(APPEND TGT_PUB_INC ${pub_hdrs_dir})

source_group("Src" FILES ${main_srcs})
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

string(TOLOWER ${TGT} LTGT)

target_include_directories(
  ${TGT} PRIVATE
  ${TGT_INC})

target_include_directories(
  ${TGT} PUBLIC
  $<BUILD_INTERFACE:${TGT_PUB_INC}>
  $<INSTALL_INTERFACE:include/${LTGT}>)

target_compile_features(
  ${TGT} PRIVATE
  cxx_std_11)

target_link_libraries(
  ${TGT} PRIVATE
  ${TGT_LIB}
)

# ----------------------------------------------------------------------------
# CMake Installation.
# ----------------------------------------------------------------------------

set_target_properties(${TGT} PROPERTIES EXPORT_NAME ${LTGT})

include(GNUInstallDirs)
set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_LIBDIR}/cmake/${TGT})

# Deploy the binary targets.
install(
  TARGETS ${TGT}
  EXPORT ${TGT}-targets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# Deploy the includes.
install(
  FILES ${pub_hdrs}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Deploy the targets to a script.
install(
  EXPORT ${TGT}-targets
  FILE ${TGT}Targets.cmake
  NAMESPACE ${TGT}::
  DESTINATION ${INSTALL_CONFIGDIR}
)

# Deploy ConfigVersion.cmake file.
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/${TGT}ConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY AnyNewerVersion
)
install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/${TGT}ConfigVersion.cmake
  DESTINATION ${INSTALL_CONFIGDIR}
)

# Deploy Config.cmake file.
configure_package_config_file(
  ${FRN_ROOT_DIR}/cmake/templates/${TGT}Config.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/${TGT}Config.cmake
  INSTALL_DESTINATION ${INSTALL_CONFIGDIR}
)
install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/${TGT}Config.cmake
  DESTINATION ${INSTALL_CONFIGDIR}
)

# Now export the target itself.
export(
  EXPORT ${TGT}-targets
  FILE ${CMAKE_CURRENT_BINARY_DIR}/${TGT}Targets.cmake
  NAMESPACE ${TGT}::
)

# Register package in the User Package Registry
export(PACKAGE ${TGT})
