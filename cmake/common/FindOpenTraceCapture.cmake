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

# Look for headers
find_path(
  OpenTraceCapture_INCLUDE_DIR
  NAMES opentracecapture/opentracecapture.h
  PATHS 
    ${PC_OPENTRACECAPTURE_INCLUDE_DIRS}
    "${CMAKE_CURRENT_SOURCE_DIR}/deps/opentracecapture/include"
    "C:/opentracecapture/include"
    "/usr/local/include"
    "/opt/homebrew/include"
)
)

# Look for libraries
if(WIN32 AND MSVC)
  find_library(
    OpenTraceCapture_LIBRARY 
    NAMES opentracecapture libopentracecapture
    PATHS 
      ${PC_OPENTRACECAPTURE_LIBRARY_DIRS}
      "${CMAKE_CURRENT_SOURCE_DIR}/deps/opentracecapture/lib"
      "C:/opentracecapture/lib"
  )
  
  find_file(
    OpenTraceCapture_DLL
    NAMES opentracecapture.dll libopentracecapture.dll
    PATHS
      "${CMAKE_CURRENT_SOURCE_DIR}/deps/opentracecapture/bin"
      "C:/opentracecapture/bin"
  )
else()
  # Non-Windows or non-MSVC library search
  find_library(
    OpenTraceCapture_LIBRARY 
    NAMES opentracecapture libopentracecapture libopentracecapture.dll.a
    PATHS 
      ${PC_OPENTRACECAPTURE_LIBRARY_DIRS} 
      "/usr/local/lib"
      "/usr/local/lib/x86_64-linux-gnu"
      "/opt/homebrew/lib"
  )
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
    if(WIN32 AND MSVC)
      # Create imported target for MSVC
      add_library(OpenTraceCapture::OpenTraceCapture SHARED IMPORTED)
      set_target_properties(
        OpenTraceCapture::OpenTraceCapture
        PROPERTIES
          IMPORTED_LOCATION "${OpenTraceCapture_DLL}"
          IMPORTED_IMPLIB "${OpenTraceCapture_LIBRARY}"
          INTERFACE_INCLUDE_DIRECTORIES "${OpenTraceCapture_INCLUDE_DIR}"
      )
      
      # Add Windows-specific link libraries
      set_property(TARGET OpenTraceCapture::OpenTraceCapture 
        PROPERTY INTERFACE_LINK_LIBRARIES ws2_32 setupapi)
    else()
      # Create imported target for other platforms
      add_library(OpenTraceCapture::OpenTraceCapture UNKNOWN IMPORTED)
      set_target_properties(
        OpenTraceCapture::OpenTraceCapture
        PROPERTIES
          IMPORTED_LOCATION "${OpenTraceCapture_LIBRARY}"
          INTERFACE_INCLUDE_DIRECTORIES "${OpenTraceCapture_INCLUDE_DIR}"
      )
    endif()
  endif()
endif()

mark_as_advanced(OpenTraceCapture_INCLUDE_DIR OpenTraceCapture_LIBRARY OpenTraceCapture_DLL)
