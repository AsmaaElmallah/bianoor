# Full rebuild: trim outros -> ayah timings -> 120 half-hizb sessions
param([string]$ReciterId = "ahmed_khader")

$ErrorActionPreference = "Stop"
$log = Join-Path $PSScriptRoot "pipeline_build.log"

function Write-Log([string]$Msg) {
  $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $Msg
  Write-Host $line
  Add-Content -LiteralPath $log -Value $line
}

"" | Set-Content -LiteralPath $log
Write-Log "Pipeline start (reciter: $ReciterId)"

$sw = [System.Diagnostics.Stopwatch]::StartNew()
& (Join-Path $PSScriptRoot "trim_surah_outro.ps1") -ReciterId $ReciterId
Write-Log ("Step 1 done trim: {0:N0} min" -f $sw.Elapsed.TotalMinutes)

& (Join-Path $PSScriptRoot "build_ayah_timings.ps1") -ReciterId $ReciterId
Write-Log ("Step 2 done timings: {0:N0} min" -f $sw.Elapsed.TotalMinutes)

& (Join-Path $PSScriptRoot "split_quran_half_hizb_120.ps1") -ReciterId $ReciterId
Write-Log ("Step 3 done sessions: {0:N0} min" -f $sw.Elapsed.TotalMinutes)

Write-Log "ALL COMPLETE"
Write-Log ("Total hours: {0:N1}" -f $sw.Elapsed.TotalHours)
