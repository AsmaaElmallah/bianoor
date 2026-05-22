# Merges emotional_pubspec_assets.yaml into pubspec.yaml
$pubspec = Join-Path $PSScriptRoot "..\pubspec.yaml"
$assetsFile = Join-Path $PSScriptRoot "emotional_pubspec_assets.yaml"
if (-not (Test-Path $assetsFile)) {
  Write-Error "Run generate_emotional_pubspec_assets.ps1 first"
}
$lines = Get-Content $assetsFile -Encoding UTF8
$all = Get-Content $pubspec -Encoding UTF8
$filtered = $all | Where-Object { $_ -notmatch '^\s+-\s+assets/emotional/' }
$fontsIdx = ($filtered | Select-String -Pattern '^\s+fonts:' | Select-Object -First 1).LineNumber
if (-not $fontsIdx) {
  Write-Error "Could not find fonts: section in pubspec.yaml"
}
$before = $filtered[0..($fontsIdx - 2)]
$after = $filtered[($fontsIdx - 1)..($filtered.Length - 1)]
$newContent = ($before + $lines + $after) -join "`n"
Set-Content $pubspec $newContent -Encoding UTF8
Write-Host "Merged $($lines.Count) emotional asset lines into pubspec.yaml"
