# ===============================
# Android SDK Setup for Windows
# Author: Mesaque Francisco (updated, idempotent)
# Safe to run multiple times (repeatable)
# ===============================

# Configuration
$androidZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
$androidZipPath = "$env:USERPROFILE\Downloads\commandlinetools.zip"
$androidSdkRoot = "C:\Android\android_sdk"
$cmdlineTempPath = "$androidSdkRoot\cmdline-tools\temp"
$cmdlineToolsPath = "$androidSdkRoot\cmdline-tools\latest"
$systemImage = "system-images;android-34;google_apis_playstore;x86_64"
$avdName = "pixel_avd"

# Step 1: Create SDK root directory if it doesn't exist
if (-Not (Test-Path $androidSdkRoot)) {
    Write-Host "📁 Creating SDK directory: $androidSdkRoot"
    New-Item -ItemType Directory -Path $androidSdkRoot -Force | Out-Null
}

# Step 2: Download Command Line Tools ZIP if not already
if (-Not (Test-Path $androidZipPath)) {
    Write-Host "📥 Downloading Android command line tools..."
    Invoke-WebRequest -Uri $androidZipUrl -OutFile $androidZipPath
} else {
    Write-Host "✔ ZIP file already downloaded: $androidZipPath"
}

# Step 3: Extract and rename 'cmdline-tools' -> 'latest' if not present
if (-Not (Test-Path "$cmdlineToolsPath\bin\sdkmanager.bat")) {
    Write-Host "📦 Extracting and setting up command line tools..."

    if (Test-Path $cmdlineToolsPath) {
        Remove-Item -Recurse -Force $cmdlineToolsPath
    }

    if (Test-Path $cmdlineTempPath) {
        Remove-Item -Recurse -Force $cmdlineTempPath
    }

    Expand-Archive -Path $androidZipPath -DestinationPath $cmdlineTempPath -Force
    Move-Item "$cmdlineTempPath\cmdline-tools" $cmdlineToolsPath -Force
} else {
    Write-Host "✔ Command line tools already set up."
}

# Step 4: Set environment variables and PATH safely
Write-Host "⚙ Ensuring ANDROID_HOME and system PATH are set..."

[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkRoot, "Machine")

$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }

$pathsToAdd = @(
    "$cmdlineToolsPath\bin",
    "$androidSdkRoot\platform-tools",
    "$androidSdkRoot\emulator",
    "$androidSdkRoot\tools",
    "$androidSdkRoot\tools\bin"
)

# Step 4.1: Add aapt path (from latest build-tools)
$buildToolsRoot = "$androidSdkRoot\build-tools"
if (Test-Path $buildToolsRoot) {
    $latestBuildTools = Get-ChildItem -Directory $buildToolsRoot | Sort-Object Name -Descending | Select-Object -First 1
    if ($latestBuildTools) {
        $aaptPath = $latestBuildTools.FullName
        Write-Host "🔧 Adding aapt path from build-tools: $aaptPath"
        if (-Not ($pathsToAdd -contains $aaptPath)) {
            $pathsToAdd += $aaptPath
        }
    } else {
        Write-Host "⚠️ No build-tools found yet, skipping aapt path."
    }
}

# Merge and apply updated PATH
$newPath = ($currentPath + $pathsToAdd | Select-Object -Unique) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

# Step 5: Define sdkmanager
$sdkmanager = "$cmdlineToolsPath\bin\sdkmanager.bat"

# Step 6: Install SDK packages if not already installed
function Install-PackageIfMissing($pkgName) {
    $installed = & $sdkmanager --list_installed 2>&1 | Select-String $pkgName
    if (-not $installed) {
        Write-Host "📦 Installing: $pkgName"
        & $sdkmanager $pkgName --sdk_root="$androidSdkRoot"
    } else {
        Write-Host "✔ Already installed: $pkgName"
    }
}

# Step 7: Install required packages
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

# Step 8: Accept licenses silently
Write-Host "✅ Accepting all SDK licenses..."
& $sdkmanager --licenses --sdk_root="$androidSdkRoot" | ForEach-Object { $_ }

# Step 9: Install system image
Install-PackageIfMissing $systemImage

# Step 10: Create AVD only if not exists
$avdmanager = "$cmdlineToolsPath\bin\avdmanager.bat"
$existingAvd = & $avdmanager list avd | Select-String $avdName

if (-not $existingAvd) {
    Write-Host "📱 Creating AVD: $avdName"
    & $avdmanager create avd -n $avdName --device "pixel" -k $systemImage --force
} else {
    Write-Host "✔ AVD already exists: $avdName"
}

# Final message
Write-Host "`n🎉 Android SDK setup complete and fully repeatable!"
Write-Host "🔁 You can re-run this script anytime. It won't reinstall things unnecessarily."
Write-Host "➡ Restart PowerShell or your computer to apply environment variable changes."
Write-Host "➡ To start the emulator: emulator @$avdName"
