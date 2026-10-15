param([string]$In, [string]$Out, [int]$Size = 256, [int]$Clear = 245, [int]$Spread = 235, [int]$Soft = 200)
# Removes a flat white background (flood fill from the borders) and resizes.
Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::FromFile($In)
$w = [Math]::Min($src.Width, 512); $h = [int]($src.Height * $w / $src.Width)
$bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($src, 0, 0, $w, $h); $g.Dispose(); $src.Dispose()

$rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, $bmp.PixelFormat)
$bytes = New-Object byte[] ($data.Stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
$stride = $data.Stride

function Whiteness([int]$i) {
  $b = $bytes[$i]; $gg = $bytes[$i + 1]; $r = $bytes[$i + 2]
  return [Math]::Min($r, [Math]::Min($gg, $b))
}

$seen = New-Object bool[] ($w * $h)
$queue = New-Object System.Collections.Generic.Queue[int]
for ($x = 0; $x -lt $w; $x++) { $queue.Enqueue($x); $queue.Enqueue(($h - 1) * $w + $x) }
for ($y = 0; $y -lt $h; $y++) { $queue.Enqueue($y * $w); $queue.Enqueue($y * $w + $w - 1) }

while ($queue.Count -gt 0) {
  $p = $queue.Dequeue()
  if ($seen[$p]) { continue }
  $seen[$p] = $true
  $x = $p % $w; $y = [int][Math]::Floor($p / $w)
  $i = $y * $stride + $x * 4
  $m = Whiteness $i
  if ($m -lt $Soft) { continue }
  # $Clear+ fully clear; $Soft..$Clear fades out to soften the edge.
  $alpha = if ($m -ge $Clear) { 0 } else { [int](255 * ($Clear - $m) / ($Clear - $Soft)) }
  if ($alpha -lt $bytes[$i + 3]) { $bytes[$i + 3] = [byte]$alpha }
  if ($m -lt $Spread) { continue }
  if ($x -gt 0) { $queue.Enqueue($p - 1) }
  if ($x -lt $w - 1) { $queue.Enqueue($p + 1) }
  if ($y -gt 0) { $queue.Enqueue($p - $w) }
  if ($y -lt $h - 1) { $queue.Enqueue($p + $w) }
}

[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $bytes.Length)
$bmp.UnlockBits($data)

$outBmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g2 = [System.Drawing.Graphics]::FromImage($outBmp)
$g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g2.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g2.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g2.DrawImage($bmp, 0, 0, $Size, $Size)
$g2.Dispose(); $bmp.Dispose()
$outBmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$outBmp.Dispose()
"saved $Out"
