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
    try {
        Invoke-WebRequest -Uri $javaUrl -OutFile $javaInstaller
    } catch {
        Write-Host "Failed to download JDK installer. Error: $_"
        Exit
    }
} else {
    Write-Host "JDK installer already exists."
}

Write-Host "Installing Java..."
try {
    Start-Process -FilePath $javaInstaller -ArgumentList "/s" -NoNewWindow -Wait
    Write-Host "Java installation completed."
} catch {
    Write-Host "Failed to install Java. Error: $_"
    Exit
}

[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
Write-Host "JAVA_HOME set to $javaHome"

$javaBin = "$javaHome\bin"
$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$cleanPath = ($systemPath -split ";") | Where-Object { $_ -and ($_ -notlike "*jdk-17*") }
$newPath = ($cleanPath + $javaBin) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "Java bin added to system PATH"

Write-Host "`nJAVA VERSION:"
try {
    java -version
} catch {
    Write-Host "Java version check failed. Java may not be installed correctly."
}

# ===================== MAVEN INSTALLATION =====================
$mavenVersion = "3.9.9"
$mavenUrl = "https://dlcdn.apache.org/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip"
$mavenZip = "$env:USERPROFILE\Downloads\apache-maven-$mavenVersion-bin.zip"
$mavenInstallDir = "C:\Program Files\Apache\maven-$mavenVersion"
$mavenExtracted = "$mavenInstallDir\apache-maven-$mavenVersion"
$mavenBin = "$mavenExtracted\bin"

if (-Not (Test-Path $mavenZip)) {
    Write-Host "Downloading Maven..."
    try {
        Invoke-WebRequest -Uri $mavenUrl -OutFile $mavenZip
    } catch {
        Write-Host "Failed to download Maven. Error: $_"
        Exit
    }
} else {
    Write-Host "Maven zip already exists."
}

New-Item -ItemType Directory -Path $mavenInstallDir -Force | Out-Null
try {
    Expand-Archive -Path $mavenZip -DestinationPath $mavenInstallDir -Force
    Write-Host "Maven extracted to $mavenInstallDir"
} catch {
    Write-Host "Failed to extract Maven. Error: $_"
    Exit
}

[System.Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenExtracted, "Machine")
Write-Host "MAVEN_HOME set to $mavenExtracted"

$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$cleanPath = ($systemPath -split ";") | Where-Object { $_ -and ($_ -notlike "*apache-maven*") }
$newPath = ($cleanPath + $mavenBin) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "Maven bin added to system PATH"

Write-Host "`nMAVEN VERSION:"
try {
    mvn -version
} catch {
    Write-Host "Maven version check failed. Maven may not be installed correctly."
}

# ===================== OPTIONAL: NODE.JS + APPIUM SETUP =====================

# Ask if user wants to install Node.js
$installNode = Read-Host "Do you want to install Node.js (required for Appium)? (Y/N)"
if ($installNode -match '^[Yy]') {
    $nodeUrl = "https://nodejs.org/dist/v20.12.2/node-v20.12.2-x64.msi"
    $nodeInstaller = "$env:USERPROFILE\Downloads\node-v20.12.2-x64.msi"

    if (-Not (Test-Path $nodeInstaller)) {
        Write-Host "Downloading Node.js installer..."
        try {
            Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller
        } catch {
            Write-Host "Failed to download Node.js installer. Error: $_"
        }
    }

    Write-Host "Installing Node.js..."
    try {
        Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /qn /norestart" -Wait
        Write-Host "Node.js installed successfully."
    } catch {
        Write-Host "Failed to install Node.js. Error: $_"
    }

    Write-Host "`nNODE VERSION:"
    try {
        node -v
    } catch {
        Write-Host "Node version check failed. Node.js may not be installed correctly."
    }

    Write-Host "`nNPM VERSION:"
    try {
        npm -v
    } catch {
        Write-Host "NPM version check failed. Node.js may not be installed correctly."
    }

    # Ask if user wants to install Appium globally
    $installAppium = Read-Host "Do you want to install Appium globally using npm? (Y/N)"
    if ($installAppium -match '^[Yy]') {
        Write-Host "Installing Appium globally..."
        try {
            npm install -g appium
            Write-Host "Appium installed successfully."
        } catch {
            Write-Host "Failed to install Appium. Error: $_"
        }

        Write-Host "`nAPPIUM VERSION:"
        try {
            appium --version
        } catch {
            Write-Host "Appium version check failed. Appium may not be installed correctly."
        }
    } else {
        Write-Host "Skipping Appium installation."
    }

    # Ask if user wants to install Appium Inspector
    $installInspector = Read-Host "Do you want to install Appium Inspector (GUI for Windows 64-bit)? (Y/N)"
    if ($installInspector -match '^[Yy]') {
        $inspectorUrl = "https://github.com/appium/appium-inspector/releases/download/v2025.3.1/Appium-Inspector-2025.3.1-win-x64.exe"
        $inspectorPath = "$env:USERPROFILE\Downloads\Appium-Inspector-windows.exe"

        Write-Host "Downloading Appium Inspector..."
        try {
            Invoke-WebRequest -Uri $inspectorUrl -OutFile $inspectorPath
            Write-Host "Launching Appium Inspector installer..."
            Start-Process -FilePath $inspectorPath -Wait
        } catch {
            Write-Host "Failed to download or install Appium Inspector. Error: $_"
        }
    } else {
        Write-Host "Skipping Appium Inspector installation."
    }

    # Ask if user wants to install Appium Doctor
    $installDoctor = Read-Host "Do you want to install Appium Doctor (diagnostic tool)? (Y/N)"
    if ($installDoctor -match '^[Yy]') {
        Write-Host "Installing Appium Doctor..."
        try {
            npm install -g appium-doctor
            Write-Host "`nAPPIUM DOCTOR VERSION:"
            appium-doctor --version
            Write-Host "`nRunning Appium Doctor:"
            appium-doctor
        } catch {
            Write-Host "Failed to install or run Appium Doctor. Error: $_"
        }
    } else {
        Write-Host "Skipping Appium Doctor installation."
    }
} else {
    Write-Host "Skipping Node.js and Appium setup."
}

Write-Host "`nSetup completed! Please restart your computer for all changes to take effect."
