# Export math PPTX slides to bayanour/assets/math for Flutter.
# Requires: ffprobe on PATH; Microsoft PowerPoint for full slide PNG render.
param(
  [string]$SourceDir = (Resolve-Path (Join-Path $PSScriptRoot "..\..\math")).Path,
  [string]$OutDir = (Join-Path $PSScriptRoot "..\assets\math"),
  [switch]$SkipPowerPointRender
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "pptx_export_common.ps1")

function Get-PackageMeta([string]$fileName) {
  $n = $fileName
  if ($n -match 'الخرزات') {
    return @{ id = 'beads_numeric'; track = 'beadsNumeric'; dayStart = 0; dayEnd = 0; slideMode = 'cycle' }
  }
  if ($n -match '133-136|133') {
    return @{ id = 'dot_numeric_133_136'; track = 'dotNumeric'; dayStart = 133; dayEnd = 136; slideMode = 'cumulativeTail' }
  }
  if ($n -match 'الدرس 2|11-20') {
    return @{ id = 'q_11_20'; track = 'quantitative'; dayStart = 11; dayEnd = 20; slideMode = 'offsetEnd' }
  }
  if ($n -match 'الدرس الاول|١٠ايام|10ايام') {
    return @{ id = 'q_01_10'; track = 'quantitative'; dayStart = 1; dayEnd = 10; slideMode = 'twoDaysPerSlide' }
  }
  if ($n -match 'الثالث|٢٠-٣٠|20-30') {
    return @{ id = 'q_20_30'; track = 'quantitative'; dayStart = 20; dayEnd = 30; slideMode = 'offsetEnd' }
  }
  if ($n -match 'الرابع|٣٠-٤٠|30-40') {
    return @{ id = 'q_30_40'; track = 'quantitative'; dayStart = 30; dayEnd = 40; slideMode = 'offsetEnd' }
  }
  if ($n -match 'الخامس|٤١-٥٠|41-50') {
    return @{ id = 'q_41_50'; track = 'quantitative'; dayStart = 41; dayEnd = 50; slideMode = 'offsetEnd' }
  }
  if ($n -match 'السادس|٥١-٦٠|51-60') {
    return @{ id = 'q_51_60'; track = 'quantitative'; dayStart = 51; dayEnd = 60; slideMode = 'offsetEnd' }
  }
  if ($n -match 'السابع|٦١-٦٦|61-66') {
    return @{ id = 'q_61_66'; track = 'quantitative'; dayStart = 61; dayEnd = 66; slideMode = 'offsetEnd' }
  }
  if ($n -match 'الثامن|٦٧-٧٢|67-72') {
    return @{ id = 'q_67_72'; track = 'quantitative'; dayStart = 67; dayEnd = 72; slideMode = 'offsetEnd' }
  }
  if ($n -match 'التاسع|٧٣-٧٨|73-78') {
    return @{ id = 'q_73_78'; track = 'quantitative'; dayStart = 73; dayEnd = 78; slideMode = 'offsetEnd' }
  }
  if ($n -match 'العاشر|٧٩-٨٤|79-84') {
    return @{ id = 'q_79_84'; track = 'quantitative'; dayStart = 79; dayEnd = 84; slideMode = 'offsetEnd' }
  }
  if ($n -match 'الدرس 11|85-90') {
    return @{ id = 'q_85_90'; track = 'quantitative'; dayStart = 85; dayEnd = 90; slideMode = 'cumulativeTail' }
  }
  if ($n -match 'الدرس 12|91-95') {
    return @{ id = 'q_91_95'; track = 'quantitative'; dayStart = 91; dayEnd = 95; slideMode = 'cumulativeTail' }
  }
  if ($n -match 'الدرس 13|96-100') {
    return @{ id = 'q_96_100'; track = 'quantitative'; dayStart = 96; dayEnd = 100; slideMode = 'cumulativeTail' }
  }
  if ($n -match 'الدرس 14|101-105') {
    return @{ id = 'q_101_105'; track = 'quantitative'; dayStart = 101; dayEnd = 105; slideMode = 'cumulativeTail' }
  }
  if ($n -match 'الدرس 15|106-110') {
    return @{ id = 'q_106_110'; track = 'quantitative'; dayStart = 106; dayEnd = 110; slideMode = 'cumulativeTail' }
  }
  if ($n -match 'الدرس 16|111-115') {
    return @{ id = 'q_111_115'; track = 'quantitative'; dayStart = 111; dayEnd = 115; slideMode = 'cumulativeTail' }
  }
  if ($n -match 'الدرس 17|116-120') {
    return @{ id = 'q_116_120'; track = 'quantitative'; dayStart = 116; dayEnd = 120; slideMode = 'cumulativeTail' }
  }
  if ($n -match 'الدرس 18|121-124') {
    return @{ id = 'q_121_124'; track = 'quantitative'; dayStart = 121; dayEnd = 124; slideMode = 'cumulativeTail' }
  }
  if ($n -match 'الدرس 19|125-128') {
    return @{ id = 'q_125_128'; track = 'quantitative'; dayStart = 125; dayEnd = 128; slideMode = 'cumulativeTail' }
  }
  if ($n -match 'الدرس 20|129-132') {
    return @{ id = 'q_129_132'; track = 'quantitative'; dayStart = 129; dayEnd = 132; slideMode = 'cumulativeTail' }
  }
  $safe = ($fileName -replace '\.pptx$','' -replace '[^\w\-]+','_').Trim('_')
  return @{ id = $safe; track = 'quantitative'; dayStart = 0; dayEnd = 0; slideMode = 'sequential' }
}

function Export-Pptx([string]$pptxPath, [hashtable]$meta) {
  $slides = Export-PptxPackage -PptxPath $pptxPath -PackageDir $OutDir -PackageId $meta.id `
    -PreferPowerPointRender:(-not $SkipPowerPointRender)
  return @{
    id         = $meta.id
    track      = $meta.track
    dayStart   = $meta.dayStart
    dayEnd     = $meta.dayEnd
    slideMode  = $meta.slideMode
    sourceFile = [IO.Path]::GetFileName($pptxPath)
    slideCount = $slides.Count
    slides     = $slides
  }
}

if (-not (Test-Path $SourceDir)) {
  Write-Error "Source not found: $SourceDir"
}

if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$packages = @()
Get-ChildItem $SourceDir -Filter "*.pptx" -File | ForEach-Object {
  Write-Host "Exporting: $($_.Name)"
  $meta = Get-PackageMeta $_.Name
  $packages += Export-Pptx $_.FullName $meta
}

$manifest = @{ version = 1; packages = $packages }
$jsonPath = Join-Path $OutDir "manifest.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content $jsonPath -Encoding UTF8
Write-Host "Done. Packages: $($packages.Count). Output: $OutDir"
