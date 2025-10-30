#!/usr/bin/env pwsh
# Test script for MSVC Windows build validation

param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

if ($Verbose) {
    $VerbosePreference = "Continue"
}

Write-Host "=== OpenTraceBroadcaster MSVC Build Test ===" -ForegroundColor Green

# Test 1: Check required tools
Write-Host "`n1. Checking required tools..." -ForegroundColor Yellow

$tools = @{
    "cmake" = "CMake"
    "ninja" = "Ninja Build System"
    "cl" = "MSVC Compiler"
    "msbuild" = "MSBuild"
}

$toolsOk = $true
foreach ($tool in $tools.Keys) {
    try {
        $null = & $tool --version 2>$null
        Write-Host "  ✓ $($tools[$tool]) found" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ $($tools[$tool]) not found" -ForegroundColor Red
        $toolsOk = $false
    }
}

if (-not $toolsOk) {
    Write-Error "Required tools are missing. Please install Visual Studio, CMake, and Ninja."
}

# Test 2: Check Visual Studio environment
Write-Host "`n2. Checking Visual Studio environment..." -ForegroundColor Yellow

if ($env:VCINSTALLDIR) {
    Write-Host "  ✓ Visual Studio environment detected" -ForegroundColor Green
    Write-Verbose "  VCINSTALLDIR: $env:VCINSTALLDIR"
} else {
    Write-Host "  ! Visual Studio environment not set up" -ForegroundColor Yellow
    Write-Host "  Attempting to set up MSVC environment..." -ForegroundColor Cyan
    
    # Try to find and run vcvars64.bat
    $vcvarsPath = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
    )
    
    $vcvarsFound = $false
    foreach ($path in $vcvarsPath) {
        if (Test-Path $path) {
            Write-Host "  Found vcvars64.bat at: $path" -ForegroundColor Cyan
            $vcvarsFound = $true
            break
        }
    }
    
    if (-not $vcvarsFound) {
        Write-Warning "Could not find vcvars64.bat. Please run this script from a Visual Studio Developer Command Prompt."
    }
}

# Test 3: Check CMake configuration
Write-Host "`n3. Testing CMake configuration..." -ForegroundColor Yellow

$testBuildDir = "test-build-msvc"
if (Test-Path $testBuildDir) {
    Remove-Item -Recurse -Force $testBuildDir
}

try {
    Write-Host "  Configuring test build..." -ForegroundColor Cyan
    
    $cmakeArgs = @(
        "-S", "."
        "-B", $testBuildDir
        "-G", "Ninja"
        "-DCMAKE_BUILD_TYPE=Release"
        "-DCMAKE_C_COMPILER=cl"
        "-DCMAKE_CXX_COMPILER=cl"
    )
    
    $output = & cmake @cmakeArgs 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ CMake configuration successful" -ForegroundColor Green
    } else {
        Write-Host "  ✗ CMake configuration failed" -ForegroundColor Red
        Write-Host "Output:" -ForegroundColor Gray
        $output | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        throw "CMake configuration failed"
    }
} catch {
    Write-Error "CMake configuration test failed: $_"
}

# Test 4: Check dependency detection
Write-Host "`n4. Checking dependency detection..." -ForegroundColor Yellow

$cmakeCache = "$testBuildDir/CMakeCache.txt"
if (Test-Path $cmakeCache) {
    $cacheContent = Get-Content $cmakeCache
    
    # Check for OpenTraceCapture
    $otcFound = $cacheContent | Where-Object { $_ -match "OpenTraceCapture.*FOUND" }
    if ($otcFound) {
        Write-Host "  ✓ OpenTraceCapture dependency detected" -ForegroundColor Green
    } else {
        Write-Host "  ! OpenTraceCapture dependency not found" -ForegroundColor Yellow
        Write-Host "    This is expected if dependencies are not yet built" -ForegroundColor Gray
    }
    
    # Check for libserialport
    $libspFound = $cacheContent | Where-Object { $_ -match "libserialport.*FOUND" }
    if ($libspFound) {
        Write-Host "  ✓ libserialport dependency detected" -ForegroundColor Green
    } else {
        Write-Host "  ! libserialport dependency not found" -ForegroundColor Yellow
        Write-Host "    This is expected if dependencies are not yet built" -ForegroundColor Gray
    }
}

# Test 5: Build test (optional)
if (-not $SkipBuild) {
    Write-Host "`n5. Testing build process..." -ForegroundColor Yellow
    
    try {
        Write-Host "  Building test project..." -ForegroundColor Cyan
        $buildOutput = & cmake --build $testBuildDir --config Release 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Build successful" -ForegroundColor Green
            
            # Check for output files
            $dllPath = "$testBuildDir/obs-measurement-overlay.dll"
            if (Test-Path $dllPath) {
                Write-Host "  ✓ Plugin DLL created" -ForegroundColor Green
                
                # Check DLL dependencies
                try {
                    $dumpbinOutput = & dumpbin /dependents $dllPath 2>$null
                    if ($dumpbinOutput -match "MSVCR|VCRUNTIME") {
                        Write-Host "  ✓ MSVC runtime dependencies detected" -ForegroundColor Green
                    }
                } catch {
                    Write-Verbose "Could not check DLL dependencies (dumpbin not available)"
                }
            } else {
                Write-Host "  ! Plugin DLL not found at expected location" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ✗ Build failed" -ForegroundColor Red
            Write-Host "Build output:" -ForegroundColor Gray
            $buildOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        }
    } catch {
        Write-Host "  ✗ Build test failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "`n5. Skipping build test (use -SkipBuild:$false to enable)" -ForegroundColor Gray
}

# Cleanup
Write-Host "`n6. Cleaning up..." -ForegroundColor Yellow
if (Test-Path $testBuildDir) {
    Remove-Item -Recurse -Force $testBuildDir
    Write-Host "  ✓ Test build directory cleaned" -ForegroundColor Green
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "MSVC build environment validation completed." -ForegroundColor Cyan

if ($toolsOk) {
    Write-Host "✓ All required tools are available" -ForegroundColor Green
} else {
    Write-Host "✗ Some required tools are missing" -ForegroundColor Red
}

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Build dependencies with MSVC (libserialport, OpenTraceCapture)" -ForegroundColor Gray
Write-Host "2. Run: .\build-msvc.ps1 -Configuration Release" -ForegroundColor Gray
Write-Host "3. Check output in build-msvc/ directory" -ForegroundColor Gray

Write-Host "`nFor more information, see MSVC_BUILD.md" -ForegroundColor Cyan
