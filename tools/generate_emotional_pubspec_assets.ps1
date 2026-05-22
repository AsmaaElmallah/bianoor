# Writes emotional asset directory lines for pubspec.yaml
$root = Join-Path $PSScriptRoot "..\assets\emotional"
$lines = @("    - assets/emotional/manifest.json")
Get-ChildItem (Join-Path $root "packages") -Directory -ErrorAction SilentlyContinue |
  ForEach-Object {
    Get-ChildItem $_.FullName -Directory -Filter "slide_*" |
      ForEach-Object { $lines += "    - assets/emotional/packages/$($_.Parent.Name)/$($_.Name)/" }
  }
$out = Join-Path $PSScriptRoot "emotional_pubspec_assets.yaml"
$lines | Set-Content $out -Encoding UTF8
Write-Host "Wrote $($lines.Count) lines to $out"
