<#
.SYNOPSIS
    Java Development Environment Setup Script
.DESCRIPTION
    Installs Java JDK 17, Maven 3.9.9, and optionally Node.js with Appium
    for mobile test automation. Configures all necessary environment variables.
.NOTES
    Version: 1.1
    Requires: Windows PowerShell 5.1 or later
    Run as Administrator
#>

# ===================== INITIAL SETUP =====================
# Set console encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ===================== EXECUTION POLICY =====================
$currentPolicy = Get-ExecutionPolicy -Scope Process
if ($currentPolicy -notin "RemoteSigned", "Unrestricted") {
    Write-Host "Current Execution Policy: $currentPolicy"
    $policyChoice = Read-Host "Select policy [R]emoteSigned or [U]nrestricted (R/U)"
    
    switch ($policyChoice.ToUpper()) {
        "R" { 
            Set-ExecutionPolicy RemoteSigned -Scope Process -Force
            Write-Host "Execution policy set to RemoteSigned" -ForegroundColor Green
        }
        "U" { 
            Set-ExecutionPolicy Unrestricted -Scope Process -Force
            Write-Host "Execution policy set to Unrestricted" -ForegroundColor Yellow
        }
        default {
            Write-Host "Invalid choice. Exiting." -ForegroundColor Red
            Exit 1
        }
    }
}

# ===================== JAVA INSTALLATION =====================
Write-Host "`n=== JAVA INSTALLATION ===" -ForegroundColor Cyan
$javaUrl = "https://download.oracle.com/java/17/archive/jdk-17.0.12_windows-x64_bin.exe"
$javaInstaller = "$env:TEMP\jdk-17-installer.exe"
$javaHome = "C:\Program Files\Java\jdk-17"

# Download Java
if (-not (Test-Path $javaInstaller)) {
    try {
        Write-Host "Downloading JDK 17..."
        Invoke-WebRequest -Uri $javaUrl -OutFile $javaInstaller -UseBasicParsing
    } catch {
        Write-Host "Download failed: $_" -ForegroundColor Red
        Exit 1
    }
}

# Install Java
try {
    Write-Host "Installing JDK 17 (silent mode)..."
    Start-Process -FilePath $javaInstaller -ArgumentList "/s" -Wait -NoNewWindow
    Write-Host "Java installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
    Exit 1
}

# Set Environment Variables
[Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
$env:JAVA_HOME = $javaHome

$newPath = (
    [Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" |
    Where-Object { $_ -and $_ -notlike "*jdk-17*" }
) -join ";" + ";$javaHome\bin"

[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "Environment variables configured" -ForegroundColor Green

# Verify Installation
try {
    Write-Host "`nJava Version:"
    java -version 2>&1 | Out-Host
} catch {
    Write-Host "Java verification failed" -ForegroundColor Red
}

# ===================== MAVEN INSTALLATION =====================
Write-Host "`n=== MAVEN INSTALLATION ===" -ForegroundColor Cyan
$mavenVersion = "3.9.9"
$mavenUrl = "https://dlcdn.apache.org/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip"
$mavenZip = "$env:TEMP\apache-maven-$mavenVersion-bin.zip"
$mavenHome = "C:\Program Files\Apache\maven-$mavenVersion"

# Download Maven
if (-not (Test-Path $mavenZip)) {
    try {
        Write-Host "Downloading Maven $mavenVersion..."
        Invoke-WebRequest -Uri $mavenUrl -OutFile $mavenZip -UseBasicParsing
    } catch {
        Write-Host "Download failed: $_" -ForegroundColor Red
        Exit 1
    }
}

# Install Maven
try {
    Write-Host "Extracting Maven..."
    if (-not (Test-Path $mavenHome)) {
        New-Item -Path $mavenHome -ItemType Directory -Force | Out-Null
    }
    Expand-Archive -Path $mavenZip -DestinationPath $mavenHome -Force
    
    $mavenPath = Get-ChildItem -Path $mavenHome -Filter "apache-maven-*" | Select-Object -First 1
    [Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenPath.FullName, "Machine")
    
    $newPath = (
        [Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" |
        Where-Object { $_ -and $_ -notlike "*apache-maven*" }
    ) -join ";" + ";$($mavenPath.FullName)\bin"
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "Maven installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
    Exit 1
}

# Verify Installation
try {
    Write-Host "`nMaven Version:"
    mvn -version 2>&1 | Out-Host
} catch {
    Write-Host "Maven verification failed" -ForegroundColor Red
}

# ===================== OPTIONAL: NODE.JS + APPIUM =====================
Write-Host "`n=== OPTIONAL INSTALLATIONS ===" -ForegroundColor Cyan

# Node.js Installation
$installNode = Read-Host "Install Node.js (required for Appium)? [Y/N]"
if ($installNode -match '^[Yy]') {
    $nodeUrl = "https://nodejs.org/dist/v20.12.2/node-v20.12.2-x64.msi"
    $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
    
    try {
        Write-Host "Downloading Node.js..."
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
        
        Write-Host "Installing Node.js..."
        Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /qn /norestart" -Wait
        Write-Host "Node.js installed" -ForegroundColor Green
        
        # Refresh PATH
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Host "`nNode.js Version:"
        node -v 2>&1 | Out-Host
        Write-Host "npm Version:"
        npm -v 2>&1 | Out-Host
        
        # Appium Installation
        $installAppium = Read-Host "Install Appium globally? [Y/N]"
        if ($installAppium -match '^[Yy]') {
            Write-Host "Installing Appium..."
            npm install -g appium
            Write-Host "Appium installed" -ForegroundColor Green
            
            Write-Host "`nAppium Version:"
            appium --version 2>&1 | Out-Host
            
            # Appium Doctor
            $installDoctor = Read-Host "Install Appium Doctor? [Y/N]"
            if ($installDoctor -match '^[Yy]') {
                npm install -g appium-doctor
                Write-Host "`nAppium Doctor Report:"
                appium-doctor 2>&1 | Out-Host
            }
            
            # Appium Inspector
            $installInspector = Read-Host "Install Appium Inspector? [Y/N]"
            if ($installInspector -match '^[Yy]') {
                $inspectorUrl = "https://github.com/appium/appium-inspector/releases/download/v2025.3.1/Appium-Inspector-2025.3.1-win-x64.exe"
                $inspectorPath = "$env:TEMP\Appium-Inspector.exe"
                
                Invoke-WebRequest -Uri $inspectorUrl -OutFile $inspectorPath -UseBasicParsing
                Start-Process -FilePath $inspectorPath -Wait
                Write-Host "Appium Inspector installed" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# ===================== COMPLETION =====================
Write-Host "`n=== SETUP COMPLETED ===" -ForegroundColor Green
