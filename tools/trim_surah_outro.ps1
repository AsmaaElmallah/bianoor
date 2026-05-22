# Remove trailing site outro (e.g. "تم التنزيل من موقع نداء الإسلام") from per-surah MP3s.
# Writes trimmed copies to source_trimmed/ — originals are not modified.
param(
  [string]$ReciterId = "ahmed_khader",
  [double]$NoiseDb = -38,
  [double]$MinSilenceSec = 0.25,
  [double]$TailScanSec = 30
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$sourceDir = Join-Path $root "tools\quran_archive\$ReciterId\source"
if (-not (Test-Path $sourceDir)) {
  $sourceDir = Join-Path $root "assets\audio\quran\$ReciterId\source"
}
$outDir = Join-Path $sourceDir "_trimmed"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Get-DurationSec([string]$Path) {
  $d = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $Path 2>$null
  return [double]$d
}

function Get-SilenceEnds([string]$Path, [double]$FromSec) {
  $log = cmd /c "ffmpeg -hide_banner -ss $FromSec -i `"$Path`" -af silencedetect=noise=${NoiseDb}dB:d=$MinSilenceSec -f null - 2>&1"
  $ends = [System.Collections.Generic.List[double]]::new()
  foreach ($line in $log) {
    if ($line -match 'silence_end:\s*([0-9.]+)') {
      [void]$ends.Add([double]$Matches[1] + $FromSec)
    }
  }
  return $ends
}

Get-ChildItem -LiteralPath $sourceDir -Filter "*.mp3" -File | Where-Object { $_.Name -match '^\d{3}_' } | ForEach-Object {
  $src = $_.FullName
  $dur = Get-DurationSec $src
  if ($dur -lt 5) { return }

  $scanFrom = [math]::Max(0, $dur - $TailScanSec)
  $ends = Get-SilenceEnds $src $scanFrom

  # Last silence_end in the tail window ≈ end of Quran recitation before outro voice.
  $cutAt = $dur
  if ($ends.Count -gt 0) {
    $cutAt = $ends[-1]
    if ($cutAt -lt $dur * 0.5) { $cutAt = $dur }
  } else {
    # Fallback: drop last 12s if no silence detected (typical outro length).
    $cutAt = [math]::Max($dur - 12, $dur * 0.95)
  }

  $out = Join-Path $outDir $_.Name
  & ffmpeg -y -hide_banner -loglevel error -i $src -t $cutAt -c:a libmp3lame -q:a 4 $out
  if ($LASTEXITCODE -ne 0) { throw "trim failed: $src" }
  Write-Host ("{0}: {1:N1}s -> {2:N1}s" -f $_.Name, $dur, $cutAt)
}

Write-Host ""
Write-Host "Trimmed surahs: $outDir"
Write-Host "Point split scripts at source_trimmed (or copy files into source/)."
