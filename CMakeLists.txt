cmake_minimum_required(VERSION 3.28...3.30)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/bootstrap.cmake" NO_POLICY_SCOPE)

project(${_name} VERSION ${_version})

option(ENABLE_FRONTEND_API "Use obs-frontend-api for UI functionality" OFF)
option(ENABLE_QT "Use Qt functionality" OFF)

include(compilerconfig)
include(defaults)
include(helpers)

add_library(${CMAKE_PROJECT_NAME} MODULE)

# On Windows with vcpkg, tell it to use system libobs (provided by OBS build system)
if(WIN32 AND DEFINED VCPKG_TOOLCHAIN)
  set(CMAKE_FIND_PACKAGE_PREFER_CONFIG FALSE)
endif()

find_package(libobs REQUIRED)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::libobs)

if(ENABLE_FRONTEND_API)
  find_package(obs-frontend-api REQUIRED)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::obs-frontend-api)
endif()

if(ENABLE_QT)
  find_package(Qt6 COMPONENTS Widgets Core)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::Core Qt6::Widgets)
  target_compile_options(
    ${CMAKE_PROJECT_NAME}
    PRIVATE $<$<C_COMPILER_ID:Clang,AppleClang>:-Wno-quoted-include-in-framework-header -Wno-comma>
  )
  set_target_properties(
    ${CMAKE_PROJECT_NAME}
    PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON
  )
endif()

# Find libopentracecapture dependency
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/common")

# Add src directory to include path for Windows compatibility headers
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

find_package(OpenTraceCapture REQUIRED)

# Find glib dependency (required by OpenTraceCapture on some platforms)
if(WIN32)
  # On Windows, glib is optional - try to find it but don't fail if missing
  find_package(PkgConfig QUIET)
  if(PkgConfig_FOUND)
    pkg_check_modules(GLIB QUIET glib-2.0)
  endif()
  
  if(NOT GLIB_FOUND)
    # Fallback: look in common Windows installation paths
    find_path(GLIB_INCLUDE_DIR glib.h 
      PATHS "C:/glib/include" "C:/Program Files/glib/include"
      PATH_SUFFIXES glib-2.0)
    find_library(GLIB_LIBRARY glib-2.0
      PATHS "C:/glib/lib" "C:/Program Files/glib/lib")
    
    if(GLIB_INCLUDE_DIR AND GLIB_LIBRARY)
      set(GLIB_FOUND TRUE)
      set(GLIB_INCLUDE_DIRS ${GLIB_INCLUDE_DIR})
      set(GLIB_LIBRARIES ${GLIB_LIBRARY})
    else()
      message(WARNING "glib not found on Windows - OpenTraceCapture may not work properly")
    endif()
  endif()
else()
  find_package(PkgConfig REQUIRED)
  # Add Homebrew paths for macOS
  if(APPLE)
    set(ENV{PKG_CONFIG_PATH} "/opt/homebrew/lib/pkgconfig:/usr/local/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
  endif()
  pkg_check_modules(GLIB REQUIRED glib-2.0)
endif()

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OpenTraceCapture::OpenTraceCapture)

if(GLIB_FOUND)
  target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${GLIB_INCLUDE_DIRS})
  target_link_directories(${CMAKE_PROJECT_NAME} PRIVATE ${GLIB_LIBRARY_DIRS})
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE ${GLIB_LIBRARIES})
endif()

target_sources(${CMAKE_PROJECT_NAME} PRIVATE src/plugin-main.cpp src/measurement-reader.cpp)

# CPack configuration for packaging
set(CPACK_PACKAGE_NAME "obs-measurement-overlay")
set(CPACK_PACKAGE_VERSION "0.1.0")
set(CPACK_PACKAGE_CONTACT "OpenTraceLab <noreply@opentracelab.com>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "OBS Studio plugin for measurement overlay")
set(CPACK_PACKAGE_DESCRIPTION "An OBS Studio plugin that displays real-time measurements from DMM and LCR meter devices as an overlay.")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "obs-studio, libglib2.0-0")
include(CPack)

set_target_properties_plugin(${CMAKE_PROJECT_NAME} PROPERTIES OUTPUT_NAME ${_name})
