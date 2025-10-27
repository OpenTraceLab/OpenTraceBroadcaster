# FindOpenTraceCapture.cmake - Find OpenTraceCapture library
#
# This module defines:
#  OpenTraceCapture_FOUND - True if OpenTraceCapture is found
#  OpenTraceCapture_INCLUDE_DIRS - Include directories for OpenTraceCapture
#  OpenTraceCapture_LIBRARIES - Libraries to link against
#  OpenTraceCapture::OpenTraceCapture - Imported target

find_package(PkgConfig QUIET)

if(PKG_CONFIG_FOUND)
  pkg_check_modules(PC_OPENTRACECAPTURE QUIET opentracecapture)
endif()

find_path(
  OpenTraceCapture_INCLUDE_DIR
  NAMES opentracecapture/opentracecapture.h
  PATHS 
    ${PC_OPENTRACECAPTURE_INCLUDE_DIRS} 
    "C:/Program Files/include"
    "/usr/local/include"
)

find_library(
  OpenTraceCapture_LIBRARY 
  NAMES opentracecapture libopentracecapture libopentracecapture.dll.a
  PATHS 
    ${PC_OPENTRACECAPTURE_LIBRARY_DIRS} 
    "C:/Program Files/lib"
    "C:/Program Files/bin"
    "/usr/local/lib"
    "/usr/local/lib/x86_64-linux-gnu"
)

# Debug output
if(WIN32)
  message(STATUS "OpenTraceCapture search paths: C:/Program Files/lib;C:/Program Files/bin")
  file(GLOB LIB_FILES "C:/Program Files/lib/*opentrace*")
  message(STATUS "Found files in C:/Program Files/lib: ${LIB_FILES}")
  file(GLOB BIN_FILES "C:/Program Files/bin/*opentrace*")  
  message(STATUS "Found files in C:/Program Files/bin: ${BIN_FILES}")
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  OpenTraceCapture
  REQUIRED_VARS OpenTraceCapture_LIBRARY OpenTraceCapture_INCLUDE_DIR
  VERSION_VAR PC_OPENTRACECAPTURE_VERSION
)

if(OpenTraceCapture_FOUND)
  set(OpenTraceCapture_LIBRARIES ${OpenTraceCapture_LIBRARY})
  set(OpenTraceCapture_INCLUDE_DIRS ${OpenTraceCapture_INCLUDE_DIR})

  if(NOT TARGET OpenTraceCapture::OpenTraceCapture)
    add_library(OpenTraceCapture::OpenTraceCapture UNKNOWN IMPORTED)
    set_target_properties(
      OpenTraceCapture::OpenTraceCapture
      PROPERTIES
        IMPORTED_LOCATION "${OpenTraceCapture_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${OpenTraceCapture_INCLUDE_DIR}"
    )
  endif()
endif()

mark_as_advanced(OpenTraceCapture_INCLUDE_DIR OpenTraceCapture_LIBRARY)
