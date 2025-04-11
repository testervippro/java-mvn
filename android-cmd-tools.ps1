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

if (-Not (Test-Path "$javaHome\bin\java.exe")) {
    if (-Not (Test-Path $javaInstaller)) {
        Write-Host "Downloading JDK installer..."
        try { 
            Invoke-WebRequest -Uri $javaUrl -OutFile $javaInstaller 
            Write-Host "JDK installer downloaded."
        } catch { 
            Write-Host "Failed to download JDK. $_"; Exit 
        }
    }

    Write-Host "Installing Java..."
    try {
        Start-Process -FilePath $javaInstaller -ArgumentList "/s" -NoNewWindow -Wait
        Write-Host "Java installation completed."
    } catch { 
        Write-Host "Java install failed. $_"; Exit 
    }
} else {
    Write-Host "Java is already installed at $javaHome"
}

# Update environment variables if not already set
$currentJavaHome = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
if ($currentJavaHome -ne $javaHome) {
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
    Write-Host "JAVA_HOME updated."
}

$javaBin = "$javaHome\bin"
$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
if (-not ($systemPath -split ";" -contains $javaBin)) {
    $newPath = $systemPath.TrimEnd(";") + ";$javaBin"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "Java bin added to PATH."
}

Write-Host "`nJAVA VERSION:"
java -version

# ===================== MAVEN INSTALLATION =====================
$mavenVersion = "3.9.9"
$mavenUrl = "https://dlcdn.apache.org/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip"
$mavenZip = "$env:USERPROFILE\Downloads\apache-maven-$mavenVersion-bin.zip"
$mavenInstallDir = "C:\Program Files\Apache\maven-$mavenVersion"
$mavenExtracted = "$mavenInstallDir\apache-maven-$mavenVersion"
$mavenBin = "$mavenExtracted\bin"

if (-Not (Test-Path "$mavenExtracted\bin\mvn.cmd")) {
    if (-Not (Test-Path $mavenZip)) {
        Write-Host "Downloading Maven..."
        try { 
            Invoke-WebRequest -Uri $mavenUrl -OutFile $mavenZip 
            Write-Host "Maven downloaded."
        } catch { 
            Write-Host "Failed to download Maven. $_"; Exit 
        }
    }

    New-Item -ItemType Directory -Path $mavenInstallDir -Force | Out-Null
    try {
        Expand-Archive -Path $mavenZip -DestinationPath $mavenInstallDir -Force
        Write-Host "Maven extracted to $mavenInstallDir"
    } catch { 
        Write-Host "Failed to extract Maven. $_"; Exit 
    }
} else {
    Write-Host "Maven is already installed at $mavenExtracted"
}

# Update environment variables if not already set
$currentMavenHome = [System.Environment]::GetEnvironmentVariable("MAVEN_HOME", "Machine")
if ($currentMavenHome -ne $mavenExtracted) {
    [System.Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenExtracted, "Machine")
    Write-Host "MAVEN_HOME updated."
}

$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
if (-not ($systemPath -split ";" -contains $mavenBin)) {
    $newPath = $systemPath.TrimEnd(";") + ";$mavenBin"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "Maven bin added to PATH."
}

Write-Host "`nMAVEN VERSION:"
mvn -version

# ===================== PODMAN PORTABLE =====================
$zipUrl = "https://drive.google.com/uc?export=download&id=1saE2g62o9RCixEB8ZCelo1GpJqjm19Qf"
$zipFile = "$env:TEMP\podman-portable.zip"
$extractPath = "$env:USERPROFILE\podman-portable"
$binPath = Join-Path $extractPath "podman\bin"

if (-Not (Test-Path "$binPath\podman.exe")) {
    Write-Host "Downloading Podman Portable..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile

    Write-Host "Extracting Podman Portable..."
    if (Test-Path $extractPath) { Remove-Item -Recurse -Force $extractPath }
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
    Write-Host "Podman Portable extracted."
} else {
    Write-Host "Podman Portable already installed."
}

# Update PATH if needed
$envPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if (-not ($envPath -split ";" -contains $binPath)) {
    [Environment]::SetEnvironmentVariable("Path", "$envPath;$binPath", [EnvironmentVariableTarget]::Machine)
    Write-Host "Added Podman to system PATH."
} else {
    Write-Host "Podman is already in PATH."
}

# ===================== NODE.JS, APPIUM & INSPECTOR =====================
$nodeUrl = "https://nodejs.org/dist/$nodeVersion/node-$nodeVersion-x64.msi"
$nodeInstaller = "$env:USERPROFILE\Downloads\node-$nodeVersion-x64.msi"
$nodePath = "C:\Program Files\nodejs"

if (-Not (Test-Path "$nodePath\node.exe")) {
    if (-Not (Test-Path $nodeInstaller)) {
        Write-Host "Downloading Node.js installer..."
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller
    }

    Write-Host "Installing Node.js..."
    Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /qn /norestart" -Wait
    Write-Host "Node.js installed."
} else {
    Write-Host "Node.js is already installed at $nodePath"
}

# Update PATH if needed
$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
if (-not ($systemPath -split ";" -contains $nodePath)) {
    $newPath = $systemPath.TrimEnd(";") + ";$nodePath"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "Node.js added to PATH."
}

Write-Host "NODE VERSION:"
node -v
Write-Host "NPM VERSION:"
npm -v

# Check if Appium is installed
$appiumCheck = npm list -g appium --depth=0 2>&1
if ($appiumCheck -like "*empty*" -or $appiumCheck -like "*error*") {
    Write-Host "Installing Appium & Appium Doctor..."
    npm install -g appium
    npm install -g appium-doctor
} else {
    Write-Host "Appium is already installed globally."
}

Write-Host "APPIUM VERSION:"; appium --version
Write-Host "APPIUM DOCTOR VERSION:"; appium-doctor --version

# Install Appium Inspector if not already installed
$inspectorUrl = "https://github.com/appium/appium-inspector/releases/download/v2025.3.1/Appium-Inspector-2025.3.1-win-x64.exe"
$inspectorPath = "$env:USERPROFILE\Downloads\Appium-Inspector-windows.exe"
$inspectorInstalledPath = "$env:USERPROFILE\AppData\Local\Programs\appium-inspector"

if (-Not (Test-Path $inspectorInstalledPath)) {
    if (-Not (Test-Path $inspectorPath)) {
        Write-Host "Downloading Appium Inspector..."
        Invoke-WebRequest -Uri $inspectorUrl -OutFile $inspectorPath
    }
    Write-Host "Installing Appium Inspector..."
    Start-Process -FilePath $inspectorPath -Wait
} else {
    Write-Host "Appium Inspector is already installed."
}

# ===================== ANDROID SDK COMMAND LINE TOOLS =====================
$androidZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
$androidZipPath = "$env:USERPROFILE\Downloads\commandlinetools.zip"
$androidSdkRoot = "C:\Android\android_sdk"
$cmdlineTempPath = "$androidSdkRoot\cmdline-tools\temp"
$cmdlineToolsPath = "$androidSdkRoot\cmdline-tools\latest"

if (-Not (Test-Path $androidSdkRoot)) {
    New-Item -ItemType Directory -Path $androidSdkRoot -Force | Out-Null
}

if (-Not (Test-Path "$cmdlineToolsPath\bin\sdkmanager.bat")) {
    if (-Not (Test-Path $androidZipPath)) {
        Invoke-WebRequest -Uri $androidZipUrl -OutFile $androidZipPath
    }

    if (Test-Path $cmdlineToolsPath) { Remove-Item -Recurse -Force $cmdlineToolsPath }
    if (Test-Path $cmdlineTempPath) { Remove-Item -Recurse -Force $cmdlineTempPath }
    
    Expand-Archive -Path $androidZipPath -DestinationPath $cmdlineTempPath -Force
    Move-Item "$cmdlineTempPath\cmdline-tools" $cmdlineToolsPath -Force
    Write-Host "Android Command Line Tools installed."
} else {
    Write-Host "Android Command Line Tools already installed."
}

# Update environment variables if needed
$currentAndroidHome = [System.Environment]::GetEnvironmentVariable("ANDROID_HOME", "Machine")
if ($currentAndroidHome -ne $androidSdkRoot) {
    [System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkRoot, "Machine")
    Write-Host "ANDROID_HOME updated."
}

$currentAndroidSdkRoot = [System.Environment]::GetEnvironmentVariable("ANDROID_SDK_ROOT", "Machine")
if ($currentAndroidSdkRoot -ne $androidSdkRoot) {
    [System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdkRoot, "Machine")
    Write-Host "ANDROID_SDK_ROOT updated."
}

$pathsToAdd = @(
    "$cmdlineToolsPath\bin",
    "$androidSdkRoot\platform-tools",
    "$androidSdkRoot\emulator",
    "$androidSdkRoot\build-tools\$buildToolsVersion"
)

$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }
$newPath = $currentPath
$addedPaths = 0

foreach ($path in $pathsToAdd) {
    if (-not ($currentPath -contains $path)) {
        $newPath += $path
        $addedPaths++
    }
}

if ($addedPaths -gt 0) {
    [System.Environment]::SetEnvironmentVariable("Path", ($newPath -join ";"), "Machine")
    Write-Host "Added $addedPaths Android paths to system PATH."
}

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
