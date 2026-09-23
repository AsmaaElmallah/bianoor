# Build a debug APK, copy it to the phone and open the installer.
# Needed only after pubspec.yaml or android/ios changes; otherwise use .\attach.ps1
Set-Location $PSScriptRoot
$env:GRADLE_USER_HOME = "$env:USERPROFILE\.gradle"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

flutter build apk --debug --dart-define-from-file=dart_defines.json
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $adb push "build\app\outputs\flutter-apk\app-debug.apk" /sdcard/Download/bayanour.apk
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $adb shell am start -a android.intent.action.VIEW -d file:///sdcard/Download/bayanour.apk -t application/vnd.android.package-archive | Out-Null
Write-Host "Tap Install on the phone, then run .\attach.ps1" -ForegroundColor Green
