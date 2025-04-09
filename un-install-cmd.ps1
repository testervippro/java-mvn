# ===============================
# Uninstall Android SDK (Windows)
# ===============================

$androidSdkRoot = "C:\Android\android_sdk"

Write-Host " Killing Android SDK-related processes..."
$processes = @("adb.exe", "emulator.exe", "qemu-system-x86_64.exe")
foreach ($proc in $processes) {
    try {
        taskkill /F /IM $proc | Out-Null
        Write-Host " Killed: $proc"
    } catch {
        Write-Host "ℹCould not kill or not running: $proc"
    }
}

Start-Sleep -Seconds 2

Write-Host "`n🗑️ Removing SDK directory: $androidSdkRoot"
try {
    Remove-Item -Recurse -Force $androidSdkRoot
    Write-Host "Removed SDK directory"
} catch {
    Write-Host "Could not fully delete SDK directory. You may need to remove it manually."
    Write-Host $_.Exception.Message
}

Write-Host "Removing environment variables..."
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $null, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $null, "Machine")
Write-Host "Removed ANDROID_HOME and ANDROID_SDK_ROOT"

Write-Host "Cleaning PATH entries..."
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }
$cleanedPath = $currentPath | Where-Object { $_ -notlike "$androidSdkRoot*" }
$newPath = ($cleanedPath | Select-Object -Unique) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "Cleaned up PATH entries"

Write-Host "Uninstallation Complete!"
Write-Host "Please restart PowerShell or your PC to apply environment changes"
