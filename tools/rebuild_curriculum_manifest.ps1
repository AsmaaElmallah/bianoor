# Rebuilds manifest.json from existing packages/*/slide_* folders (math / visual / emotional).
param(
  [ValidateSet('math', 'visual', 'emotional', 'all')]
  [string]$Track = 'all'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'pptx_export_common.ps1')

function Get-ImageCount([string]$slideDir) {
  $n = @(Get-ChildItem $slideDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^image(_\d+)?\.(png|jpe?g)$' }).Count
  if ($n -gt 0) { return $n }
  return 1
}

function Build-ManifestForRoot([string]$assetsRoot) {
  $packagesDir = Join-Path $assetsRoot 'packages'
  if (-not (Test-Path $packagesDir)) {
    Write-Warning "Skip (no packages): $assetsRoot"
    return
  }

  $packages = [System.Collections.Generic.List[object]]::new()
  Get-ChildItem $packagesDir -Directory | Sort-Object Name | ForEach-Object {
    $pkgId = $_.Name
    $slides = [System.Collections.Generic.List[object]]::new()
    $idx = 0
    Get-ChildItem $_.FullName -Directory -Filter 'slide_*' | Sort-Object Name | ForEach-Object {
      $idx++
      $slideDir = $_.FullName
      $relFolder = "packages/$pkgId/$($_.Name)"
      $audioPath = Join-Path $slideDir 'audio.m4a'
      $dur = 3.0
      if (Test-Path $audioPath) {
        $dur = Get-AudioDurationSec $audioPath
      }
      $slides.Add([ordered]@{
          index       = $idx
          folder      = $relFolder
          durationSec = $dur
          imageCount  = (Get-ImageCount $slideDir)
        })
    }
    $packages.Add([ordered]@{
        id         = $pkgId
        slideCount = $slides.Count
        slides     = $slides
      })
  }

  $manifest = [ordered]@{ version = 1; packages = $packages }
  $jsonPath = Join-Path $assetsRoot 'manifest.json'
  $json = $manifest | ConvertTo-Json -Depth 12 -Compress:$false
  [System.IO.File]::WriteAllText($jsonPath, $json, [System.Text.UTF8Encoding]::new($false))
  Write-Host "Wrote $jsonPath ($($packages.Count) packages)"
}

$bayanour = Join-Path $PSScriptRoot '..'
$targets = if ($Track -eq 'all') { @('math', 'visual', 'emotional') } else { @($Track) }
foreach ($t in $targets) {
  Build-ManifestForRoot (Join-Path $bayanour "assets\$t")
}

Write-Host 'Done. Run: flutter pub get && flutter run (full restart).'
