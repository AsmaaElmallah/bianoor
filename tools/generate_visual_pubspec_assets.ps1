# Writes visual asset directory lines for pubspec.yaml
$root = Join-Path $PSScriptRoot "..\assets\visual"
$lines = @("    - assets/visual/manifest.json")
Get-ChildItem (Join-Path $root "packages") -Directory -ErrorAction SilentlyContinue |
  ForEach-Object {
    Get-ChildItem $_.FullName -Directory -Filter "slide_*" |
      ForEach-Object { $lines += "    - assets/visual/packages/$($_.Parent.Name)/$($_.Name)/" }
  }
$out = Join-Path $PSScriptRoot "visual_pubspec_assets.yaml"
$lines | Set-Content $out -Encoding UTF8
Write-Host "Wrote $($lines.Count) lines to $out"
