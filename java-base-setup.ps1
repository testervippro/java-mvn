<#
.SYNOPSIS
    Complete development environment setup script with enhanced Node.js PATH handling
#>

# [Previous configuration and helper functions remain the same until Node.js section]

# ===================== NODE.JS INSTALLATION =====================
Write-Host "`n=== INSTALLING NODE.JS $nodeVersion ===" -ForegroundColor Cyan

$nodeUrl = "https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-x64.msi"
$nodeInstaller = "$env:TEMP\node-v$nodeVersion-x64.msi"
$nodeInstallPath = "C:\Program Files\nodejs"
$npmPath = "$env:APPDATA\npm"

function Test-NodeInPath {
    $path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    return $path -like "*$nodeInstallPath*" -and $path -like "*$npmPath*"
}

if (-not (Test-CommandExists "node")) {
    if (-not (Test-Path $nodeInstaller)) {
        if (-not (Invoke-SafeDownload $nodeUrl $nodeInstaller)) { Exit }
    }

    Write-Host "Installing Node.js..." -ForegroundColor Yellow
    if (Invoke-SafeInstall $nodeInstaller "/qn") {
        # Explicitly add Node.js and npm to PATH if not already present
        $pathModified = $false
        
        if (-not (Test-NodeInPath)) {
            # Add Node.js installation directory
            if (Add-ToSystemPath $nodeInstallPath) {
                $pathModified = $true
            }
            
            # Add npm global directory
            if (Add-ToSystemPath $npmPath) {
                $pathModified = $true
            }
        }

        if ($pathModified) {
            Write-Host "Node.js directories added to PATH" -ForegroundColor Green
            # Refresh PATH for current session
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + 
                        [System.Environment]::GetEnvironmentVariable("Path","User")
        }

        # Verify installation with retries
        $maxRetries = 3
        $retryCount = 0
        $nodeVerified = $false
        $npmVerified = $false
        
        while ($retryCount -lt $maxRetries) {
            Start-Sleep -Seconds 2  # Allow time for PATH changes to propagate
            
            Write-Host "`nVerifying installation (Attempt $($retryCount + 1))..." -ForegroundColor Yellow
            
            # Check Node.js
            try {
                $nodeVersionOutput = node -v 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "NODE VERSION: $($nodeVersionOutput.Trim())" -ForegroundColor Green
                    $nodeVerified = $true
                } else {
                    Write-Host "Node version check failed (Exit code: $LASTEXITCODE)" -ForegroundColor Red
                }
            } catch {
                Write-Host "Node version check error: $_" -ForegroundColor Red
            }
            
            # Check npm
            try {
                $npmVersionOutput = npm -v 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "NPM VERSION: $($npmVersionOutput.Trim())" -ForegroundColor Green
                    $npmVerified = $true
                } else {
                    Write-Host "npm version check failed (Exit code: $LASTEXITCODE)" -ForegroundColor Red
                }
            } catch {
                Write-Host "npm version check error: $_" -ForegroundColor Red
            }
            
            if ($nodeVerified -and $npmVerified) {
                break
            }
            
            $retryCount++
        }

        if (-not ($nodeVerified -and $npmVerified)) {
            Write-Host "`nNode.js installation verification failed after $maxRetries attempts" -ForegroundColor Red
            Write-Host "Possible solutions:" -ForegroundColor Yellow
            Write-Host "1. Restart your computer to ensure PATH changes take effect"
            Write-Host "2. Verify these directories exist and are in your PATH:"
            Write-Host "   - $nodeInstallPath"
            Write-Host "   - $npmPath"
            Write-Host "3. Check Node.js installation in Control Panel > Programs"
        }

        # Install Appium globally if requested
        if ($nodeVerified -and $npmVerified) {
            $installAppium = Read-Host "Install Appium globally? (Y/N)"
            if ($installAppium -match '^[Yy]') {
                Write-Host "Installing Appium..." -ForegroundColor Yellow
                npm install -g appium
                
                Write-Host "`nAPPIUM VERSION:" -ForegroundColor Cyan
                appium --version
            }
        }
    } else {
        Write-Host "Node.js installation failed. Please install manually." -ForegroundColor Red
    }
} else {
    Write-Host "Node.js is already installed:" -ForegroundColor Green
    node -v
    npm -v
}

# [Rest of the script remains the same]
