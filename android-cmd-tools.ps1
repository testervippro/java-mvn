# Android SDK configuration
$androidZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
$androidZipPath = "$env:USERPROFILE\Downloads\commandlinetools.zip"
$androidSdkRoot = "C:\Android\android_sdk"
$cmdlineTempPath = "$androidSdkRoot\cmdline-tools\temp"
$cmdlineToolsPath = "$androidSdkRoot\cmdline-tools\latest"
$buildToolsVersion = "34.0.0"
$avdName = "demo"
$systemImage = "system-images;android-30;google_apis;x86_64"

# Create SDK root if it doesn't exist
if (-not (Test-Path $androidSdkRoot)) {
    New-Item -ItemType Directory -Path $androidSdkRoot -Force | Out-Null
}

# Download SDK zip
if (-not (Test-Path $androidZipPath)) {
    Invoke-WebRequest -Uri $androidZipUrl -OutFile $androidZipPath
}

# Extract command line tools
if (-not (Test-Path "$cmdlineToolsPath\bin\sdkmanager.bat")) {
    if (Test-Path $cmdlineToolsPath) { Remove-Item -Recurse -Force $cmdlineToolsPath }
    if (Test-Path $cmdlineTempPath) { Remove-Item -Recurse -Force $cmdlineTempPath }
    Expand-Archive -Path $androidZipPath -DestinationPath $cmdlineTempPath -Force
    Move-Item "$cmdlineTempPath\cmdline-tools" $cmdlineToolsPath -Force
}

# Environment variables (session)
$env:ANDROID_HOME = $androidSdkRoot
$env:ANDROID_SDK_ROOT = $androidSdkRoot

$androidEmulatorHome = "$androidSdkRoot\.android"
$androidAvdHome = "$androidEmulatorHome\avd"
$env:ANDROID_EMULATOR_HOME = $androidEmulatorHome
$env:ANDROID_AVD_HOME = $androidAvdHome

# Persist environment variables (machine-wide)
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkRoot, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdkRoot, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_EMULATOR_HOME", $androidEmulatorHome, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_AVD_HOME", $androidAvdHome, "Machine")

# Add tools to system PATH
$pathsToAdd = @(
    "$cmdlineToolsPath\bin",
    "$androidSdkRoot\platform-tools",
    "$androidSdkRoot\emulator",
    "$androidSdkRoot\build-tools\$buildToolsVersion"
)
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }
$newPath = ($currentPath + $pathsToAdd | Select-Object -Unique) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

# Install required SDK packages
$sdkmanager = "$cmdlineToolsPath\bin\sdkmanager.bat"
$packages = @(
    "cmdline-tools;latest",
    "platform-tools",
    "emulator",
    "build-tools;$buildToolsVersion",
    $systemImage
)

function Install-PackageIfMissing {
    param([string]$pkg)
    $installed = & $sdkmanager --list_installed 2>&1 | Select-String $pkg
    if (-not $installed) {
        Write-Host "`n📦 Installing: $pkg"
        & $sdkmanager $pkg --sdk_root="$androidSdkRoot"
    } else {
        Write-Host "✔ Already installed: $pkg"
    }
}

foreach ($pkg in $packages) {
    Install-PackageIfMissing $pkg
}

# Accept licenses
Write-Host "`n📜 Accepting licenses..."
& "$sdkmanager" --licenses | ForEach-Object { Write-Host $_ }

# Create AVD if not exists
$avdmanager = "$cmdlineToolsPath\bin\avdmanager.bat"
$avdIniPath = Join-Path $androidAvdHome "$avdName.ini"

if (-not (Test-Path $avdIniPath)) {
    Write-Host "`n📱 Creating AVD: $avdName (Pixel 6a)"
    $createAvdCmd = "`"$avdmanager`" create avd -n $avdName --device pixel_6a -k `"$systemImage`" --force"
    cmd.exe /c $createAvdCmd
} else {
    Write-Host "✔ AVD already exists: $avdName"
}

# Verify installed tools
Write-Host "`n🛠 Verifying tools in PATH..."
adb version
& "$avdmanager" list avd
& "$androidSdkRoot\build-tools\$buildToolsVersion\aapt2.exe" version
& "$androidSdkRoot\emulator\emulator.exe" -list-avds
