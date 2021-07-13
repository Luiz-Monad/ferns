
# ----------------------------------------------------------------------------

function(qvr_install_target TGT)
  set(__args PUB_INC LIB)
  cmake_parse_arguments("TGT" "" "" "${__args}" ${ARGN})

  string(TOLOWER ${TGT} __LTGT)
  set_target_properties(${TGT} PROPERTIES EXPORT_NAME ${__LTGT})

  include(GNUInstallDirs)
  set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_DATAROOTDIR}/${TGT})

  foreach(__dep ${TGT_LIB})
    get_target_property(__dep_file ${__dep} QVR_TGT_FILE)
    list(APPEND __libs ${__dep_file})
    get_target_property(__dep_file ${__dep} QVR_TGT_DEP)
    list(APPEND __deps ${__dep_file})
  endforeach()
  set(TGT_LIB ${__libs})
  set(TGT_DEP ${__deps})

  # Deploy the binary targets.
  install(
    TARGETS ${TGT}
    EXPORT ${TGT}-targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

  # Deploy the public includes.
  install(
    FILES ${TGT_PUB_INC}
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
    ${QVR_ROOT_DIR}/cmake/templates/TargetConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/${TGT}Config.cmake
    INSTALL_DESTINATION ${INSTALL_CONFIGDIR}
  )
  install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/${TGT}Config.cmake
    DESTINATION ${INSTALL_CONFIGDIR}
  )

  # Now export the target itself (cpack).
  export(
    EXPORT ${TGT}-targets
    FILE ${CMAKE_CURRENT_BINARY_DIR}/${TGT}Targets.cmake
    NAMESPACE ${TGT}::
  )

  # Register package (cpack).
  export(PACKAGE ${TGT})

endfunction()

# ----------------------------------------------------------------------------

function(qvr_install_dependency TGT)
  set(__args NS FILE)
  cmake_parse_arguments("TGT" "" "${__args}" "" ${ARGN})

  string(TOLOWER ${TGT} __LTGT)
  set(TGT_FILE ${TGT_NS}${TGT_FILE}Targets.cmake)

  include(GNUInstallDirs)
  set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_DATAROOTDIR}/${TGT_NS})

  get_filename_component(TGT_DEP ${CMAKE_CURRENT_LIST_FILE} NAME)

  # Create the virtual target.
  add_library(${TGT} INTERFACE)
  set_target_properties(
    ${TGT} PROPERTIES
    QVR_TGT_FILE ${TGT_FILE}
    QVR_TGT_DEP ${TGT_DEP}
  )

  # Deploy the virtual target.
  install(
    TARGETS ${TGT}
    EXPORT ${TGT}-targets
  )

  # Deploy the targets to a script.
  install(
    EXPORT ${TGT}-targets
    FILE ${TGT_FILE}
    NAMESPACE ${TGT}::
    DESTINATION ${INSTALL_CONFIGDIR}
  )

  # Deploy ourselves.
  install(
    FILES ${CMAKE_CURRENT_LIST_FILE}
    DESTINATION ${INSTALL_CONFIGDIR}
  )

  # Now export the target itself (for cpack).
  export(
    EXPORT ${TGT}-targets
    FILE ${CMAKE_CURRENT_BINARY_DIR}/${TGT_NS}/${TGT_FILE}
    NAMESPACE ${TGT}::
  )

endfunction()

# ----------------------------------------------------------------------------
