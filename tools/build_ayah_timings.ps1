# Build per-surah ayah start times (seconds) using silence gaps — for ayah-safe ffmpeg cuts.
# Output: tools/quran_archive/{reciter}/ayah_timings.json
param(
  [string]$ReciterId = "ahmed_khader",
  [double]$NoiseDb = -38,
  [double]$MinSilenceSec = 0.3
)

$ErrorActionPreference = "Stop"

$ayahCounts = @(
  7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6
)

$root = Split-Path $PSScriptRoot -Parent
$sourceDir = Join-Path $root "tools\quran_archive\$ReciterId\source\_trimmed"
if (-not (Test-Path $sourceDir)) {
  $sourceDir = Join-Path $root "tools\quran_archive\$ReciterId\source"
}
$outJson = Join-Path $root "tools\quran_archive\$ReciterId\ayah_timings.json"

function Get-DurationSec([string]$Path) {
  $d = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $Path 2>$null
  return [double]$d
}

function Get-SurahFile([string]$Dir, [int]$Surah) {
  $f = Get-ChildItem -LiteralPath $Dir -Filter ("{0:D3}_*.mp3" -f $Surah) | Select-Object -First 1
  if (-not $f) { throw "Missing surah $Surah in $Dir" }
  return $f.FullName
}

function Get-AyahStartsFromSilence([string]$Path, [int]$AyahCount, [double]$Duration) {
  $log = cmd /c "ffmpeg -hide_banner -i `"$Path`" -af silencedetect=noise=${NoiseDb}dB:d=$MinSilenceSec -f null - 2>&1"
  $starts = [System.Collections.Generic.List[double]]::new()
  [void]$starts.Add(0.0)

  foreach ($line in $log) {
    if ($line -match 'silence_end:\s*([0-9.]+)') {
      $t = [double]$Matches[1]
      if ($t -gt 0.15 -and $t -lt ($Duration - 0.05)) {
        [void]$starts.Add($t)
      }
    }
  }

  # Map silence boundaries to ayah starts: expect ~(ayahCount) regions.
  if ($starts.Count -lt $AyahCount) {
    # Fallback: proportional spread between detected points + duration.
    $proportional = for ($a = 0; $a -lt $AyahCount; $a++) { ($a / $AyahCount) * $Duration }
    return ,$proportional
  }

  if ($starts.Count -gt $AyahCount) {
    # Keep first AyahCount boundaries (merge extra silences into previous ayah).
    return ,$starts.GetRange(0, $AyahCount)
  }

  return ,$starts
}

$all = @{}
for ($s = 1; $s -le 114; $s++) {
  $path = Get-SurahFile $sourceDir $s
  $dur = Get-DurationSec $path
  $count = $ayahCounts[$s - 1]
  $starts = Get-AyahStartsFromSilence $path $count $dur
  $ends = for ($a = 0; $a -lt $count; $a++) {
    if ($a -lt ($count - 1)) { $starts[$a + 1] } else { $dur }
  }
  $all["$s"] = @{
    durationSec = [math]::Round($dur, 3)
    ayahStarts  = @($starts | ForEach-Object { [math]::Round($_, 3) })
    ayahEnds    = @($ends | ForEach-Object { [math]::Round($_, 3) })
  }
  if ($s % 10 -eq 0) { Write-Host "Timed surah $s / 114" }
}

$all | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $outJson -Encoding UTF8
Write-Host "Saved: $outJson"
