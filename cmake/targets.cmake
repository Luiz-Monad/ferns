
# ----------------------------------------------------------------------------

function(qvr_install_target _arg_TGT)
  set(__args PUB_INC LIB)
  cmake_parse_arguments("_arg" "" "" "${__args}" ${ARGN})

  # Consts.
  string(TOLOWER ${_arg_TGT} __name)
  set_target_properties(${_arg_TGT} PROPERTIES EXPORT_NAME ${__name})

  # Helpers.
  include(GNUInstallDirs)
  set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_DATAROOTDIR}/${_arg_TGT})

  # Extra file dependencies.
  foreach(__dep ${_arg_LIB})
    get_target_property(__val ${__dep} QVR_TGT_DEP)
    list(APPEND __deps ${__val})
  endforeach()

  # Extra config options to persist.
  foreach(__opt ${_arg_LIB})
    get_target_property(__val ${__opt} QVR_TGT_OPT)
    if(__val)
      list(APPEND __opts ${__val})
    endif()
  endforeach()

  # Deploy the binary targets to project targets.
  install(
    TARGETS ${_arg_TGT}
    EXPORT ${PROJECT_NAME}-targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

  # Deploy the public includes.
  install(
    FILES ${_arg_PUB_INC}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${_arg_TGT}
  )

  # Deploy the project targets to a script.
  install(
    EXPORT ${PROJECT_NAME}-targets
    FILE ${_arg_TGT}Targets.cmake
    NAMESPACE ${_arg_TGT}::
    DESTINATION ${INSTALL_CONFIGDIR}
  )

  # Deploy ConfigVersion.cmake file.
  include(CMakePackageConfigHelpers)
  write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${_arg_TGT}ConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
  )
  install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/${_arg_TGT}ConfigVersion.cmake
    DESTINATION ${INSTALL_CONFIGDIR}
  )

  # Deploy Config.cmake file.
  set(_TGT_NAME ${__name})
  set(_TGT_OPT ${__opts})
  set(_TGT_DEP ${__deps})
  set(_TGT_NS ${_arg_TGT})
  configure_package_config_file(
    ${QVR_ROOT_DIR}/cmake/templates/TargetConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/${_arg_TGT}Config.cmake
    INSTALL_DESTINATION ${INSTALL_CONFIGDIR}
  )
  install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/${_arg_TGT}Config.cmake
    DESTINATION ${INSTALL_CONFIGDIR}
  )

  # Now export the target itself (cpack).
  export(
    EXPORT ${PROJECT_NAME}-targets
    FILE ${CMAKE_CURRENT_BINARY_DIR}/${_arg_TGT}Targets.cmake
    NAMESPACE ${_arg_TGT}::
  )

  # Register package (cpack).
  export(PACKAGE ${_arg_TGT})

endfunction()

# ----------------------------------------------------------------------------

function(qvr_target_create _arg_TGT)
  set(__args NS)
  cmake_parse_arguments("_arg" "" "${__args}" "" ${ARGN})

  # Check if already created.
  if((TARGET ${_arg_TGT}) OR (TARGET ${_arg_NS}::${_arg_TGT}))
    return()
  endif()

  # Helpers.
  include(GNUInstallDirs)
  set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_DATAROOTDIR}/${_arg_NS})

  # Create the virtual target.
  add_library(${_arg_TGT} INTERFACE)

  # Add extra file dependencies to project config.
  get_filename_component(_dep ${CMAKE_CURRENT_LIST_FILE} NAME)
  set_target_properties(
    ${_arg_TGT} PROPERTIES QVR_TGT_DEP ${_dep}
  )

  # Deploy the virtual target to project targets.
  install(
    TARGETS ${_arg_TGT}
    EXPORT ${PROJECT_NAME}-targets
  )

  # Deploy our caller with its find_package calls.
  install(
    FILES ${CMAKE_CURRENT_LIST_FILE}
    DESTINATION ${INSTALL_CONFIGDIR}
  )

  # Make all local ports from VCPKG available.
  foreach(PREFIX ${CMAKE_PREFIX_PATH})
    list(APPEND CMAKE_MODULE_PATH ${PREFIX} ${PREFIX}/share)
  endforeach()
  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} PARENT_SCOPE)

endfunction()

# ----------------------------------------------------------------------------

function(qvr_target_option _arg_TGT _arg_OPTION)

  # Check the call guard for imported targets.
  get_filename_component(_name ${CMAKE_CURRENT_LIST_FILE} NAME)
  if(DEFINED ${_arg_TGT}_configuring OR DEFINED ${_name}_configuring)
    return()
  endif()

  # Continue.
  set_property(TARGET ${_arg_TGT} APPEND PROPERTY QVR_TGT_OPT ${_arg_OPTION})

endfunction()

# ----------------------------------------------------------------------------

function(qvr_target_link_libraries _arg_TGT)

  # Check the call guard for imported targets.
  get_filename_component(_name ${CMAKE_CURRENT_LIST_FILE} NAME)
  if(DEFINED ${_arg_TGT}_configuring OR DEFINED ${_name}_configuring)
    return()
  endif()

  # Continue.
  target_link_libraries(${_arg_TGT} ${ARGN})

endfunction()

# ----------------------------------------------------------------------------
