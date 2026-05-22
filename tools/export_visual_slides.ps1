# Export tahfeez-basary PPTX -> bayanour/assets/visual (ordered visual_src_01..18)
param(
  [string]$SourceDir = (Resolve-Path (Join-Path $PSScriptRoot "..\..\tahfeez-basary")).Path,
  [string]$OutDir = (Join-Path $PSScriptRoot "..\assets\visual"),
  [switch]$SkipPowerPointRender
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "pptx_export_common.ps1")
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Day-range wildcards in filenames (stable without Arabic regex in console).
function Get-LessonSortKey([string]$fileName) {
  switch -Wildcard ($fileName) {
    '*0-5*' { return 1 }
    '*6-10*' { return 2 }
    '*21-30*' { return 3 }
    '*16-20*' { return 4 }
    '*21-25*' { return 5 }
    '*26-30*' { return 6 }
    '*31-35*' { return 7 }
    '*36-40*' { return 8 }
    '*46-50*' { return 9 }
    '*51-55*' { return 10 }
    '*55-60*' { return 11 }
    '*61-66*' { return 12 }
    '*67-72*' { return 13 }
    '*73-78*' { return 14 }
    '*79-85*' { return 15 }
    '*86-91*' { return 16 }
    '*18.pptx' { return 18 }
    default { return 17 }
  }
}

function Export-Pptx([string]$pptxPath, [string]$packageId) {
  $slides = Export-PptxPackage -PptxPath $pptxPath -PackageDir $OutDir -PackageId $packageId `
    -PreferPowerPointRender:(-not $SkipPowerPointRender)
  return @{
    id         = $packageId
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

function Get-PptxSlideCount([string]$pptxPath) {
  $zip = [System.IO.Compression.ZipFile]::OpenRead($pptxPath)
  $count = ($zip.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide[0-9]+\.xml$' }).Count
  $zip.Dispose()
  return $count
}

$all = Get-ChildItem $SourceDir -Filter "*.pptx" -File | Where-Object { $_.Name -notlike '~$*' }
$main = $all | Where-Object { (Get-LessonSortKey $_.Name) -le 16 } | Sort-Object { Get-LessonSortKey $_.Name }
$tail = $all | Where-Object { (Get-LessonSortKey $_.Name) -ge 17 }
$tailOrdered = $tail | Sort-Object { Get-PptxSlideCount $_.FullName }
# 49 slides = lesson 18, 72 slides = lesson 17
$files = @($main) + @($tailOrdered[1]) + @($tailOrdered[0])

$packages = @()
$lessonNum = 0
foreach ($f in $files) {
  $lessonNum++
  $id = 'visual_src_{0:D2}' -f $lessonNum
  Write-Host "Exporting [$id]: $($f.Name) ($(Get-PptxSlideCount $f.FullName) slides)"
  $packages += Export-Pptx $f.FullName $id
}

$manifest = @{ version = 1; packages = $packages }
$jsonPath = Join-Path $OutDir "manifest.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content $jsonPath -Encoding UTF8
$totalSlides = ($packages | ForEach-Object { $_.slideCount } | Measure-Object -Sum).Sum
Write-Host "Done. Packages: $($packages.Count). Slides: $totalSlides"
