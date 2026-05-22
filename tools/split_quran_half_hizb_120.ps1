# Build 120 MP3s (half-hizb / rub' juz) from 114 surah source files.
# Cuts use ayah_timings.json (silence-based) so sessions never end mid-ayah.
# Run trim_surah_outro.ps1 + build_ayah_timings.ps1 first.
param([string]$ReciterId = "ahmed_khader")

$ErrorActionPreference = "Stop"

$ayahCounts = @(
  7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6
)

$juzStarts = @(
  @(1,1), @(2,142), @(2,253), @(3,93), @(4,24), @(4,148), @(5,82), @(6,111), @(7,88), @(8,41),
  @(9,93), @(11,6), @(12,53), @(15,1), @(17,1), @(18,75), @(21,1), @(23,1), @(25,21), @(27,56),
  @(29,46), @(33,31), @(36,28), @(39,32), @(41,47), @(46,1), @(51,31), @(58,1), @(67,1), @(78,1),
  @(114,7)
)

function Get-GlobalIndex {
  param([int]$Surah, [int]$Ayah)
  $g = $Ayah - 1
  for ($i = 0; $i -lt ($Surah - 1); $i++) { $g += $ayahCounts[$i] }
  return $g
}

function From-GlobalIndex {
  param([int]$G)
  $remaining = $G
  for ($si = 0; $si -lt 114; $si++) {
    if ($remaining -lt $ayahCounts[$si]) {
      return @{ Surah = $si + 1; Ayah = $remaining + 1 }
    }
    $remaining -= $ayahCounts[$si]
  }
  return @{ Surah = 114; Ayah = 7 }
}

function Get-SurahFile {
  param([string]$Dir, [int]$Surah)
  $f = Get-ChildItem -LiteralPath $Dir -Filter ("{0:D3}_*.mp3" -f $Surah) | Select-Object -First 1
  if (-not $f) { throw "Missing surah $Surah in $Dir" }
  return $f.FullName
}

function Get-DurationSec {
  param([string]$Path)
  $d = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $Path 2>$null
  return [double]$d
}

function Get-AyahTimeBounds {
  param([int]$Surah, [int]$StartAyah, [int]$EndAyahExclusive, [string]$Src, $Timings)
  $total = $ayahCounts[$Surah - 1]
  $key = "$Surah"
  $t = $null
  if ($Timings) { $t = $Timings.$key }
  if ($t) {
    $starts = @($t.ayahStarts)
    $ends = @($t.ayahEnds)
    if ($starts.Count -ge $total -and $ends.Count -ge $total) {
      $ss = $starts[$StartAyah - 1]
      $ee = if ($EndAyahExclusive -le $total) { $ends[$EndAyahExclusive - 1] } else { $ends[$total - 1] }
      return @{ SS = [double]$ss; EE = [double]$ee }
    }
  }
  $dur = Get-DurationSec $Src
  return @{
    SS = ($StartAyah - 1) / $total * $dur
    EE = ($EndAyahExclusive - 1) / $total * $dur
  }
}

function Extract-AyahRange {
  param(
    [string]$Src, [string]$WorkDir, [int]$Surah,
    [int]$StartAyah, [int]$EndAyahExclusive,
    $Timings
  )
  $total = $ayahCounts[$Surah - 1]
  if ($StartAyah -ge $EndAyahExclusive) { return $null }

  $out = Join-Path $WorkDir ("clip_s{0:D3}_{1}_{2}.mp3" -f $Surah, $StartAyah, ($EndAyahExclusive - 1))
  if (Test-Path $out) { return $out }

  $bounds = Get-AyahTimeBounds -Surah $Surah -StartAyah $StartAyah -EndAyahExclusive $EndAyahExclusive -Src $Src -Timings $Timings
  $ss = $bounds.SS
  $ee = $bounds.EE
  if ($ee -le $ss + 0.05) { throw "Invalid ayah window s$Surah a$StartAyah..$($EndAyahExclusive-1)" }

  & ffmpeg -y -hide_banner -loglevel error -ss $ss -to $ee -i $Src -acodec libmp3lame -q:a 4 $out
  if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed for $Src" }
  return $out
}

function Build-ClipsForRange {
  param(
    [int]$StartSurah, [int]$StartAyah,
    [int]$EndSurah, [int]$EndAyah,
    [string]$SourceDir, [string]$WorkDir,
    $Timings
  )
  $clips = [System.Collections.Generic.List[string]]::new()

  for ($surah = $StartSurah; $surah -le $EndSurah; $surah++) {
    $src = Get-SurahFile $SourceDir $surah
    $startA = if ($surah -eq $StartSurah) { $StartAyah } else { 1 }
    $endEx = if ($surah -eq $EndSurah) { $EndAyah } else { $ayahCounts[$surah - 1] + 1 }
    if ($startA -ge $endEx) { break }

    $clip = Extract-AyahRange -Src $src -WorkDir $WorkDir -Surah $surah -StartAyah $startA -EndAyahExclusive $endEx -Timings $Timings
    if ($clip) { [void]$clips.Add($clip) }
  }
  return $clips
}

function Concat-Mp3 {
  param([string[]]$Files, [string]$OutPath)
  if ($Files.Count -eq 0) { throw "No clips to concat for $OutPath" }
  if ($Files.Count -eq 1) {
    Copy-Item -LiteralPath $Files[0] -Destination $OutPath -Force
    return
  }
  $lst = "$OutPath.concat.txt"
  $lines = foreach ($f in $Files) {
    $p = ($f -replace '\\', '/') -replace "'", "'\''"
    "file '$p'"
  }
  [System.IO.File]::WriteAllText($lst, ($lines -join "`n"))
  # Re-encode so clips from different surah extractions mux reliably.
  & ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i $lst -c:a libmp3lame -q:a 4 $OutPath
  if ($LASTEXITCODE -ne 0) { throw "concat failed $OutPath" }
  Remove-Item $lst -Force
}

function Get-HizbPairs {
  $pairs = [System.Collections.Generic.List[hashtable]]::new()
  for ($j = 0; $j -lt 30; $j++) {
    $g0 = Get-GlobalIndex -Surah $juzStarts[$j][0] -Ayah $juzStarts[$j][1]
    $g1 = Get-GlobalIndex -Surah $juzStarts[$j + 1][0] -Ayah $juzStarts[$j + 1][1]
    $midG = $g0 + [int][math]::Floor(($g1 - $g0) / 2)
    $mid = From-GlobalIndex -G $midG

    [void]$pairs.Add(@{ SS = $juzStarts[$j][0]; SA = $juzStarts[$j][1]; ES = $mid.Surah; EA = $mid.Ayah })
    [void]$pairs.Add(@{ SS = $mid.Surah; SA = $mid.Ayah; ES = $juzStarts[$j + 1][0]; EA = $juzStarts[$j + 1][1] })
  }
  return $pairs
}

$root = Split-Path $PSScriptRoot -Parent
$archiveRoot = Join-Path $root "tools\quran_archive\$ReciterId"
$trimmedDir = Join-Path $archiveRoot "source\_trimmed"
$sourceDir = if (Test-Path $trimmedDir) { $trimmedDir } else { Join-Path $archiveRoot "source" }
if (-not (Test-Path $sourceDir)) {
  $sourceDir = Join-Path $root "assets\audio\quran\$ReciterId\source"
}
if (-not (Test-Path $sourceDir)) {
  throw "Surah source not found. Run trim_surah_outro.ps1 first."
}

$timingsPath = Join-Path $archiveRoot "ayah_timings.json"
$timings = $null
if (Test-Path $timingsPath) {
  $timings = Get-Content -LiteralPath $timingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Write-Host "Using ayah timings: $timingsPath"
} else {
  Write-Warning "ayah_timings.json missing - run build_ayah_timings.ps1 (cuts may be approximate)."
}

$outDir = Join-Path $root "assets\audio\quran\$ReciterId\half_hizb"
$workDir = Join-Path $outDir "_work"
$manifestPath = Join-Path $outDir "half_hizb_manifest.json"

New-Item -ItemType Directory -Force -Path $workDir, $outDir | Out-Null
Get-ChildItem -LiteralPath $outDir -Filter "session_*.mp3" -ErrorAction SilentlyContinue | Remove-Item -Force
if (Test-Path $workDir) { Remove-Item -LiteralPath $workDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $workDir | Out-Null

$hizbPairs = Get-HizbPairs
$manifest = [System.Collections.Generic.List[object]]::new()
$segment = 1

foreach ($hizbIndex in 1..$hizbPairs.Count) {
  $p = $hizbPairs[$hizbIndex - 1]
  $g0 = Get-GlobalIndex -Surah $p.SS -Ayah $p.SA
  $g1 = Get-GlobalIndex -Surah $p.ES -Ayah $p.EA
  $midG = $g0 + [int][math]::Floor(($g1 - $g0) / 2)
  $mid = From-GlobalIndex -G $midG

  $halves = @(
    @{ SS = $p.SS; SA = $p.SA; ES = $mid.Surah; EA = $mid.Ayah; Half = 1 },
    @{ SS = $mid.Surah; SA = $mid.Ayah; ES = $p.ES; EA = $p.EA; Half = 2 }
  )

  foreach ($half in $halves) {
    $clips = Build-ClipsForRange -StartSurah $half.SS -StartAyah $half.SA -EndSurah $half.ES -EndAyah $half.EA -SourceDir $sourceDir -WorkDir $workDir -Timings $timings
    $out = Join-Path $outDir ("session_{0:D3}.mp3" -f $segment)
    $fileList = @($clips)
    if ($clips -is [string]) { $fileList = @($clips) }
    elseif ($clips -is [System.Collections.Generic.List[string]]) { $fileList = $clips.ToArray() }
    Concat-Mp3 -Files $fileList -OutPath $out

    $sec = Get-DurationSec $out
    $mb = [math]::Round((Get-Item -LiteralPath $out).Length / 1MB, 2)
    $min = [math]::Round($sec / 60, 1)
    $mm = [int][math]::Floor($sec / 60)
    $ss = [int][math]::Round($sec % 60)

    $rangeStart = ('{0}:{1}' -f $half.SS, $half.SA)
    $rangeEndEx = ('{0}:{1}' -f $half.ES, $half.EA)
    $fileName = ('session_{0:D3}.mp3' -f $segment)
    $durationLabel = ('{0:D2}:{1:D2}' -f $mm, $ss)
    [void]$manifest.Add([ordered]@{
      segment     = $segment
      parentHizb  = $hizbIndex
      halfOfHizb  = $half.Half
      rangeStart  = $rangeStart
      rangeEndEx  = $rangeEndEx
      file        = $fileName
      durationSec = [math]::Round($sec, 1)
      duration    = $durationLabel
      sizeMb      = $mb
    })

    $msg = 'Seg {0:D3} (hizb {1} part {2}): {3}:{4} -> {5}:{6} - {7} MB - {8:D2}:{9:D2}' -f `
      $segment, $hizbIndex, $half.Half, $half.SS, $half.SA, $half.ES, $half.EA, $mb, $mm, $ss
    Write-Host $msg
    $segment++
  }
}

$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Host ""
Write-Host "Done: 120 half-hizb files in $outDir"
Write-Host "Manifest: $manifestPath"
Write-Host "Original 60 hizb files in assets\audio\quran\$ReciterId\session_*.mp3 are unchanged."
