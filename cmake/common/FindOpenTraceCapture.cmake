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
  NAMES opentracecapture.h
  PATHS ${PC_OPENTRACECAPTURE_INCLUDE_DIRS}
  PATH_SUFFIXES opentracecapture
)

find_library(OpenTraceCapture_LIBRARY NAMES opentracecapture PATHS ${PC_OPENTRACECAPTURE_LIBRARY_DIRS})

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
