# تشغيل بيانور — يوجّه الملفات المؤقتة لقرص E: (C: غالباً ممتلئ)
$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path "E:\flutter_temp" | Out-Null
New-Item -ItemType Directory -Force -Path "E:\pub_cache" | Out-Null
New-Item -ItemType Directory -Force -Path "E:\gradle_home" | Out-Null

$env:TEMP = "E:\flutter_temp"
$env:TMP = "E:\flutter_temp"
$env:PUB_CACHE = "E:\pub_cache"
$env:GRADLE_USER_HOME = "E:\gradle_home"

Set-Location $PSScriptRoot

Write-Host "C: free:" ([math]::Round((Get-PSDrive C).Free / 1GB, 2)) "GB"
Write-Host "E: free:" ([math]::Round((Get-PSDrive E).Free / 1GB, 2)) "GB"
Write-Host "Running flutter with dart_defines.json ..."

flutter pub get
flutter run --dart-define-from-file=dart_defines.json @args
