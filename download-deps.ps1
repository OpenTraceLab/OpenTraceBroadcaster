#!/usr/bin/env pwsh
# Download latest MSVC releases for OpenTraceBroadcaster dependencies

param(
    [string]$OutputDir = "deps",
    [string]$GitHubToken = $env:GITHUB_TOKEN
)

$ErrorActionPreference = "Stop"

function Get-LatestRelease {
    param([string]$Repo, [string]$Pattern)
    
    $headers = @{}
    if ($GitHubToken) { $headers["Authorization"] = "Bearer $GitHubToken" }
    
    $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Headers $headers
    $asset = $releases[0].assets | Where-Object { $_.name -match $Pattern } | Select-Object -First 1
    
    if ($asset) {
        Write-Host "Downloading $($asset.name)..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile "$OutputDir/$($asset.name)" -Headers $headers
        return "$OutputDir/$($asset.name)"
    }
    return $null
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Download libserialport MSVC release
$libsp = Get-LatestRelease "OpenTraceLab/libserialport" "msvc.*x64.*\.zip"
if ($libsp) { Expand-Archive $libsp -DestinationPath "$OutputDir/libserialport" -Force }

# Download OpenTraceCapture MSVC release  
$otc = Get-LatestRelease "OpenTraceLab/OpenTraceCapture" "msvc.*\.zip"
if ($otc) { Expand-Archive $otc -DestinationPath "$OutputDir/opentracecapture" -Force }

Write-Host "Dependencies downloaded to $OutputDir" -ForegroundColor Green
