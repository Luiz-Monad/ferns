# ----------------------------------------------------------------------------
#  Target
# ----------------------------------------------------------------------------

set(TGT frns.3rdparty)

add_library(${TGT} INTERFACE)

install(
  TARGETS ${TGT}
  EXPORT ${TGT}-targets
)

# Deploy the targets to a script.
include(GNUInstallDirs)
set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_LIBDIR}/cmake/${TGT})
install(
  EXPORT ${TGT}-targets
  FILE ${TGT}Targets.cmake
  NAMESPACE ${TGT}::
  DESTINATION ${INSTALL_CONFIGDIR}
)

# Now export the target itself.
export(
  EXPORT ${TGT}-targets
  FILE ${CMAKE_CURRENT_BINARY_DIR}/${TGT}/${TGT}Targets.cmake
  NAMESPACE ${TGT}::
)

# ----------------------------------------------------------------------------
#  Detect 3rd-party libraries
# ----------------------------------------------------------------------------

# Make all local VCPKG available
foreach(PREFIX ${CMAKE_PREFIX_PATH})
  list(APPEND CMAKE_MODULE_PATH ${PREFIX} ${PREFIX}/share)
endforeach()

# --- zlib (required) ---
find_package(ZLIB REQUIRED)
if(ZLIB_FOUND AND ANDROID)
  if(ZLIB_LIBRARIES MATCHES "/usr/(lib|lib32|lib64)/libz.so$")
    set(ZLIB_LIBRARIES z)
  endif()
  set(HAVE_ZLIB YES)
  target_link_libraries(${TGT} INTERFACE ZLIB::ZLIB)
endif()

# --- opencv (required) ---
find_package(LocalOpenCV REQUIRED)
if(OpenCV_FOUND)
  set(HAVE_OpenCV YES)
  target_link_libraries(${TGT} INTERFACE OpenCV::OpenCV)
endif()
