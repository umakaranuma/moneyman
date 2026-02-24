# Generate white-on-transparent PNG notification icons for Android.
# Run from project root: powershell -ExecutionPolicy Bypass -File scripts\gen_notification_icons.ps1
Add-Type -AssemblyName System.Drawing

$base = Join-Path $PSScriptRoot "..\android\app\src\main\res"
$sizes = @(
  @{d='drawable-mdpi'; w=24; h=24},
  @{d='drawable-hdpi'; w=36; h=36},
  @{d='drawable-xhdpi'; w=48; h=48},
  @{d='drawable-xxhdpi'; w=72; h=72},
  @{d='drawable-xxxhdpi'; w=96; h=96}
)

foreach ($s in $sizes) {
  $path = Join-Path $base $s.d
  if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
  $out = Join-Path $path "ic_notification.png"
  $bmp = New-Object System.Drawing.Bitmap($s.w, $s.h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
  $d = [Math]::Min($s.w, $s.h) * 0.4
  $r = $d / 2
  $cx = $s.w / 2
  $cy = $s.h / 2 - $s.h * 0.05
  $g.FillEllipse($brush, [float]($cx - $r), [float]($cy - $r), [float]$d, [float]$d)
  $font = New-Object System.Drawing.Font("Arial", [float]($s.h * 0.4), [System.Drawing.FontStyle]::Bold)
  $sf = New-Object System.Drawing.StringFormat
  $sf.Alignment = [System.Drawing.StringAlignment]::Center
  $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
  $rect = New-Object System.Drawing.RectangleF(0, 0, $s.w, $s.h)
  $g.DrawString("i", $font, $brush, $rect, $sf)
  $g.Dispose()
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Output "Created $out"
}
Write-Output "Done. Notification icons generated."
