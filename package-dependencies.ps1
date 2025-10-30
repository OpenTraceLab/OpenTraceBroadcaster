#!/usr/bin/env pwsh
# Package MSVC-built dependencies for OpenTraceBroadcaster

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "dependencies-msvc",
    
    [Parameter(Mandatory=$false)]
    [string]$LibSerialPortArtifact = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OpenTraceCaptureArtifact = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$DownloadFromCI,
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken = ""
)

$ErrorActionPreference = "Stop"

Write-Host "Packaging MSVC dependencies for OpenTraceBroadcaster..." -ForegroundColor Green
Write-Host "Output Directory: $OutputDir" -ForegroundColor Yellow

# Create output directory
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Function to download GitHub artifact
function Download-GitHubArtifact {
    param(
        [string]$Repository,
        [string]$ArtifactName,
        [string]$Token,
        [string]$OutputPath
    )
    
    if ($Token -eq "") {
        Write-Warning "GitHub token not provided. Cannot download artifacts from CI."
        return $false
    }
    
    Write-Host "Downloading $ArtifactName from $Repository..." -ForegroundColor Cyan
    
    # This is a placeholder - in a real scenario, you'd use GitHub API
    # to download the latest successful build artifacts
    Write-Host "Note: GitHub artifact download not implemented in this demo" -ForegroundColor Yellow
    return $false
}

# Function to extract and organize dependency
function Organize-Dependency {
    param(
        [string]$SourcePath,
        [string]$DependencyName,
        [string]$TargetPath
    )
    
    Write-Host "Organizing $DependencyName..." -ForegroundColor Cyan
    
    $depDir = Join-Path $TargetPath $DependencyName
    New-Item -ItemType Directory -Path $depDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$depDir/include" -Force | Out-Null
    New-Item -ItemType Directory -Path "$depDir/lib" -Force | Out-Null
    New-Item -ItemType Directory -Path "$depDir/bin" -Force | Out-Null
    
    if (Test-Path $SourcePath) {
        # Copy files based on extension
        Get-ChildItem -Path $SourcePath -Recurse -File | ForEach-Object {
            switch ($_.Extension.ToLower()) {
                ".h" { Copy-Item $_.FullName "$depDir/include/" -Force }
                ".hpp" { Copy-Item $_.FullName "$depDir/include/" -Force }
                ".lib" { Copy-Item $_.FullName "$depDir/lib/" -Force }
                ".dll" { Copy-Item $_.FullName "$depDir/bin/" -Force }
                ".pdb" { Copy-Item $_.FullName "$depDir/bin/" -Force }
            }
        }
        
        Write-Host "✓ Organized $DependencyName" -ForegroundColor Green
    } else {
        Write-Warning "Source path not found: $SourcePath"
    }
}

# Handle libserialport
if ($LibSerialPortArtifact -ne "" -and (Test-Path $LibSerialPortArtifact)) {
    Organize-Dependency -SourcePath $LibSerialPortArtifact -DependencyName "libserialport" -TargetPath $OutputDir
} elseif ($DownloadFromCI) {
    $downloaded = Download-GitHubArtifact -Repository "OpenTraceLab/libserialport" -ArtifactName "libserialport-msvc-package-x64" -Token $GitHubToken -OutputPath $OutputDir
    if (-not $downloaded) {
        Write-Warning "Could not download libserialport from CI"
    }
} else {
    Write-Host "Creating placeholder for libserialport..." -ForegroundColor Yellow
    $libspDir = Join-Path $OutputDir "libserialport"
    New-Item -ItemType Directory -Path "$libspDir/include" -Force | Out-Null
    New-Item -ItemType Directory -Path "$libspDir/lib" -Force | Out-Null
    New-Item -ItemType Directory -Path "$libspDir/bin" -Force | Out-Null
    
    # Create placeholder files
    "// Placeholder libserialport.h" | Out-File "$libspDir/include/libserialport.h" -Encoding UTF8
    Write-Host "Note: Add actual libserialport MSVC build artifacts here" -ForegroundColor Cyan
}

# Handle OpenTraceCapture
if ($OpenTraceCaptureArtifact -ne "" -and (Test-Path $OpenTraceCaptureArtifact)) {
    Organize-Dependency -SourcePath $OpenTraceCaptureArtifact -DependencyName "opentracecapture" -TargetPath $OutputDir
} elseif ($DownloadFromCI) {
    $downloaded = Download-GitHubArtifact -Repository "OpenTraceLab/OpenTraceCapture" -ArtifactName "opentracecapture-msvc-package" -Token $GitHubToken -OutputPath $OutputDir
    if (-not $downloaded) {
        Write-Warning "Could not download OpenTraceCapture from CI"
    }
} else {
    Write-Host "Creating placeholder for OpenTraceCapture..." -ForegroundColor Yellow
    $otcDir = Join-Path $OutputDir "opentracecapture"
    New-Item -ItemType Directory -Path "$otcDir/include" -Force | Out-Null
    New-Item -ItemType Directory -Path "$otcDir/lib" -Force | Out-Null
    New-Item -ItemType Directory -Path "$otcDir/bin" -Force | Out-Null
    
    # Create placeholder files
    New-Item -ItemType Directory -Path "$otcDir/include/opentracecapture" -Force | Out-Null
    "// Placeholder opentracecapture.h" | Out-File "$otcDir/include/opentracecapture/opentracecapture.h" -Encoding UTF8
    Write-Host "Note: Add actual OpenTraceCapture MSVC build artifacts here" -ForegroundColor Cyan
}

# Create CMake config files
Write-Host "Creating CMake configuration files..." -ForegroundColor Cyan

$cmakeConfig = @"
# MSVC Dependencies Configuration for OpenTraceBroadcaster
set(DEPENDENCIES_ROOT `${CMAKE_CURRENT_LIST_DIR})

# libserialport
set(libserialport_ROOT "`${DEPENDENCIES_ROOT}/libserialport")
set(libserialport_INCLUDE_DIR "`${libserialport_ROOT}/include")
set(libserialport_LIBRARY "`${libserialport_ROOT}/lib/libserialport.lib")

# OpenTraceCapture
set(OpenTraceCapture_ROOT "`${DEPENDENCIES_ROOT}/opentracecapture")
set(OpenTraceCapture_INCLUDE_DIR "`${OpenTraceCapture_ROOT}/include")
set(OpenTraceCapture_LIBRARY "`${OpenTraceCapture_ROOT}/lib/opentracecapture.lib")
set(OpenTraceCapture_DLL "`${OpenTraceCapture_ROOT}/bin/opentracecapture.dll")

# Add to CMAKE_PREFIX_PATH
list(APPEND CMAKE_PREFIX_PATH "`${libserialport_ROOT}" "`${OpenTraceCapture_ROOT}")
"@

$cmakeConfig | Out-File "$OutputDir/MSVCDependencies.cmake" -Encoding UTF8

# Create package info
$packageInfo = @{
    "name" = "OpenTraceBroadcaster MSVC Dependencies"
    "version" = "1.0.0"
    "created" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    "dependencies" = @{
        "libserialport" = @{
            "path" = "libserialport"
            "description" = "Serial port library (MSVC build)"
        }
        "opentracecapture" = @{
            "path" = "opentracecapture"
            "description" = "Logic analyzer library (MSVC build)"
        }
    }
}

$packageInfo | ConvertTo-Json -Depth 3 | Out-File "$OutputDir/package.json" -Encoding UTF8

# Create archive
Write-Host "Creating dependency archive..." -ForegroundColor Cyan
$archiveName = "opentrace-broadcaster-dependencies-msvc.zip"
if (Test-Path $archiveName) {
    Remove-Item $archiveName -Force
}

Compress-Archive -Path $OutputDir -DestinationPath $archiveName

Write-Host "Dependencies packaged successfully!" -ForegroundColor Green
Write-Host "Archive: $archiveName" -ForegroundColor Yellow
Write-Host "Directory: $OutputDir" -ForegroundColor Yellow

# Show summary
Write-Host "`nPackage Contents:" -ForegroundColor Yellow
Get-ChildItem -Path $OutputDir -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Replace((Resolve-Path $OutputDir).Path, "")
    Write-Host "  $relativePath" -ForegroundColor Gray
}
