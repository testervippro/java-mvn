# ===================== UNINSTALL JAVA JDK =====================
$javaHome = "C:\Program Files\Java\jdk-17"
$javaInstaller = "$env:USERPROFILE\Downloads\jdk-17-installer.exe"
if (Test-Path $javaHome) {
    Write-Host "Removing Java directory: $javaHome"
    Remove-Item -Recurse -Force $javaHome
}
if (Test-Path $javaInstaller) {
    Write-Host "Removing Java installer"
    Remove-Item -Force $javaInstaller
}
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $null, "Machine")
Write-Host "JAVA_HOME environment variable removed."

# ===================== UNINSTALL MAVEN =====================
$mavenInstallDir = "C:\Program Files\Apache\maven-3.9.9"
$mavenZip = "$env:USERPROFILE\Downloads\apache-maven-3.9.9-bin.zip"
if (Test-Path $mavenInstallDir) {
    Write-Host "Removing Maven directory: $mavenInstallDir"
    Remove-Item -Recurse -Force $mavenInstallDir
}
if (Test-Path $mavenZip) {
    Write-Host "Removing Maven ZIP"
    Remove-Item -Force $mavenZip
}
[System.Environment]::SetEnvironmentVariable("MAVEN_HOME", $null, "Machine")
Write-Host "MAVEN_HOME environment variable removed."

# ===================== REMOVE JAVA AND MAVEN FROM SYSTEM PATH =====================
$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$filteredPath = ($systemPath -split ";") | Where-Object {
    ($_ -notlike "*jdk-17*") -and ($_ -notlike "*apache-maven*")
}
$newPath = ($filteredPath -join ";")
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "Removed Java and Maven paths from system PATH."

# ===================== UNINSTALL NODE.JS =====================
$nodeInstaller = "$env:USERPROFILE\Downloads\node-v20.12.2-x64.msi"
if (Test-Path $nodeInstaller) {
    Write-Host "Removing Node.js installer"
    Remove-Item -Force $nodeInstaller
}
$nodePath = "${env:ProgramFiles}\nodejs"
if (Test-Path $nodePath) {
    Write-Host "Removing Node.js directory: $nodePath"
    Remove-Item -Recurse -Force $nodePath
}

# ===================== UNINSTALL APPIUM AND TOOLS (if installed via npm) =====================
function Uninstall-NpmPackage($package) {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "Uninstalling $package globally..."
        try {
            npm uninstall -g $package
        } catch {
            Write-Host "Error uninstalling $package: $_"
        }
    }
}

Uninstall-NpmPackage "appium"
Uninstall-NpmPackage "appium-doctor"

# ===================== UNINSTALL APPIUM INSPECTOR (if manually downloaded) =====================
$appiumInspector = "$env:USERPROFILE\Downloads\Appium-Inspector-windows.exe"
if (Test-Path $appiumInspector) {
    Write-Host "Removing Appium Inspector executable"
    Remove-Item -Force $appiumInspector
}

# ===================== FINAL MESSAGE =====================
Write-Host "`nUninstallation completed. Please restart your computer to fully reset the environment."
