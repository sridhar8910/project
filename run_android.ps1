# Runs the Django backend and Flutter frontend on Android (emulator or device).
# Usage: .\run_android.ps1 [-Release] [-Device <deviceId>] [-LanIp <ip>]

param(
    [switch]$Release,
    [string]$Device = "",
    [string]$LanIp = ""
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

if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter command not found in PATH. Ensure Flutter SDK is installed and added to PATH."
}

function Add-PathIfMissing {
    param(
        [string]$PathToAdd
    )

    if ([string]::IsNullOrWhiteSpace($PathToAdd)) {
        return
    }

    if (-not (Test-Path $PathToAdd)) {
        return
    }

    $pathParts = $env:PATH.Split([System.IO.Path]::PathSeparator)
    if ($pathParts -notcontains $PathToAdd) {
        $env:PATH = "$env:PATH$([System.IO.Path]::PathSeparator)$PathToAdd"
    }
}

function Ensure-AndroidTooling {
    $sdkRoot = if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
        $env:ANDROID_HOME
    } else {
        Join-Path $env:LOCALAPPDATA 'Android\Sdk'
    }

    if (-not (Test-Path $sdkRoot)) {
        Write-Warning "Android SDK root '$sdkRoot' not found. Ensure the Android SDK is installed."
    }

    $pathsToAdd = @(
        Join-Path $sdkRoot 'platform-tools'
        Join-Path $sdkRoot 'emulator'
        Join-Path $sdkRoot 'tools\bin'
    )

    foreach ($path in $pathsToAdd) {
        Add-PathIfMissing -PathToAdd $path
    }

    if (-not (Get-Command "adb" -ErrorAction SilentlyContinue)) {
        Write-Error "adb command not found. Install Android SDK platform-tools and ensure they are on PATH."
    }

    $script:AndroidSdkRoot = $sdkRoot
}

Ensure-AndroidTooling

function Get-AdbDevices {
    $devicesOutput = & adb devices 2>$null
    $lines = ($devicesOutput | Out-String).Trim().Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries)

    $devices = @()
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if (-not $trimmed) { continue }
        if ($trimmed -like 'List of devices*') { continue }

        $parts = $trimmed -split "\s+"
        if ($parts.Count -ge 2) {
            $devices += [PSCustomObject]@{
                Id     = $parts[0]
                Status = $parts[1]
            }
        }
    }

    return @($devices | Where-Object { $_.Status -eq 'device' })
}

function Get-DeviceDisplayName {
    param(
        [string]$DeviceId
    )

    if ([string]::IsNullOrWhiteSpace($DeviceId)) {
        return $DeviceId
    }

    try {
        $name = (& adb -s $DeviceId shell getprop ro.product.model 2>$null | Out-String).Trim()
        if (-not [string]::IsNullOrWhiteSpace($name)) {
            return $name
        }
    } catch {
    }

    return $DeviceId
}

function Ensure-AndroidTarget {
    param(
        [string]$Device
    )

    $sdkRoot = if ($script:AndroidSdkRoot) { $script:AndroidSdkRoot } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }

    if (-not [string]::IsNullOrWhiteSpace($Device)) {
        $connected = Get-AdbDevices
        $matched = $connected | Where-Object { $_.Id -eq $Device }
        if (-not $matched) {
            Write-Warning "Specified device '$Device' is not currently detected. Attempting to proceed, but the run may fail."
        }
        $name = Get-DeviceDisplayName -DeviceId $Device
        return [PSCustomObject]@{ Id = $Device; Name = $name }
    }

    $connectedDevices = Get-AdbDevices
    if ($connectedDevices.Count -gt 0) {
        $device = $connectedDevices[0]
        $name = Get-DeviceDisplayName -DeviceId $device.Id
        Write-Host "Using Android device: $name ($($device.Id))" -ForegroundColor Yellow
        return [PSCustomObject]@{ Id = $device.Id; Name = $name }
    }

    $emulatorExecutable = Join-Path $sdkRoot 'emulator\emulator.exe'
    if (-not (Test-Path $emulatorExecutable)) {
        throw "No Android device/emulator connected and emulator executable not found at '$emulatorExecutable'. Install the Android Emulator or connect a device."
    }

    $availableAvds = (& $emulatorExecutable -list-avds 2>$null | Out-String).Trim().Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries)
    if (-not $availableAvds -or $availableAvds.Count -eq 0) {
        throw "No Android device/emulator connected and no Android Virtual Devices configured. Create an AVD from Android Studio's Device Manager."
    }

    $avdName = $availableAvds[0].Trim()
    Write-Warning "No Android devices detected. Launching emulator '$avdName'..."
    Start-Process -FilePath $emulatorExecutable -ArgumentList @('-avd', $avdName) | Out-Null

    Write-Host "Waiting for emulator to come online..." -ForegroundColor Yellow
    & adb wait-for-device | Out-Null

    $maxAttempts = 120
    for ($attempt = 0; $attempt -lt $maxAttempts; $attempt++) {
        Start-Sleep -Seconds 2
        try {
            $bootCompleted = (& adb shell getprop sys.boot_completed 2>$null | Out-String).Trim()
            if ($bootCompleted -eq '1') {
                break
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    }

    if ($attempt -ge $maxAttempts) {
        throw "Emulator launch timed out after $($maxAttempts * 2) seconds."
    }

    $connectedDevices = Get-AdbDevices
    if ($connectedDevices.Count -eq 0) {
        throw "Emulator launched but no Android device detected over adb."
    }

    $device = $connectedDevices[0]
    $name = Get-DeviceDisplayName -DeviceId $device.Id
    Write-Host "Using Android device: $name ($($device.Id))" -ForegroundColor Yellow
    return [PSCustomObject]@{ Id = $device.Id; Name = $name }
}

$targetDevice = Ensure-AndroidTarget -Device $Device
$target = $targetDevice.Id

Write-Host "Starting Django backend..." -ForegroundColor Cyan

$backendProcess = Start-Process -FilePath $pythonExe -ArgumentList 'manage.py', 'runserver', '0.0.0.0:8000' -WorkingDirectory $backendPath -NoNewWindow -PassThru

Start-Sleep -Seconds 3

Write-Host "Preparing to launch Flutter on Android..." -ForegroundColor Cyan

$flutterArgs = @('run', '-d')

$flutterArgs += $target

if ($Release) {
    $flutterArgs += '--release'
}

if (-not [string]::IsNullOrWhiteSpace($LanIp)) {
    Write-Host "Using custom LAN IP for backend access: http://$LanIp:8000/api" -ForegroundColor Yellow
} else {
    Write-Host "No LAN IP provided. Defaulting backend base URL to emulator loopback (10.0.2.2)." -ForegroundColor Yellow
    $LanIp = "10.0.2.2"
}

$backendUrl = "http://$LanIp:8000/api"
$flutterArgs += "--dart-define=BACKEND_BASE_URL=$backendUrl"

Push-Location $flutterPath
try {
    flutter @flutterArgs
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