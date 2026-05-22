# Shared PPTX -> slide folders (PNG render + audio from package).
# Prefer PowerPoint COM so vector/text slides export correctly (not just embedded media icons).

function Get-AudioDurationSec([string]$path) {
  $ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
  if (-not $ffprobe) { return 3.0 }
  $raw = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $path 2>$null
  $sec = [double]$raw
  if ($sec -le 0) { return 3.0 }
  return [math]::Round($sec, 2)
}

function Extract-ZipPptx([string]$pptxPath) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $tempRoot = Join-Path $env:TEMP "pptx_export_$([guid]::NewGuid().ToString('N'))"
  $zipCopy = "$tempRoot.zip"
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
  Copy-Item -LiteralPath $pptxPath -Destination $zipCopy -Force
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zipCopy, $tempRoot)
  return @{ Root = $tempRoot; ZipCopy = $zipCopy }
}

function Get-SlideAudioFromZip([string]$zipRoot, [string]$slideXmlName) {
  $relsPath = Join-Path $zipRoot "ppt\slides\_rels\$slideXmlName.rels"
  if (-not (Test-Path $relsPath)) { return @{ Path = $null; DurationSec = 3.0 } }
  $rels = Get-Content $relsPath -Raw -Encoding UTF8
  if ($rels -notmatch 'media/(media\d+\.m4a)') {
    return @{ Path = $null; DurationSec = 3.0 }
  }
  $audioSrc = Join-Path $zipRoot "ppt\media\$($matches[1])"
  if (-not (Test-Path $audioSrc)) {
    return @{ Path = $null; DurationSec = 3.0 }
  }
  return @{ Path = $audioSrc; DurationSec = (Get-AudioDurationSec $audioSrc) }
}

function Copy-EmbeddedSlideImages([string]$zipRoot, [string]$slideXmlName, [string]$slideOut) {
  $relsPath = Join-Path $zipRoot "ppt\slides\_rels\$slideXmlName.rels"
  if (-not (Test-Path $relsPath)) { return 0 }
  $rels = Get-Content $relsPath -Raw -Encoding UTF8
  $imgIndex = 0
  foreach ($m in [regex]::Matches($rels, 'media/(image\d+\.(?:png|jpeg|jpg))')) {
    $src = Join-Path $zipRoot "ppt\media\$($m.Groups[1].Value)"
    if (-not (Test-Path $src)) { continue }
    $ext = [IO.Path]::GetExtension($src).ToLower()
    $destName = if ($imgIndex -eq 0) { "image$ext" } else { "image_$imgIndex$ext" }
    Copy-Item $src (Join-Path $slideOut $destName) -Force
    $imgIndex++
  }
  return $imgIndex
}

function Test-PowerPointAvailable {
  try {
    $ppt = New-Object -ComObject PowerPoint.Application -ErrorAction Stop
    $ppt.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Export-PptxPackage {
  param(
    [Parameter(Mandatory = $true)][string]$PptxPath,
    [Parameter(Mandatory = $true)][string]$PackageDir,
    [Parameter(Mandatory = $true)][string]$PackageId,
    [switch]$PreferPowerPointRender
  )

  $packageRoot = [System.IO.Path]::GetFullPath($PackageDir)
  $pkgDir = Join-Path $packageRoot "packages\$PackageId"
  if (Test-Path $pkgDir) { Remove-Item $pkgDir -Recurse -Force }
  New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null
  $PptxPath = [System.IO.Path]::GetFullPath($PptxPath)

  $zip = Extract-ZipPptx $PptxPath
  $zipRoot = $zip.Root
  $slidesDir = Join-Path $zipRoot "ppt\slides"
  $slideFiles = Get-ChildItem $slidesDir -Filter "slide*.xml" -ErrorAction SilentlyContinue |
    Sort-Object { [int]($_.BaseName -replace '\D', '') }

  $usePpt = $PreferPowerPointRender -and (Test-PowerPointAvailable)
  $pptApp = $null
  $presentation = $null

  if ($usePpt) {
    try {
      $pptApp = New-Object -ComObject PowerPoint.Application
      try { $pptApp.Visible = 1 } catch { }
      $presentation = $pptApp.Presentations.Open($PptxPath, $true, $true, $false)
      if ($presentation.Slides.Count -ne $slideFiles.Count) {
        Write-Warning "Slide count mismatch COM=$($presentation.Slides.Count) zip=$($slideFiles.Count) for $PackageId"
      }
    } catch {
      Write-Warning "PowerPoint render unavailable, falling back to embedded media: $_"
      $usePpt = $false
      if ($presentation) { $presentation.Close() | Out-Null }
      if ($pptApp) { $pptApp.Quit() | Out-Null }
      $presentation = $null
      $pptApp = $null
    }
  }

  $slideManifests = @()
  $idx = 0
  foreach ($slideFile in $slideFiles) {
    $idx++
    $num = '{0:D3}' -f $idx
    $slideOut = Join-Path $pkgDir "slide_$num"
    New-Item -ItemType Directory -Path $slideOut -Force | Out-Null

    $imgCount = 0
    if ($usePpt -and $idx -le $presentation.Slides.Count) {
      $pngPath = [System.IO.Path]::GetFullPath((Join-Path $slideOut "image.png"))
      try {
        $presentation.Slides.Item($idx).Export($pngPath, "PNG", 1920, 1080)
        if ((Test-Path $pngPath) -and (Get-Item $pngPath).Length -gt 8000) {
          $imgCount = 1
        } else {
          Remove-Item $pngPath -Force -ErrorAction SilentlyContinue
        }
      } catch {
        Write-Warning "Slide $idx export failed: $_"
      }
    }

    if ($imgCount -eq 0) {
      $imgCount = Copy-EmbeddedSlideImages $zipRoot $slideFile.Name $slideOut
    }

    $audio = Get-SlideAudioFromZip $zipRoot $slideFile.Name
    if ($audio.Path) {
      Copy-Item $audio.Path (Join-Path $slideOut "audio.m4a") -Force
    }

    $slideManifests += @{
      index       = $idx
      folder      = "packages/$PackageId/slide_$num"
      durationSec = $audio.DurationSec
      imageCount  = $imgCount
    }
  }

  if ($presentation) { $presentation.Close() | Out-Null }
  if ($pptApp) {
    $pptApp.Quit() | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($pptApp) | Out-Null
  }

  Remove-Item $zip.Root -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item $zip.ZipCopy -Force -ErrorAction SilentlyContinue

  return $slideManifests
}
