# ----------------------------------------------------------------------------
#  Target
# ----------------------------------------------------------------------------

set(TGT frns.3rdparty)
set(TGT_NS Ferns)
set(TGT_FILE 3rdparty)

if((NOT TARGET ${TGT}) AND (NOT TARGET ${TGT_NS}::${TGT}))

  include(cmake/targets.cmake)
  qvr_install_dependency(${TGT} NS ${TGT_NS} FILE ${TGT_FILE})

endif()

# ----------------------------------------------------------------------------
#  Detect 3rd-party libraries (VCPKG)
# ----------------------------------------------------------------------------

# Make all local VCPKG available
foreach(PREFIX ${CMAKE_PREFIX_PATH})
  list(APPEND CMAKE_MODULE_PATH ${PREFIX} ${PREFIX}/share)
endforeach()

# --- zlib (required) ---
find_package(ZLIB REQUIRED)
if(ZLIB_FOUND)
  if(ANDROID AND ZLIB_LIBRARIES MATCHES "/usr/(lib|lib32|lib64)/libz.so$")
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
