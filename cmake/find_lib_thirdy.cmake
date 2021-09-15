# ----------------------------------------------------------------------------
#  Target
# ----------------------------------------------------------------------------

set(_TGT frns.3rdparty)
set(_TGT_NS Ferns)

include(cmake/targets.cmake)
qvr_target_create(${_TGT} NS ${_TGT_NS})

# ----------------------------------------------------------------------------
#  Detect 3rd-party libraries (VCPKG)
# ----------------------------------------------------------------------------

# --- zlib (required) ---
find_package(ZLIB REQUIRED)
if(ZLIB_FOUND)
  if(ANDROID AND ZLIB_LIBRARIES MATCHES "/usr/(lib|lib32|lib64)/libz.so$")
    set(ZLIB_LIBRARIES z)
  endif()
  set(HAVE_ZLIB YES)
  qvr_target_link_libraries(${_TGT} INTERFACE ZLIB::ZLIB)
endif()

# --- opencv (required) ---
find_package(LocalOpenCV REQUIRED)
if(OpenCV_FOUND)
  set(HAVE_OpenCV YES)
  qvr_target_link_libraries(${_TGT} INTERFACE OpenCV::opencv)
endif()
