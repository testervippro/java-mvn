# ===============================
# Android SDK Setup for Windows
# Author: Mesaque Francisco (updated & merged version)
# Idempotent, repeatable setup script
# ===============================

# Configuration
$androidZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
$androidZipPath = "$env:USERPROFILE\Downloads\commandlinetools.zip"
$androidSdkRoot = "C:\Android\sdk"
$cmdlineTempPath = "$androidSdkRoot\cmdline-tools\temp"
$cmdlineToolsPath = "$androidSdkRoot\cmdline-tools\latest"
$systemImage = "system-images;android-34;google_apis_playstore;x86_64"
$avdName = "pixel_avd"

# Create SDK root directory if it doesn't exist
if (-Not (Test-Path $androidSdkRoot)) {
    Write-Host "📁 Creating SDK directory: $androidSdkRoot"
    New-Item -ItemType Directory -Path $androidSdkRoot -Force | Out-Null
}

# Step 1: Download Command Line Tools ZIP if not already
if (-Not (Test-Path $androidZipPath)) {
    Write-Host "📥 Downloading Android command line tools..."
    Invoke-WebRequest -Uri $androidZipUrl -OutFile $androidZipPath
}

# Step 2: Extract and rename 'cmdline-tools' -> 'latest'
if (-Not (Test-Path "$cmdlineToolsPath\bin\sdkmanager.bat")) {
    Write-Host "📦 Extracting tools to SDK path..."

    # Remove old 'latest' if exists
    if (Test-Path $cmdlineToolsPath) {
        Write-Host "🧹 Cleaning up old 'latest' directory..."
        Remove-Item -Recurse -Force $cmdlineToolsPath
    }

    # Clean old temp, extract, and rename
    if (Test-Path $cmdlineTempPath) {
        Remove-Item -Recurse -Force $cmdlineTempPath
    }

    Expand-Archive -Path $androidZipPath -DestinationPath $cmdlineTempPath -Force
    Move-Item "$cmdlineTempPath\cmdline-tools" $cmdlineToolsPath -Force
}

# Step 3: Set environment variables (Machine-level)
Write-Host "⚙ Setting ANDROID_HOME and updating system PATH..."
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkRoot, "Machine")

$pathsToAdd = @(
    "$cmdlineToolsPath\bin",
    "$androidSdkRoot\platform-tools",
    "$androidSdkRoot\emulator",
    "$androidSdkRoot\tools",
    "$androidSdkRoot\tools\bin"
)

$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }
$newPath = ($currentPath + $pathsToAdd | Select-Object -Unique) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

# Step 4: Define sdkmanager
$sdkmanager = "$cmdlineToolsPath\bin\sdkmanager.bat"

# Function to install packages if not present
function Install-PackageIfMissing($pkgName) {
    $installed = & $sdkmanager --list_installed 2>&1 | Select-String $pkgName
    if (-not $installed) {
        Write-Host "📦 Installing: $pkgName"
        & $sdkmanager $pkgName --sdk_root="$androidSdkRoot"
    } else {
        Write-Host "✔ Already installed: $pkgName"
    }
}

# Step 5: Install required SDK packages
$packages = @(
    "cmdline-tools;latest",
    "platform-tools",
    "emulator",
    "build-tools;34.0.0",
    "platforms;android-34",
    "extras;google;m2repository",
    "extras;android;m2repository"
)

foreach ($pkg in $packages) {
    Install-PackageIfMissing $pkg
}

# Step 6: Accept all licenses
Write-Host "✅ Accepting licenses..."
& $sdkmanager --licenses

# Step 7: Install system image if missing
Install-PackageIfMissing $systemImage

# Step 8: Create AVD if not exists
$avdmanager = "$cmdlineToolsPath\bin\avdmanager.bat"
$existingAvd = & $avdmanager list avd | Select-String $avdName

if (-not $existingAvd) {
    Write-Host "📱 Creating AVD: $avdName"
    & $avdmanager create avd -n $avdName --device "pixel" -k $systemImage --force
} else {
    Write-Host "✔ AVD already exists: $avdName"
}

# Final message
Write-Host "`n🎉 Android SDK setup complete and repeatable!"
Write-Host "🔁 You can run this script anytime to ensure the environment is configured properly."
Write-Host "➡ Restart PowerShell or your system to apply environment changes."
Write-Host "➡ To launch emulator: emulator @$avdName"
