# Renames non-ASCII package folders to ASCII ids and updates manifest.json.
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = Join-Path $PSScriptRoot "..\assets\math"
$packagesDir = Join-Path $root "packages"
$manifestPath = Join-Path $root "manifest.json"

# Map by matching known substrings (works regardless of console encoding).
$rules = @(
  @{ Match = "الخرزات"; New = "beads_numeric" }
  @{ Match = "الاول"; New = "lesson_01_10" }
  @{ Match = "الثالث"; New = "lesson_20_30" }
  @{ Match = "الرابع"; New = "lesson_30_40" }
  @{ Match = "الخامس"; New = "lesson_41_50" }
  @{ Match = "السادس"; New = "lesson_51_60" }
  @{ Match = "السابع"; New = "lesson_61_66" }
  @{ Match = "الثامن"; New = "lesson_67_72" }
  @{ Match = "التاسع"; New = "lesson_73_78" }
  @{ Match = "العاشر"; New = "lesson_79_84" }
)

$manifest = Get-Content $manifestPath -Raw -Encoding UTF8

Get-ChildItem $packagesDir -Directory | ForEach-Object {
  $name = $_.Name
  if ($name -match '^[a-z0-9_]+$') { return }
  foreach ($rule in $rules) {
    if ($name -notlike "*$($rule.Match)*") { continue }
    $dest = Join-Path $packagesDir $rule.New
    if ($_.FullName -eq $dest) { break }
    if (Test-Path $dest) {
      Write-Warning "Skip $($rule.New): already exists"
      break
    }
    Rename-Item -LiteralPath $_.FullName -NewName $rule.New
    Write-Host "Renamed -> $($rule.New)"
    $manifest = $manifest.Replace("packages/$name/", "packages/$($rule.New)/")
    $manifest = $manifest.Replace('"id":  "' + $name + '"', '"id":  "' + $rule.New + '"')
    break
  }
}

[System.IO.File]::WriteAllText($manifestPath, $manifest, [System.Text.UTF8Encoding]::new($false))
Write-Host "Updated manifest.json"
