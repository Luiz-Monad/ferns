
status("")
status("  I/O: ")

if(NOT HAVE_ZLIB)
  status("    ZLib:" NO)
else()
  status("    ZLib:" "${ZLIB_LIBRARY} (ver ${ZLIB_VERSION_STRING})")
endif()

if(NOT HAVE_OpenCV)
  status("    OpenCV:" NO)
else()
  status("    OpenCV:" "${OpenCV_DIR} (ver ${OpenCV_VERSION})")
endif()
