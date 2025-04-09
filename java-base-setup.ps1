# ===================== AUTO-ELEVATE TO ADMIN =====================
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $choice = Read-Host "This script requires Administrator rights. Relaunch as Admin? (Y/N)"
    if ($choice -match '^[Yy]') {
        Write-Host "Relaunching as Administrator..."
        Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    } else {
        Write-Host "Exiting. Admin rights are required."
        Exit
    }
}

# ===================== CHECK & SET EXECUTION POLICY =====================
$currentPolicy = Get-ExecutionPolicy -Scope Process
if ($currentPolicy -notin @("RemoteSigned", "Unrestricted")) {
    Write-Host "Current Execution Policy: $currentPolicy"
    $policyChoice = Read-Host "Select policy to apply [R]emoteSigned or [U]nrestricted (R/U):"
    switch ($policyChoice.ToUpper()) {
        "R" {
            Set-ExecutionPolicy RemoteSigned -Scope Process -Force
            Write-Host "Execution policy set to RemoteSigned"
        }
        "U" {
            Set-ExecutionPolicy Unrestricted -Scope Process -Force
            Write-Host "Execution policy set to Unrestricted"
        }
        default {
            Write-Host "Invalid choice. Exiting."
            Exit
        }
    }
}

# ===================== JAVA INSTALLATION =====================
$javaUrl = "https://download.oracle.com/java/17/archive/jdk-17.0.12_windows-x64_bin.exe"
$javaInstaller = "$env:USERPROFILE\Downloads\jdk-17-installer.exe"
$javaHome = "C:\Program Files\Java\jdk-17"

if (-Not (Test-Path $javaInstaller)) {
    Write-Host "Downloading JDK installer..."
    Invoke-WebRequest -Uri $javaUrl -OutFile $javaInstaller
} else {
    Write-Host "JDK installer already exists."
}

Write-Host "Installing Java..."
Start-Process -FilePath $javaInstaller -ArgumentList "/s" -NoNewWindow -Wait
Write-Host "Java installation completed."

[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
Write-Host "JAVA_HOME set to $javaHome"

$javaBin = "$javaHome\bin"
$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$cleanPath = ($systemPath -split ";") | Where-Object { $_ -and ($_ -notlike "*jdk-17*") }
$newPath = ($cleanPath + $javaBin) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "Java bin added to system PATH"

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
    Invoke-WebRequest -Uri $mavenUrl -OutFile $mavenZip
} else {
    Write-Host "Maven zip already exists."
}

New-Item -ItemType Directory -Path $mavenInstallDir -Force | Out-Null
Expand-Archive -Path $mavenZip -DestinationPath $mavenInstallDir -Force
Write-Host "Maven extracted to $mavenInstallDir"

[System.Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenExtracted, "Machine")
Write-Host "MAVEN_HOME set to $mavenExtracted"

$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$cleanPath = ($systemPath -split ";") | Where-Object { $_ -and ($_ -notlike "*apache-maven*") }
$newPath = ($cleanPath + $mavenBin) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "Maven bin added to system PATH"

Write-Host "`nMAVEN VERSION:"
$mvnOutput = mvn -version 2>&1
if ($mvnOutput) {
    Write-Host $mvnOutput
} else {
    Write-Host "Maven installation failed. Please check manually."
}

# ===================== OPTIONAL: NODE.JS + APPIUM SETUP =====================

# Ask if user wants to install Node.js
$installNode = Read-Host "Do you want to install Node.js (required for Appium)? (Y/N)"
if ($installNode -match '^[Yy]') {
    $nodeUrl = "https://nodejs.org/dist/v20.12.2/node-v20.12.2-x64.msi"
    $nodeInstaller = "$env:USERPROFILE\Downloads\node-v20.12.2-x64.msi"

    if (-Not (Test-Path $nodeInstaller)) {
        Write-Host "Downloading Node.js installer..."
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller
    }

    Write-Host "Installing Node.js..."
    Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /qn /norestart" -Wait

    Write-Host "`nNODE VERSION:"
    node -v
    Write-Host "`nNPM VERSION:"
    npm -v
} else {
    Write-Host "Skipping Node.js installation."
}

# Ask if user wants to install Appium globally
$installAppium = Read-Host "Do you want to install Appium globally using npm? (Y/N)"
if ($installAppium -match '^[Yy]') {
    Write-Host "Installing Appium globally..."
    npm install -g appium

    Write-Host "`nAPPIUM VERSION:"
    appium --version
} else {
    Write-Host "Skipping Appium installation."
}

# Ask if user wants to install Appium Inspector (Windows GUI)
$installInspector = Read-Host "Do you want to install Appium Inspector (GUI for Windows 64-bit)? (Y/N)"
if ($installInspector -match '^[Yy]') {
    $inspectorUrl = "https://github.com/appium/appium-inspector/releases/download/v2024.4.1/Appium-Inspector-windows-2024.4.1.exe"
    $inspectorPath = "$env:USERPROFILE\Downloads\Appium-Inspector-windows.exe"

    Write-Host "Downloading Appium Inspector..."
    Invoke-WebRequest -Uri $inspectorUrl -OutFile $inspectorPath

    Write-Host "Launching Appium Inspector installer..."
    Start-Process -FilePath $inspectorPath -Wait
} else {
    Write-Host "Skipping Appium Inspector installation."
}

# ===================== APPIUM DOCTOR & ANDROID DRIVER =====================
# Ask if user wants to install Appium Doctor
$installDoctor = Read-Host "Do you want to install Appium Doctor (diagnostic tool)? (Y/N)"
if ($installDoctor -match '^[Yy]') {
    Write-Host "Installing Appium Doctor..."
    npm install -g appium-doctor
    Write-Host "`nAPPIUM DOCTOR VERSION:"
    appium-doctor --version
    Write-Host "`nRunning Appium Doctor:"
    appium-doctor
} else {
    Write-Host "Skipping Appium Doctor installation."
}

# Ask if user wants to install Android Driver
$installAndroidDriver = Read-Host "Do you want to install the Appium Android driver? (Y/N)"
if ($installAndroidDriver -match '^[Yy]') {
    Write-Host "Installing Appium Android driver..."
    appium driver install uiautomator2
    Write-Host "`nListing installed drivers:"
    appium driver list
} else {
    Write-Host "Skipping Android driver installation."
}




