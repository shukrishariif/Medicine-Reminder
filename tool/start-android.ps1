param([string]$Avd = 'my_avd', [int]$Port = 5554)
$ErrorActionPreference = 'Stop'
$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }
if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\sdk' }
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
if (-not (Test-Path $adb) -or -not (Test-Path $emulator)) {
    throw 'Android SDK not found. Set ANDROID_HOME to your SDK folder.'
}
$devices = & $adb devices
$device = "emulator-$Port"
if (-not ($devices -match "^$device\s")) {
    # Cold boot only; never wipe the virtual device or its app data.
    # The Android debug profile also enables Flutter software rendering.
    Start-Process -FilePath $emulator -ArgumentList '-avd', $Avd, '-port', $Port, '-no-snapshot', '-gpu', 'swiftshader_indirect', '-feature', '-Vulkan', '-no-audio' -WindowStyle Hidden
}
$deadline = (Get-Date).AddMinutes(3)
do {
    $devices = & $adb devices
    if ($devices -match "^$device\s+device\s*$") {
        $booted = ''
        try { $booted = & $adb -s $device shell getprop sys.boot_completed 2>$null } catch { }
        if ($booted -match '1') {
            & (Join-Path $PSScriptRoot 'check-android-storage.ps1') -Device $device
            Write-Host 'Android emulator is ready. Starting Daryeel.'
            exit 0
        }
    }
    Start-Sleep -Seconds 2
} while ((Get-Date) -lt $deadline)
throw 'Emulator did not boot within three minutes. Check Android Device Manager.'
