# Build 60 session MP3s (one per Quran hizb / half-juz) from 114 surah files.
param([string]$ReciterId = "ahmed_khader")

$ErrorActionPreference = "Stop"

$ayahCounts = @(
  7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6
)

# 30 juz start points; index 30 = end sentinel (after 114:6)
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

function Extract-AyahRange {
  param(
    [string]$Src, [string]$WorkDir, [int]$Surah,
    [int]$StartAyah, [int]$EndAyahExclusive
  )
  $total = $ayahCounts[$Surah - 1]
  if ($StartAyah -ge $EndAyahExclusive) { return $null }
  if ($StartAyah -eq 1 -and $EndAyahExclusive -eq ($total + 1)) { return $Src }

  $out = Join-Path $WorkDir ("clip_s{0:D3}_{1}_{2}.mp3" -f $Surah, $StartAyah, ($EndAyahExclusive - 1))
  if (Test-Path $out) { return $out }

  $dur = Get-DurationSec $Src
  $ss = ($StartAyah - 1) / $total * $dur
  $ee = ($EndAyahExclusive - 1) / $total * $dur
  & ffmpeg -y -hide_banner -loglevel error -ss $ss -to $ee -i $Src -acodec libmp3lame -q:a 4 $out
  if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed for $Src" }
  return $out
}

function Build-ClipsForHizb {
  param(
    [int]$StartSurah, [int]$StartAyah,
    [int]$EndSurah, [int]$EndAyah,
    [string]$SourceDir, [string]$WorkDir
  )
  $clips = [System.Collections.Generic.List[string]]::new()

  for ($surah = $StartSurah; $surah -le $EndSurah; $surah++) {
    $src = Get-SurahFile $SourceDir $surah
    $startA = if ($surah -eq $StartSurah) { $StartAyah } else { 1 }
    $endEx = if ($surah -eq $EndSurah) { $EndAyah } else { $ayahCounts[$surah - 1] + 1 }
    if ($startA -ge $endEx) { break }

    $clip = Extract-AyahRange -Src $src -WorkDir $WorkDir -Surah $surah -StartAyah $startA -EndAyahExclusive $endEx
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
  & ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i $lst -c copy $OutPath
  if ($LASTEXITCODE -ne 0) { throw "concat failed $OutPath" }
  Remove-Item $lst -Force
}

$root = Split-Path $PSScriptRoot -Parent
$sourceDir = Join-Path $root "tools\quran_archive\$ReciterId\source"
if (-not (Test-Path $sourceDir)) {
  $sourceDir = Join-Path $root "assets\audio\quran\$ReciterId\source"
}
$outDir = Join-Path $root "assets\audio\quran\$ReciterId"
$workDir = Join-Path $outDir "_work_hizb"
New-Item -ItemType Directory -Force -Path $workDir, $outDir | Out-Null

Get-ChildItem -LiteralPath $outDir -Filter "session_*.mp3" -ErrorAction SilentlyContinue | Remove-Item -Force
if (Test-Path $workDir) { Remove-Item -LiteralPath $workDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $workDir | Out-Null

$hizb = 1
for ($j = 0; $j -lt 30; $j++) {
  $g0 = Get-GlobalIndex -Surah $juzStarts[$j][0] -Ayah $juzStarts[$j][1]
  $g1 = Get-GlobalIndex -Surah $juzStarts[$j + 1][0] -Ayah $juzStarts[$j + 1][1]
  $midG = $g0 + [int][math]::Floor(($g1 - $g0) / 2)
  $mid = From-GlobalIndex -G $midG

  $pairs = @(
    @{ SS = $juzStarts[$j][0]; SA = $juzStarts[$j][1]; ES = $mid.Surah; EA = $mid.Ayah },
    @{ SS = $mid.Surah; SA = $mid.Ayah; ES = $juzStarts[$j + 1][0]; EA = $juzStarts[$j + 1][1] }
  )

  foreach ($p in $pairs) {
    $clips = Build-ClipsForHizb -StartSurah $p.SS -StartAyah $p.SA -EndSurah $p.ES -EndAyah $p.EA -SourceDir $sourceDir -WorkDir $workDir
    $out = Join-Path $outDir ("session_{0:D2}.mp3" -f $hizb)
    $fileList = @($clips)
    if ($clips -is [string]) { $fileList = @($clips) }
    elseif ($clips -is [System.Collections.Generic.List[string]]) { $fileList = $clips.ToArray() }
    Concat-Mp3 -Files $fileList -OutPath $out
    $mb = [math]::Round((Get-Item -LiteralPath $out).Length / 1MB, 2)
    $min = [math]::Round((Get-DurationSec $out) / 60, 1)
    Write-Host ("Hizb {0:D2}: {1}:{2} -> {3}:{4} | {5} clips | {6} MB | ~{7} min" -f $hizb, $p.SS, $p.SA, $p.ES, $p.EA, $clips.Count, $mb, $min)
    $hizb++
  }
}

Write-Host ""
Write-Host "Done: 60 hizb sessions in $outDir"
