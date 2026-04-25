# Theia Client Installer for Windows
# Usage: irm https://data-tamer.github.io/theia-client-releases/install.ps1 | iex

$ErrorActionPreference = "Stop"
$Repo = "data-tamer/theia-client-releases"
$Asset = "theia-windows-amd64.exe"
$InstallDir = "C:\Program Files\TheiaClient"
$Binary = "theia.exe"

Write-Host "=== Theia Client Installer ===" -ForegroundColor Cyan
Write-Host ""

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -Command `"irm https://data-tamer.github.io/theia-client-releases/install.ps1 | iex`""
    exit
}

Write-Host "Platform: windows/amd64"

# Download
$URL = "https://github.com/$Repo/releases/latest/download/$Asset"
$TmpFile = "$env:TEMP\theia-setup.exe"
Write-Host "Downloading $Asset..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $URL -OutFile $TmpFile -UseBasicParsing

# Verify
$ver = & $TmpFile version 2>&1
Write-Host "Downloaded: $ver"

# Install
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item $TmpFile "$InstallDir\$Binary" -Force
Remove-Item $TmpFile -Force

Write-Host "Installed to: $InstallDir\$Binary"
Write-Host ""

# Run built-in installer
Write-Host "Setting up service..."
& "$InstallDir\$Binary" install

Write-Host ""
Write-Host "Done! Open http://localhost:8080/setup to configure." -ForegroundColor Green
