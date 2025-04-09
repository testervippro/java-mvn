# ===============================
# Minimal Android SDK Setup (Windows) + PATH Check
# Author: Mesaque (Extended by ChatGPT)
# ===============================

# Config
$androidZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
$androidZipPath = "$env:USERPROFILE\Downloads\commandlinetools.zip"
$androidSdkRoot = "C:\Android\android_sdk"
$cmdlineTempPath = "$androidSdkRoot\cmdline-tools\temp"
$cmdlineToolsPath = "$androidSdkRoot\cmdline-tools\latest"
$buildToolsVersion = "34.0.0"
$avdName = "pixel6a"
$systemImage = "system-images;android-30;google_apis;x86_64"

# Ensure SDK root
if (-Not (Test-Path $androidSdkRoot)) {
    New-Item -ItemType Directory -Path $androidSdkRoot -Force | Out-Null
}

# Download SDK zip
if (-Not (Test-Path $androidZipPath)) {
    Invoke-WebRequest -Uri $androidZipUrl -OutFile $androidZipPath
}

# Extract tools
if (-Not (Test-Path "$cmdlineToolsPath\bin\sdkmanager.bat")) {
    if (Test-Path $cmdlineToolsPath) { Remove-Item -Recurse -Force $cmdlineToolsPath }
    if (Test-Path $cmdlineTempPath) { Remove-Item -Recurse -Force $cmdlineTempPath }

    Expand-Archive -Path $androidZipPath -DestinationPath $cmdlineTempPath -Force
    Move-Item "$cmdlineTempPath\cmdline-tools" $cmdlineToolsPath -Force
}

# Set environment vars (session)
$env:ANDROID_HOME = $androidSdkRoot
$env:ANDROID_SDK_ROOT = $androidSdkRoot

# Persist environment vars
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkRoot, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdkRoot, "Machine")

# Add important paths
$pathsToAdd = @(
    "$cmdlineToolsPath\bin",                           # avdmanager, sdkmanager
    "$androidSdkRoot\platform-tools",                 # adb
    "$androidSdkRoot\emulator",                       # emulator
    "$androidSdkRoot\build-tools\$buildToolsVersion"  # aapt2
)

$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }
$newPath = ($currentPath + $pathsToAdd | Select-Object -Unique) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

# Install packages
$sdkmanager = "$cmdlineToolsPath\bin\sdkmanager.bat"
$packages = @(
    "cmdline-tools;latest",
    "platform-tools",
    "emulator",
    "build-tools;$buildToolsVersion",
    $systemImage
)

function Install-PackageIfMissing($pkg) {
    $installed = & $sdkmanager --list_installed 2>&1 | Select-String $pkg
    if (-not $installed) {
        Write-Host "📦 Installing: $pkg"
        & $sdkmanager $pkg --sdk_root="$androidSdkRoot"
    } else {
        Write-Host "✔ Already installed: $pkg"
    }
}
foreach ($pkg in $packages) {
    Install-PackageIfMissing $pkg
}

# Accept licenses
& $sdkmanager --licenses --sdk_root="$androidSdkRoot" | ForEach-Object { $_ }

# Create AVD
$avdmanager = "$cmdlineToolsPath\bin\avdmanager.bat"
$existingAvd = & $avdmanager list avd | Select-String $avdName
if (-not $existingAvd) {
    Write-Host "📱 Creating AVD: $avdName (Pixel 6a)"
    & $avdmanager create avd -n $avdName --device "pixel_6a" -k $systemImage --force
} else {
    Write-Host "✔ AVD already exists: $avdName"
}

# =======================
#  Check PATH and Tools
# =======================
Write-Host "Verifying tools in PATH..."

Write-Host "Checking adb..."
try {
    adb version
} catch {
    Write-Host "adb not available in PATH or failed to run"
}

Write-Host "Checking emulator..."
try {
    emulator -list-avds
} catch {
    Write-Host "emulator not available in PATH or failed to run"
}

Write-Host "Checking avdmanager..."
try {
    avdmanager -h
} catch {
    Write-Host "avdmanager not available in PATH or failed to run"
}

Write-Host "Checking aapt2..."
try {
    aapt2 version
} catch {
    Write-Host "aapt2 not available in PATH or failed to run"
}


# Final message
Write-Host "`n🎉 Setup complete!"
Write-Host "➡ Restart PowerShell or your PC to apply PATH changes"
Write-Host "➡ Start the emulator using: emulator @$avdName"
