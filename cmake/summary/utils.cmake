# This file is derived work from part of the OpenCV project.
# It is subject to the license terms in the LICENSE file found in the top-level directory
# of this distribution and at http://opencv.org/license.html.

if(COMMAND qvr_cmake_dump_vars)  # include guard
  return()
endif()

include(CMakeParseArguments)


# Debugging function
function(qvr_cmake_dump_vars)
  set(QVR_SUPPRESS_DEPRECATIONS 1)  # suppress deprecation warnings from variable_watch() guards
  get_cmake_property(__variableNames VARIABLES)
  cmake_parse_arguments(DUMP "" "TOFILE" "" ${ARGN})
  set(regex "${DUMP_UNPARSED_ARGUMENTS}")
  string(TOLOWER "${regex}" regex_lower)
  set(__VARS "")
  foreach(__variableName ${__variableNames})
    string(TOLOWER "${__variableName}" __variableName_lower)
    if((__variableName MATCHES "${regex}" OR __variableName_lower MATCHES "${regex_lower}")
        AND NOT __variableName_lower MATCHES "^__")
      get_property(__value VARIABLE PROPERTY "${__variableName}")
      set(__VARS "${__VARS}${__variableName}=${__value}\n")
    endif()
  endforeach()
  if(DUMP_TOFILE)
    file(WRITE ${CMAKE_BINARY_DIR}/${DUMP_TOFILE} "${__VARS}")
  else()
    message(AUTHOR_WARNING "${__VARS}")
  endif()
endfunction()


# Search packages for the host system instead of packages for the target system
# in case of cross compilation these macros should be defined by the toolchain file
if(NOT COMMAND find_host_package)
  macro(find_host_package)
    find_package(${ARGN})
  endmacro()
endif()
if(NOT COMMAND find_host_program)
  macro(find_host_program)
    find_program(${ARGN})
  endmacro()
endif()


set(QVR_BUILD_INFO_STR "" CACHE INTERNAL "")
function(qvr_output_status msg)
  message(STATUS "${msg}")
  string(REPLACE "\\" "\\\\" msg "${msg}")
  string(REPLACE "\"" "\\\"" msg "${msg}")
  string(REGEX REPLACE "^(\r*\n)+$" "" msg "${msg}")
  if(msg MATCHES "\r*\n")
    string(REPLACE "\r*\n" "\\n" msg "${msg}")
  endif()
  set(QVR_BUILD_INFO_STR "${QVR_BUILD_INFO_STR}\"${msg}\\n\"" CACHE INTERNAL "")
endfunction()


macro(qvr_finalize_status)
  set(QVR_BUILD_INFO_FILE "${CMAKE_BINARY_DIR}/version_string.tmp")
  if(EXISTS "${QVR_BUILD_INFO_FILE}")
    file(READ "${QVR_BUILD_INFO_FILE}" __content)
  else()
    set(__content "")
  endif()
  if("${__content}" STREQUAL "${QVR_BUILD_INFO_STR}")
    #message(STATUS "${QVR_BUILD_INFO_FILE} contains the same content")
  else()
    file(WRITE "${QVR_BUILD_INFO_FILE}" "${QVR_BUILD_INFO_STR}")
  endif()
  unset(__content)
  unset(QVR_BUILD_INFO_STR CACHE)

  if(NOT QVR_SKIP_STATUS_FINALIZATION)
    if(DEFINED QVR_MODULE_QVR_core_BINARY_DIR)
      execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different "${QVR_BUILD_INFO_FILE}" "${QVR_MODULE_QVR_core_BINARY_DIR}/version_string.inc" OUTPUT_QUIET)
    endif()
  endif()
endmacro()


# Status report function.
# Automatically align right column and selects text based on condition.
# Usage:
#   status(<text>)
#   status(<heading> <value1> [<value2> ...])
#   status(<heading> <condition> THEN <text for TRUE> ELSE <text for FALSE> )
function(status text)
  set(status_cond)
  set(status_then)
  set(status_else)

  set(status_current_name "cond")
  foreach(arg ${ARGN})
    if(arg STREQUAL "THEN")
      set(status_current_name "then")
    elseif(arg STREQUAL "ELSE")
      set(status_current_name "else")
    else()
      list(APPEND status_${status_current_name} ${arg})
    endif()
  endforeach()

  if(DEFINED status_cond)
    set(status_placeholder_length 32)
    string(RANDOM LENGTH ${status_placeholder_length} ALPHABET " " status_placeholder)
    string(LENGTH "${text}" status_text_length)
    if(status_text_length LESS status_placeholder_length)
      string(SUBSTRING "${text}${status_placeholder}" 0 ${status_placeholder_length} status_text)
    elseif(DEFINED status_then OR DEFINED status_else)
      qvr_output_status("${text}")
      set(status_text "${status_placeholder}")
    else()
      set(status_text "${text}")
    endif()

    if(DEFINED status_then OR DEFINED status_else)
      if(${status_cond})
        string(REPLACE ";" " " status_then "${status_then}")
        string(REGEX REPLACE "^[ \t]+" "" status_then "${status_then}")
        qvr_output_status("${status_text} ${status_then}")
      else()
        string(REPLACE ";" " " status_else "${status_else}")
        string(REGEX REPLACE "^[ \t]+" "" status_else "${status_else}")
        qvr_output_status("${status_text} ${status_else}")
      endif()
    else()
      string(REPLACE ";" " " status_cond "${status_cond}")
      string(REGEX REPLACE "^[ \t]+" "" status_cond "${status_cond}")
      qvr_output_status("${status_text} ${status_cond}")
    endif()
  else()
    qvr_output_status("${text}")
  endif()
endfunction()


macro(qvr_git_describe var_name path)
  if(GIT_FOUND)
    execute_process(COMMAND "${GIT_EXECUTABLE}" describe --tags --exact-match --dirty
      WORKING_DIRECTORY "${path}"
      OUTPUT_VARIABLE ${var_name}
      RESULT_VARIABLE GIT_RESULT
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT GIT_RESULT EQUAL 0)
      execute_process(COMMAND "${GIT_EXECUTABLE}" describe --tags --always --dirty --match "[0-9].[0-9].[0-9]*" --exclude "[^-]*-cvsdk"
        WORKING_DIRECTORY "${path}"
        OUTPUT_VARIABLE ${var_name}
        RESULT_VARIABLE GIT_RESULT
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      if(NOT GIT_RESULT EQUAL 0)  # --exclude is not supported by 'git'
        # match only tags with complete OpenCV versions (ignores -alpha/-beta/-rc suffixes)
        execute_process(COMMAND "${GIT_EXECUTABLE}" describe --tags --always --dirty --match "[0-9].[0-9]*[0-9]"
          WORKING_DIRECTORY "${path}"
          OUTPUT_VARIABLE ${var_name}
          RESULT_VARIABLE GIT_RESULT
          ERROR_QUIET
          OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if(NOT GIT_RESULT EQUAL 0)
          set(${var_name} "unknown")
        endif()
      endif()
    endif()
  else()
    set(${var_name} "unknown")
  endif()
endmacro()

