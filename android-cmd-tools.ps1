# ===================== CHECK & SET EXECUTION POLICY =====================
$currentPolicy = Get-ExecutionPolicy -Scope Process
if ($currentPolicy -notin @("RemoteSigned", "Unrestricted")) {
    Write-Host "Current Execution Policy: $currentPolicy"
    $policyChoice = Read-Host "Select policy to apply [R]emoteSigned or [U]nrestricted (R/U):"
    switch ($policyChoice.ToUpper()) {
        "R" { Set-ExecutionPolicy RemoteSigned -Scope Process -Force; Write-Host "Execution policy set to RemoteSigned" }
        "U" { Set-ExecutionPolicy Unrestricted -Scope Process -Force; Write-Host "Execution policy set to Unrestricted" }
        default { Write-Host "Invalid choice. Exiting."; Exit }
    }
}

$buildToolsVersion = "34.0.0"
$javaHome = "C:\Program Files\Java\jdk-17"
$nodeVersion = "v20.19.0"

# ===================== JAVA INSTALLATION =====================
$javaUrl = "https://download.oracle.com/java/17/archive/jdk-17.0.12_windows-x64_bin.exe"
$javaInstaller = "$env:USERPROFILE\Downloads\jdk-17-installer.exe"

if (-Not (Test-Path $javaInstaller)) {
    Write-Host "Downloading JDK installer..."
    try { Invoke-WebRequest -Uri $javaUrl -OutFile $javaInstaller } catch { Write-Host "Failed to download JDK. $_"; Exit }
} else { Write-Host "JDK installer already exists." }

Write-Host "Installing Java..."
try {
    Start-Process -FilePath $javaInstaller -ArgumentList "/s" -NoNewWindow -Wait
    Write-Host "Java installation completed."
} catch { Write-Host "Java install failed. $_"; Exit }

[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
$javaBin = "$javaHome\bin"
$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$cleanPath = ($systemPath -split ";") | Where-Object { $_ -and ($_ -notlike "*jdk-17*") }
$newPath = ($cleanPath + $javaBin) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "JAVA_HOME and PATH updated."

Write-Host "`nJAVA VERSION:"
java -version

# ===================== MAVEN INSTALLATION =====================
$mavenVersion = "3.9.9"
$mavenUrl = "https://dlcdn.apache.org/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip"
$mavenZip = "$env:USERPROFILE\Downloads\apache-maven-$mavenVersion-bin.zip"
$mavenInstallDir = "C:\Program Files\Apache\maven-$mavenVersion"
$mavenExtracted = "$mavenInstallDir\apache-maven-$mavenVersion"
$mavenBin = "$mavenExtracted\bin"

if (-Not (Test-Path $mavenZip)) {
    Write-Host "Downloading Maven..."
    try { Invoke-WebRequest -Uri $mavenUrl -OutFile $mavenZip } catch { Write-Host "Failed to download Maven. $_"; Exit }
} else { Write-Host "Maven zip already exists." }

New-Item -ItemType Directory -Path $mavenInstallDir -Force | Out-Null
try {
    Expand-Archive -Path $mavenZip -DestinationPath $mavenInstallDir -Force
    Write-Host "Maven extracted to $mavenInstallDir"
} catch { Write-Host "Failed to extract Maven. $_"; Exit }

[System.Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenExtracted, "Machine")
$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$cleanPath = ($systemPath -split ";") | Where-Object { $_ -and ($_ -notlike "*apache-maven*") }
$newPath = ($cleanPath + $mavenBin) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "MAVEN_HOME and PATH updated."

Write-Host "`nMAVEN VERSION:"
mvn -version

# ===================== NODE.JS, APPIUM & INSPECTOR =====================

$nodeUrl = "https://nodejs.org/dist/$nodeVersion/node-$nodeVersion-x64.msi"
$nodeInstaller = "$env:USERPROFILE\Downloads\node-$nodeVersion-x64.msi"
$nodePath = "C:\Program Files\nodejs"

if (-Not (Test-Path $nodeInstaller)) {
    Write-Host "Downloading Node.js installer..."
    Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller
}

Write-Host "Installing Node.js..."
Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /qn /norestart" -Wait
Write-Host "Node.js installed."

if (Test-Path $nodePath) {
    $systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $cleanPath = ($systemPath -split ";") | Where-Object { $_ -and ($_ -notlike "*nodejs*") }
    $newPath = ($cleanPath + $nodePath) -join ";"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
}

Write-Host "NODE VERSION:"
node -v
Write-Host "NPM VERSION:"
npm -v

Write-Host "Installing Appium & Appium Doctor..."
npm install -g appium
npm install -g appium-doctor
Write-Host "APPIUM VERSION:"; appium --version
Write-Host "APPIUM DOCTOR VERSION:"; appium-doctor --version

# Install Appium Inspector
$inspectorUrl = "https://github.com/appium/appium-inspector/releases/download/v2025.3.1/Appium-Inspector-2025.3.1-win-x64.exe"
$inspectorPath = "$env:USERPROFILE\Downloads\Appium-Inspector-windows.exe"
Write-Host "Downloading Appium Inspector..."
Invoke-WebRequest -Uri $inspectorUrl -OutFile $inspectorPath
Start-Process -FilePath $inspectorPath -Wait

# ===================== ANDROID SDK COMMAND LINE TOOLS =====================
$androidZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
$androidZipPath = "$env:USERPROFILE\Downloads\commandlinetools.zip"
$androidSdkRoot = "C:\Android\android_sdk"
$cmdlineTempPath = "$androidSdkRoot\cmdline-tools\temp"
$cmdlineToolsPath = "$androidSdkRoot\cmdline-tools\latest"

if (-Not (Test-Path $androidSdkRoot)) {
    New-Item -ItemType Directory -Path $androidSdkRoot -Force | Out-Null
}

if (-Not (Test-Path $androidZipPath)) {
    Invoke-WebRequest -Uri $androidZipUrl -OutFile $androidZipPath
}

if (-Not (Test-Path "$cmdlineToolsPath\bin\sdkmanager.bat")) {
    if (Test-Path $cmdlineToolsPath) { Remove-Item -Recurse -Force $cmdlineToolsPath }
    if (Test-Path $cmdlineTempPath) { Remove-Item -Recurse -Force $cmdlineTempPath }
    Expand-Archive -Path $androidZipPath -DestinationPath $cmdlineTempPath -Force
    Move-Item "$cmdlineTempPath\cmdline-tools" $cmdlineToolsPath -Force
}

[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkRoot, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdkRoot, "Machine")

$pathsToAdd = @(
    "$cmdlineToolsPath\bin",
    "$androidSdkRoot\platform-tools",
    "$androidSdkRoot\emulator",
    "$androidSdkRoot\build-tools\$buildToolsVersion"
)
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }
$newPath = ($currentPath + $pathsToAdd | Select-Object -Unique) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

$sdkmanager = "$cmdlineToolsPath\bin\sdkmanager.bat"
$packages = @(
    "cmdline-tools;latest",
    "platform-tools",
    "emulator",
    "build-tools;$buildToolsVersion"
)

function Install-PackageIfMissing {
    param([string]$pkg)
    $installed = & $sdkmanager --list_installed 2>&1 | Select-String $pkg
    if (-not $installed) {
        Write-Host " Installing: $pkg"
        & $sdkmanager $pkg --sdk_root="$androidSdkRoot"
    } else {
        Write-Host "Already installed: $pkg"
    }
}

foreach ($pkg in $packages) {
    Install-PackageIfMissing $pkg
}

Write-Host " Verifying Android tools:"
& "$androidSdkRoot\platform-tools\adb.exe" version
& "$cmdlineToolsPath\bin\avdmanager.bat" -h
& "$androidSdkRoot\build-tools\$buildToolsVersion\aapt2.exe" version

Write-Host "All components installed successfully. Please restart your computer to apply environment variable changes."
