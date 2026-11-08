param([string]$Device = 'emulator-5554')
$ErrorActionPreference = 'Stop'
$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }
if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\sdk' }
$adb = Join-Path $sdk 'platform-tools\adb.exe'
if (-not (Test-Path $adb)) { throw 'Android SDK not found. Set ANDROID_HOME.' }
$disk = & $adb -s $Device shell df -k /data
if ($LASTEXITCODE -ne 0) { throw 'Cannot check device storage. Connect and unlock the Android device.' }
$row = @($disk | Where-Object { $_ -match '^/\S+\s+\d+\s+\d+\s+\d+' })
if ($row.Count -ne 1) { throw 'Cannot read Android free space. Installation stopped to protect existing data.' }
$columns = $row[0].Trim() -split '\s+'
$freeMb = [math]::Floor([double]$columns[3] / 1024)
# Reserve space for Android's low-storage threshold and installation staging.
# Flutter may otherwise fall back to uninstalling the existing application.
if ($freeMb -lt 700) {
    throw "Android has only $freeMb MB free. Free at least 700 MB before running Daryeel. Do not uninstall Daryeel, clear its storage, or wipe the emulator. Installation has not started."
}
Write-Host "Android storage check passed ($freeMb MB free)."
