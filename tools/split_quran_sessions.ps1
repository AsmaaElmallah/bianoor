# Split surah MP3s into 60 curriculum sessions for a reciter.
# Usage: place 001..114 surah mp3 files in source folder, then run:
#   powershell -File tools/split_quran_sessions.ps1 -ReciterId ahmed_khader

param(
  [string]$ReciterId = "ahmed_khader",
  [string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent)
)

$base = Join-Path $ProjectRoot "assets\audio\quran\$ReciterId"
$src = Join-Path $base "source"
$parts = Join-Path $base "parts"
New-Item -ItemType Directory -Force -Path $src, $parts | Out-Null

$mp3s = Get-ChildItem -LiteralPath $src -Filter "*.mp3" | Where-Object { $_.Name -notmatch '^full_quran' } | Sort-Object Name
if ($mp3s.Count -lt 114) { throw "Expected 114 surah files in $src" }

$concatList = Join-Path $src "concat_list.txt"
$sb = New-Object System.Text.StringBuilder
foreach ($f in $mp3s) {
  $p = ($f.FullName -replace '\\','/') -replace "'","'\\''"
  [void]$sb.AppendLine("file '$p'")
}
[System.IO.File]::WriteAllText($concatList, $sb.ToString())

$full = Join-Path $src "full_quran.mp3"
ffmpeg -y -f concat -safe 0 -i $concatList -c copy $full
ffmpeg -y -i $full -f segment -segment_time 900 -reset_timestamps 1 -c copy (Join-Path $parts "part_%03d.mp3")

$partFiles = Get-ChildItem -LiteralPath $parts -Filter "part_*.mp3" | Sort-Object Name
$sessionCount = 60
$perSession = [math]::Ceiling($partFiles.Count / $sessionCount)
for ($s = 1; $s -le $sessionCount; $s++) {
  $start = ($s - 1) * $perSession
  $group = $partFiles[$start..([math]::Min($start + $perSession - 1, $partFiles.Count - 1))]
  if ($group.Count -eq 0) { break }
  $listPath = Join-Path $base "session_${s}_list.txt"
  $sb2 = New-Object System.Text.StringBuilder
  foreach ($f in $group) {
    $p = ($f.FullName -replace '\\','/') -replace "'","'\\''"
    [void]$sb2.AppendLine("file '$p'")
  }
  [System.IO.File]::WriteAllText($listPath, $sb2.ToString())
  $out = Join-Path $base ("session_{0:D2}.mp3" -f $s)
  ffmpeg -y -f concat -safe 0 -i $listPath -c copy $out
  Remove-Item $listPath -Force
}

Write-Host "Created 60 sessions in $base"
