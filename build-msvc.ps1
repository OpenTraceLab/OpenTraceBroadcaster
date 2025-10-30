#!/usr/bin/env pwsh
# Build script for OpenTraceBroadcaster using MSVC

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug", "Release", "RelWithDebInfo")]
    [string]$Configuration = "Release",
    
    [Parameter(Mandatory=$false)]
    [string]$BuildDir = "build-msvc",
    
    [Parameter(Mandatory=$false)]
    [string]$InstallPrefix = "install-msvc",
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean,
    
    [Parameter(Mandatory=$false)]
    [string]$OpenTraceCaptureDir = "",
    
    [Parameter(Mandatory=$false)]
    [string]$LibSerialPortDir = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OBSStudioDir = ""
)

$ErrorActionPreference = "Stop"

Write-Host "Building OpenTraceBroadcaster with MSVC..." -ForegroundColor Green
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Build Directory: $BuildDir" -ForegroundColor Yellow
Write-Host "Install Prefix: $InstallPrefix" -ForegroundColor Yellow

# Clean build directory if requested
if ($Clean -and (Test-Path $BuildDir)) {
    Write-Host "Cleaning build directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $BuildDir
}

# Check for required tools
$tools = @("cmake", "ninja")
foreach ($tool in $tools) {
    try {
        & $tool --version | Out-Null
        Write-Host "✓ Found $tool" -ForegroundColor Green
    } catch {
        Write-Error "Required tool '$tool' not found. Please install CMake and Ninja."
        exit 1
    }
}

# Setup CMake arguments
$cmakeArgs = @(
    "-S", "."
    "-B", $BuildDir
    "-G", "Ninja"
    "-DCMAKE_BUILD_TYPE=$Configuration"
    "-DCMAKE_INSTALL_PREFIX=$InstallPrefix"
    "-DCMAKE_C_COMPILER=cl"
    "-DCMAKE_CXX_COMPILER=cl"
)

# Add dependency paths if provided
if ($OpenTraceCaptureDir -ne "" -and (Test-Path $OpenTraceCaptureDir)) {
    Write-Host "Using OpenTraceCapture from: $OpenTraceCaptureDir" -ForegroundColor Cyan
    $cmakeArgs += "-DOpenTraceCapture_ROOT=$OpenTraceCaptureDir"
}

if ($LibSerialPortDir -ne "" -and (Test-Path $LibSerialPortDir)) {
    Write-Host "Using libserialport from: $LibSerialPortDir" -ForegroundColor Cyan
    $cmakeArgs += "-Dlibserialport_ROOT=$LibSerialPortDir"
}

if ($OBSStudioDir -ne "" -and (Test-Path $OBSStudioDir)) {
    Write-Host "Using OBS Studio from: $OBSStudioDir" -ForegroundColor Cyan
    $cmakeArgs += "-DOBS_ROOT=$OBSStudioDir"
}

# Configure build
Write-Host "Configuring build..." -ForegroundColor Cyan
Write-Host "Running: cmake $($cmakeArgs -join ' ')" -ForegroundColor Gray

try {
    & cmake @cmakeArgs
    if ($LASTEXITCODE -ne 0) {
        throw "CMake configuration failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "Configuration failed: $_"
    exit 1
}

# Build
Write-Host "Building..." -ForegroundColor Cyan
try {
    & cmake --build $BuildDir --config $Configuration --parallel
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "Build completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "Build failed: $_"
    exit 1
}

# Install
Write-Host "Installing..." -ForegroundColor Cyan
try {
    & cmake --install $BuildDir --config $Configuration
    if ($LASTEXITCODE -ne 0) {
        throw "Install failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "Installation completed successfully!" -ForegroundColor Green
    
    # List installed files
    if (Test-Path $InstallPrefix) {
        Write-Host "Installed files:" -ForegroundColor Yellow
        Get-ChildItem -Path $InstallPrefix -Recurse -File | ForEach-Object {
            Write-Host "  $($_.FullName)" -ForegroundColor Gray
        }
    }
    
} catch {
    Write-Error "Installation failed: $_"
    exit 1
}

# Show build artifacts
Write-Host "Build artifacts:" -ForegroundColor Yellow
if (Test-Path $BuildDir) {
    Get-ChildItem -Path $BuildDir -Recurse -Include "*.dll", "*.lib", "*.exe", "*.pdb" | ForEach-Object {
        Write-Host "  $($_.FullName)" -ForegroundColor Gray
    }
}

Write-Host "Build process completed successfully!" -ForegroundColor Green
