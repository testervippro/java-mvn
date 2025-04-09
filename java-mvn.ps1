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
