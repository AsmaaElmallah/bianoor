# Attach to the manually installed debug app on the phone (hot reload without USB install).
# Usage: .\attach.ps1   then press R once, and r for hot reload.
Set-Location $PSScriptRoot
$env:GRADLE_USER_HOME = "$env:USERPROFILE\.gradle"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$appId = "com.bayanour.bayanour"

$wifiDevice = "192.168.1.18:5555"

& $adb start-server | Out-Null
& $adb connect $wifiDevice | Out-Null
$devices = & $adb devices | Select-String "`tdevice$"
$device = ($devices | Where-Object { $_.Line -like "*:*" } | Select-Object -First 1)
if (-not $device) { $device = $devices | Select-Object -First 1 }
if (-not $device) {
  Write-Host "Phone not connected. Plug USB, allow USB debugging, then retry." -ForegroundColor Yellow
  exit 1
}
$deviceId = ($device.Line -split "\s+")[0]

# Restart the app after attach starts listening, so it picks up the fresh VM service URL.
& $adb -s $deviceId shell am force-stop $appId | Out-Null
& $adb -s $deviceId logcat -c | Out-Null
Start-Job -ScriptBlock {
  param($adb, $deviceId, $appId)
  Start-Sleep -Seconds 6
  & $adb -s $deviceId shell monkey -p $appId -c android.intent.category.LAUNCHER 1 | Out-Null
} -ArgumentList $adb, $deviceId, $appId | Out-Null

flutter attach -d $deviceId --app-id $appId --dart-define-from-file=dart_defines.json @args
