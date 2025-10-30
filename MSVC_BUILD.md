# MSVC Windows Build Guide

This document describes how to build OpenTraceBroadcaster on Windows using Microsoft Visual C++ (MSVC) compiler.

## Overview

OpenTraceBroadcaster now supports MSVC builds on Windows, which is required for compatibility with OBS Studio. The previous GCC-based Windows builds had ABI incompatibility issues with OBS Studio's MSVC-compiled binaries.

## Prerequisites

### Required Software

1. **Visual Studio 2019 or later** (or Build Tools for Visual Studio)
   - Include C++ build tools
   - Windows 10/11 SDK
   
2. **CMake 3.28 or later**
   - Download from [cmake.org](https://cmake.org/download/)
   
3. **Ninja Build System**
   - Install via: `winget install Ninja-build.Ninja`
   - Or download from [ninja-build.org](https://ninja-build.org/)

4. **PowerShell 5.1 or later** (included with Windows)

### Dependencies

OpenTraceBroadcaster requires MSVC-built versions of its dependencies:

1. **libserialport** (MSVC build)
2. **OpenTraceCapture** (MSVC build)
3. **OBS Studio** (for plugin development)

## Building Dependencies

### Building libserialport with MSVC

```powershell
cd path/to/libserialport
.\build-msvc.ps1 -Configuration Release -Platform x64
```

This will create MSVC-built libserialport in `build-Release-x64/`.

### Building OpenTraceCapture with MSVC

```powershell
cd path/to/OpenTraceCapture
.\build-msvc.ps1 -BuildType release -Install
```

This will create MSVC-built OpenTraceCapture in `install-msvc/`.

## Building OpenTraceBroadcaster

### Method 1: Using the Build Script (Recommended)

```powershell
cd path/to/OpenTraceBroadcaster

# Basic build
.\build-msvc.ps1

# Build with custom dependency paths
.\build-msvc.ps1 -Configuration Release `
  -OpenTraceCaptureDir "C:\path\to\OpenTraceCapture\install-msvc" `
  -LibSerialPortDir "C:\path\to\libserialport\build-Release-x64"
```

### Method 2: Manual CMake Build

```powershell
# Setup MSVC environment
& "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

# Configure
cmake -S . -B build-msvc -G Ninja `
  -DCMAKE_BUILD_TYPE=Release `
  -DCMAKE_C_COMPILER=cl `
  -DCMAKE_CXX_COMPILER=cl `
  -DOpenTraceCapture_ROOT="C:\path\to\OpenTraceCapture\install-msvc" `
  -Dlibserialport_ROOT="C:\path\to\libserialport\build-Release-x64"

# Build
cmake --build build-msvc --config Release

# Install
cmake --install build-msvc --config Release
```

## Dependency Management

### Using Pre-built Dependencies

If you have pre-built MSVC dependencies, use the packaging script:

```powershell
.\package-dependencies.ps1 `
  -LibSerialPortArtifact "C:\path\to\libserialport-msvc" `
  -OpenTraceCaptureArtifact "C:\path\to\opentracecapture-msvc" `
  -OutputDir "dependencies-msvc"
```

This creates a structured dependency package that CMake can automatically find.

### CI/CD Integration

The GitHub Actions workflow automatically:

1. Sets up MSVC environment using `ilammy/msvc-dev-cmd`
2. Downloads or builds MSVC dependencies
3. Builds OpenTraceBroadcaster with proper linking
4. Packages the plugin for distribution

## Troubleshooting

### Common Issues

1. **"OpenTraceCapture not found"**
   - Ensure OpenTraceCapture is built with MSVC
   - Check that `OpenTraceCapture_ROOT` points to the install directory
   - Verify that both `.lib` and `.dll` files are present

2. **"libserialport not found"**
   - Build libserialport using the provided MSVC project files
   - Ensure the build output directory is correctly specified

3. **ABI compatibility errors**
   - Verify all dependencies are built with the same MSVC version
   - Check that no GCC/MinGW libraries are being linked

4. **Missing DLLs at runtime**
   - The build system automatically copies required DLLs
   - Ensure dependency DLLs are in the same directory as the plugin

### Debug Build Issues

For debug builds, ensure all dependencies are also built in debug mode to avoid runtime library conflicts.

## File Structure

After a successful build, you should have:

```
build-msvc/
├── obs-measurement-overlay.dll    # Main plugin
├── obs-measurement-overlay.pdb    # Debug symbols
├── opentracecapture.dll          # Dependency DLL
└── libserialport.dll             # Dependency DLL (if used)

install-msvc/
└── obs-measurement-overlay/
    ├── bin/64bit/
    │   ├── obs-measurement-overlay.dll
    │   ├── obs-measurement-overlay.pdb
    │   ├── opentracecapture.dll
    │   └── libserialport.dll
    └── data/                     # Plugin resources
```

## Integration with OBS Studio

1. Copy the plugin directory to OBS Studio's plugin folder:
   ```
   %ProgramFiles%\obs-studio\obs-plugins\64bit\
   ```

2. Or use the development rundir for testing:
   ```
   build-msvc\rundir\Release\
   ```

## Performance Considerations

- Release builds are significantly faster than Debug builds
- Use `/MP` flag for parallel compilation (automatically enabled)
- Link-time optimization is enabled for Release builds

## Contributing

When contributing Windows-specific changes:

1. Test with both Debug and Release configurations
2. Ensure MSVC compatibility is maintained
3. Update this documentation for any new requirements
4. Test with the latest Visual Studio version

## Support

For MSVC build issues:

1. Check the [GitHub Issues](https://github.com/OpenTraceLab/OpenTraceBroadcaster/issues)
2. Verify your Visual Studio installation
3. Ensure all dependencies are MSVC-built
4. Check the CI logs for reference configurations
