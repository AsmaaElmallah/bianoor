# Inserts visual_pubspec_assets.yaml lines into pubspec.yaml (once).
$pubspec = Join-Path $PSScriptRoot "..\pubspec.yaml"
$assetYaml = Join-Path $PSScriptRoot "visual_pubspec_assets.yaml"
if (-not (Test-Path $assetYaml)) {
  Write-Error "Run generate_visual_pubspec_assets.ps1 first"
}
$marker = "    - assets/visual/manifest.json"
$content = Get-Content $pubspec -Raw -Encoding UTF8
if ($content -match [regex]::Escape($marker)) {
  Write-Host "pubspec already contains visual assets"
  exit 0
}
$lines = Get-Content $assetYaml -Encoding UTF8
$insert = ($lines -join "`n") + "`n"
# Insert before closing of assets: (last math slide or assets/audio)
if ($content -notmatch '(?ms)(  assets:\r?\n)') {
  Write-Error "Could not find assets: section"
}
# Append at end of file before last blank lines - find last "    - assets/math" or add after assets section
$lastMath = [regex]::Matches($content, '    - assets/math/packages/[^\r\n]+')
if ($lastMath.Count -gt 0) {
  $pos = $lastMath[$lastMath.Count - 1].Index + $lastMath[$lastMath.Count - 1].Length
  $newContent = $content.Insert($pos, "`n$insert")
} else {
  $newContent = $content + "`n$insert"
}
Set-Content $pubspec $newContent -Encoding UTF8 -NoNewline
Write-Host "Merged $($lines.Count) visual asset lines into pubspec.yaml"
