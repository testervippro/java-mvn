# ===============================
# Uninstall Android SDK + Delete AVDs (Windows)
# ===============================

# SDK directory to delete
$androidSdkRoot = "C:\Android\android_sdk"

# =====================
# Kill SDK Processes
# =====================
Write-Host "🔫 Killing Android SDK-related processes..."
$processes = @("adb.exe", "emulator.exe", "qemu-system-x86_64.exe")
foreach ($proc in $processes) {
    try {
        taskkill /F /IM $proc | Out-Null
        Write-Host "✅ Killed: $proc"
    } catch {
        Write-Host "ℹ️ Could not kill or not running: $proc"
    }
}

Start-Sleep -Seconds 2

# =====================
# Remove SDK Directory
# =====================
Write-Host "`n🗑️ Removing SDK directory: $androidSdkRoot"
if (Test-Path $androidSdkRoot) {
    try {
        Remove-Item -Recurse -Force $androidSdkRoot
        Write-Host "✅ SDK directory removed"
    } catch {
        Write-Host "⚠️ Could not fully delete SDK directory:"
        Write-Host $_.Exception.Message
    }
} else {
    Write-Host "ℹ️ SDK directory not found"
}

# =====================
# Remove Env Variables
# =====================
Write-Host "`n🧼 Removing environment variables..."
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $null, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $null, "Machine")
Write-Host "✅ Removed ANDROID_HOME and ANDROID_SDK_ROOT"

# =====================
# Clean PATH
# =====================
Write-Host "`n🧹 Cleaning PATH entries..."
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }
$cleanedPath = $currentPath | Where-Object { $_ -notlike "$androidSdkRoot*" }
$newPath = ($cleanedPath | Select-Object -Unique) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "✅ Cleaned up PATH entries"

# =====================
# Delete AVDs (.android)
# =====================
$androidHome = Join-Path $env:USERPROFILE ".android"
$avdDir = Join-Path $androidHome "avd"

Write-Host "`n🗑️ Deleting AVDs from: $avdDir"
if (Test-Path $avdDir) {
    try {
        Remove-Item -Recurse -Force $avdDir
        Write-Host "✅ AVDs removed successfully"
    } catch {
        Write-Host "⚠️ Failed to delete AVDs:"
        Write-Host $_.Exception.Message
    }
} else {
    Write-Host "ℹ️ No AVDs found at: $avdDir"
}

# =====================
# Delete .android .ini Configs
# =====================
$configFiles = Get-ChildItem -Path $androidHome -Filter "*.ini" -ErrorAction SilentlyContinue
foreach ($file in $configFiles) {
    try {
        Remove-Item $file.FullName -Force
        Write-Host "🧹 Removed config: $($file.Name)"
    } catch {
        Write-Host "⚠️ Could not delete: $($file.Name)"
    }
}

# =====================
# Done!
# =====================
Write-Host "`n✅ Uninstallation Complete!"
Write-Host "🔁 Please restart PowerShell or your PC to apply environment changes."
