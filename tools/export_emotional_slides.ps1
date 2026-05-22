# Export zaka-egtmaa PPTX -> bayanour/assets/emotional (ordered emotional_src_01..32)
param(
  [string]$SourceDir = (Resolve-Path (Join-Path $PSScriptRoot "..\..\zaka-egtmaa")).Path,
  [string]$OutDir = (Join-Path $PSScriptRoot "..\assets\emotional"),
  [switch]$SkipPowerPointRender
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "pptx_export_common.ps1")

function Get-LessonSortKey([string]$fileName) {
  if ($fileName -match 'درس\s*(\d{1,2})') { return [int]$Matches[1] }
  $head = $fileName.Substring(0, [Math]::Min(100, $fileName.Length))
  foreach ($m in [regex]::Matches($head, '\d{1,2}')) {
    $n = [int]$m.Value
    if ($n -ge 1 -and $n -le 32) { return $n }
  }
  return 999
}

if (-not (Test-Path $SourceDir)) {
  Write-Error "Source not found: $SourceDir (place 32 PPTX files under zaka-egtmaa)"
}

if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$files = Get-ChildItem $SourceDir -Filter "*.pptx" -File |
  Where-Object { $_.Name -notlike '~$*' } |
  Sort-Object { Get-LessonSortKey $_.Name }

if ($files.Count -eq 0) {
  Write-Error "No PPTX files under $SourceDir"
}

$packages = @()
$lessonNum = 0
foreach ($f in $files) {
  $lessonNum++
  if ($lessonNum -gt 32) { break }
  $id = 'emotional_src_{0:D2}' -f $lessonNum
  Write-Host "Exporting [$id]: $($f.Name)"
  $slides = Export-PptxPackage -PptxPath $f.FullName -PackageDir $OutDir -PackageId $id `
    -PreferPowerPointRender:(-not $SkipPowerPointRender)
  $packages += @{
    id         = $id
    sourceFile = $f.Name
    slideCount = $slides.Count
    slides     = $slides
  }
}

$manifest = @{ version = 1; packages = $packages }
$jsonPath = Join-Path $OutDir "manifest.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content $jsonPath -Encoding UTF8
$totalSlides = ($packages | ForEach-Object { $_.slideCount } | Measure-Object -Sum).Sum
Write-Host "Done. Packages: $($packages.Count). Slides: $totalSlides (expected 162)"
