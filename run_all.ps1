# Runs the Django backend and Flutter frontend together.
# Usage: .\run_all.ps1 [-Release]

param(
    [switch]$Release,
    [ValidateSet('windows', 'chrome', 'edge', 'web-server')]
    [string]$Device = 'windows'
)

$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$backendPath = Join-Path $projectRoot 'backend'
$flutterPath = Join-Path $projectRoot 'flutter_app'
$pythonExe = Join-Path $backendPath 'venv\Scripts\python.exe'

if (!(Test-Path $pythonExe)) {
    Write-Error "Python virtualenv not found at $pythonExe. Run 'python -m venv venv' inside backend and install requirements."
}

if (!(Test-Path (Join-Path $flutterPath 'pubspec.yaml'))) {
    Write-Error "Flutter project not found at $flutterPath."
}

Write-Host "Starting Django backend..." -ForegroundColor Cyan

$backendProcess = Start-Process -FilePath $pythonExe -ArgumentList 'manage.py', 'runserver', '0.0.0.0:8000' -WorkingDirectory $backendPath -NoNewWindow -PassThru

Start-Sleep -Seconds 2

if ($Device -eq 'windows') {
    Write-Host "Ensuring no stale Flutter desktop processes..." -ForegroundColor Cyan
    Get-Process -Name 'flutter_app' -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $_.Kill()
            $_.WaitForExit()
        }
        catch {
            Write-Warning "Failed to terminate process $($_.Name): $_"
        }
    }

    $generatedPluginFile = Join-Path $flutterPath 'windows\flutter\generated_plugin_registrant.h'
    if (Test-Path $generatedPluginFile) {
        try {
            Remove-Item $generatedPluginFile -Force
        }
        catch {
            Write-Warning "Could not remove locked file $generatedPluginFile. Continuing..."
        }
    }
}

Write-Host "Launching Flutter app..." -ForegroundColor Cyan

Push-Location $flutterPath
try {
    $args = @('run', '-d', $Device)
    if ($Release) {
        $args += '--release'
    }
    flutter @args
}
finally {
    Pop-Location
    Write-Host "Stopping Django backend..." -ForegroundColor Yellow
    if ($backendProcess -and -not $backendProcess.HasExited) {
        try {
            $backendProcess.CloseMainWindow() | Out-Null
            if (-not $backendProcess.HasExited) {
                Start-Sleep -Seconds 1
                $backendProcess.Kill()
            }
        }
        catch {
            if (-not $backendProcess.HasExited) {
                $backendProcess.Kill()
            }
        }
        $backendProcess.WaitForExit()
    }
}

Write-Host "All processes stopped." -ForegroundColor Green

