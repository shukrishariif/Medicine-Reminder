param([string]$Device = 'emulator-5556')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    python tool/check_supabase.py
    if ($LASTEXITCODE -ne 0) { throw 'Configure env.json before launching.' }
    & (Join-Path $PSScriptRoot 'check-android-storage.ps1') -Device $Device
    $runArgs = @('run', '-d', $Device, '--dart-define-from-file=env.json')
    if ($Device.StartsWith('emulator-')) { $runArgs += @('--no-enable-impeller', '--enable-software-rendering') }
    & flutter @runArgs
    if ($LASTEXITCODE -ne 0) { throw 'Flutter run failed; inspect the output above.' }
} finally { Pop-Location }
