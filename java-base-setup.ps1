<#
.SYNOPSIS
    Complete development environment setup script with proper error handling
.DESCRIPTION
    Installs Java, Maven, Node.js, npm, and Appium with proper PATH configuration
    and version verification. Includes comprehensive error handling.
#>

# ===================== CONFIGURATION =====================
$javaVersion = "17.0.12"
$mavenVersion = "3.9.9"
$nodeVersion = "20.19.0"
$appiumInspectorVersion = "2025.3.1"

# ===================== HELPER FUNCTIONS =====================
function Test-CommandExists {
    param($command)
    return (Get-Command $command -ErrorAction SilentlyContinue) -ne $null
}

function Add-ToSystemPath {
    param($path)
    $systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($systemPath -notlike "*$path*") {
        $newPath = $systemPath + ";" + $path
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Host "Added to PATH: $path" -ForegroundColor Green
        return $true
    }
    return $false
}

function Invoke-SafeDownload {
    param($url, $output)
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -ErrorAction Stop
        Write-Host "Downloaded: $output" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Download failed: $_" -ForegroundColor Red
        return $false
    }
}

function Invoke-SafeInstall {
    param($installer, $arguments)
    try {
        $process = Start-Process -FilePath $installer -ArgumentList $arguments -Wait -NoNewWindow -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Installer exited with code $($process.ExitCode)"
        }
        return $true
    } catch {
        Write-Host "Installation failed: $_" -ForegroundColor Red
        return $false
    }
}

# ===================== EXECUTION POLICY =====================
$currentPolicy = Get-ExecutionPolicy -Scope Process
if ($currentPolicy -notin @("RemoteSigned", "Unrestricted")) {
    Write-Host "Current Execution Policy: $currentPolicy" -ForegroundColor Yellow
    $policyChoice = Read-Host "Select policy to apply [R]emoteSigned or [U]nrestricted (R/U)?"
    switch ($policyChoice.ToUpper()) {
        "R" { Set-ExecutionPolicy RemoteSigned -Scope Process -Force }
        "U" { Set-ExecutionPolicy Unrestricted -Scope Process -Force }
        default { Write-Host "Invalid choice. Exiting."; Exit }
    }
}

# ===================== JAVA INSTALLATION =====================
Write-Host "`n=== INSTALLING JAVA JDK $javaVersion ===" -ForegroundColor Cyan

$javaUrl = "https://download.oracle.com/java/17/archive/jdk-${javaVersion}_windows-x64_bin.exe"
$javaInstaller = "$env:TEMP\jdk-${javaVersion}-installer.exe"
$javaHome = "C:\Program Files\Java\jdk-$javaVersion"

if (-not (Test-CommandExists "java")) {
    if (-not (Test-Path $javaInstaller)) {
        if (-not (Invoke-SafeDownload $javaUrl $javaInstaller)) { Exit }
    }

    Write-Host "Installing Java JDK..." -ForegroundColor Yellow
    if (Invoke-SafeInstall $javaInstaller "/s INSTALLDIR=`"$javaHome`"") {
        # Set environment variables
        [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
        Add-ToSystemPath "$javaHome\bin" | Out-Null
        
        # Verify installation
        Write-Host "`nJAVA VERSION:" -ForegroundColor Cyan
        java -version
    } else {
        Write-Host "Java installation failed. Please install manually." -ForegroundColor Red
    }
} else {
    Write-Host "Java is already installed:" -ForegroundColor Green
    java -version
}

# ===================== MAVEN INSTALLATION =====================
Write-Host "`n=== INSTALLING MAVEN $mavenVersion ===" -ForegroundColor Cyan

$mavenUrl = "https://dlcdn.apache.org/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip"
$mavenZip = "$env:TEMP\apache-maven-$mavenVersion-bin.zip"
$mavenInstallDir = "C:\Program Files\Apache\maven-$mavenVersion"

if (-not (Test-CommandExists "mvn")) {
    if (-not (Test-Path $mavenZip)) {
        if (-not (Invoke-SafeDownload $mavenUrl $mavenZip)) { Exit }
    }

    try {
        Expand-Archive -Path $mavenZip -DestinationPath $mavenInstallDir -Force
        $mavenHome = "$mavenInstallDir\apache-maven-$mavenVersion"
        
        # Set environment variables
        [System.Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenHome, "Machine")
        Add-ToSystemPath "$mavenHome\bin" | Out-Null
        
        # Verify installation
        Write-Host "`nMAVEN VERSION:" -ForegroundColor Cyan
        mvn -version
    } catch {
        Write-Host "Maven installation failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Maven is already installed:" -ForegroundColor Green
    mvn -version
}

# ===================== NODE.JS INSTALLATION =====================
Write-Host "`n=== INSTALLING NODE.JS $nodeVersion ===" -ForegroundColor Cyan

$nodeUrl = "https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-x64.msi"
$nodeInstaller = "$env:TEMP\node-v$nodeVersion-x64.msi"

if (-not (Test-CommandExists "node")) {
    if (-not (Test-Path $nodeInstaller)) {
        if (-not (Invoke-SafeDownload $nodeUrl $nodeInstaller)) { Exit }
    }

    Write-Host "Installing Node.js..." -ForegroundColor Yellow
    if (Invoke-SafeInstall $nodeInstaller "/qn") {
        # Refresh PATH to detect newly installed binaries
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Verify installation
        Write-Host "`nNODE.JS VERSION:" -ForegroundColor Cyan
        node -v
        
        Write-Host "`nNPM VERSION:" -ForegroundColor Cyan
        npm -v
        
        # Install Appium globally
        $installAppium = Read-Host "Install Appium globally? (Y/N)"
        if ($installAppium -match '^[Yy]') {
            Write-Host "Installing Appium..." -ForegroundColor Yellow
            npm install -g appium
            
            Write-Host "`nAPPIUM VERSION:" -ForegroundColor Cyan
            appium --version
        }
    } else {
        Write-Host "Node.js installation failed. Please install manually." -ForegroundColor Red
    }
} else {
    Write-Host "Node.js is already installed:" -ForegroundColor Green
    node -v
    npm -v
}

# ===================== APPIUM INSPECTOR =====================
$inspectorChoice = Read-Host "`nInstall Appium Inspector $appiumInspectorVersion? (Y/N)"
if ($inspectorChoice -match '^[Yy]') {
    $inspectorUrl = "https://github.com/appium/appium-inspector/releases/download/v$appiumInspectorVersion/Appium-Inspector-$appiumInspectorVersion-win-x64.exe"
    $inspectorInstaller = "$env:TEMP\Appium-Inspector.exe"
    
    if (Invoke-SafeDownload $inspectorUrl $inspectorInstaller) {
        Write-Host "Installing Appium Inspector..." -ForegroundColor Yellow
        Invoke-SafeInstall $inspectorInstaller "/S" | Out-Null
    }
}

# ===================== FINAL STEPS =====================
Write-Host "`n=== INSTALLATION COMPLETE ===" -ForegroundColor Green
Write-Host "Please restart your computer for all changes to take effect." -ForegroundColor Yellow
