# Regenera los PNG de ícono de la app en Windows sin rsvg-convert.
# Fuente: test/goldens/store-icon-512.png (arte real Flutter, paleta actual).
# Uso:  powershell -File scripts/regen_icons.ps1
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "test/goldens/store-icon-512.png"
$res = Join-Path $root "android/app/src/main/res"
$landing = Join-Path $root "landing/assets"
$bg = [System.Drawing.Color]::FromArgb(255, 7, 10, 17)   # nexoraBackground

if (-not (Test-Path $src)) { Write-Error "Falta $src"; exit 1 }

$source = [System.Drawing.Image]::FromFile($src)

function New-EmptyBitmap([int]$px, [bool]$alpha) {
    $fmt = if ($alpha) { [System.Drawing.Imaging.PixelFormat]::Format32bppArgb }
           else { [System.Drawing.Imaging.PixelFormat]::Format24bppRgb }
    $bmp = New-Object System.Drawing.Bitmap($px, $px, $fmt)
    return $bmp
}

function Resize-Into([System.Drawing.Image]$img, [int]$px) {
    $bmp = New-EmptyBitmap $px $false
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.Clear($bg)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $px, $px)
    $g.DrawImage($img, $rect)
    $g.Dispose()
    return $bmp
}

function Save-Transparent([System.Drawing.Image]$img, [string]$out, [bool]$toWhite) {
    $px = $img.Width
    $bmp = New-EmptyBitmap $px $true
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($img, 0, 0, $px, $px)
    $g.Dispose()
    for ($y = 0; $y -lt $px; $y++) {
        for ($x = 0; $x -lt $px; $x++) {
            $c = $bmp.GetPixel($x, $y)
            if ($c.A -gt 0 -and $c.R -eq 7 -and $c.G -eq 10 -and $c.B -eq 17) {
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            } elseif ($toWhite -and $c.A -gt 0) {
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($c.A, 255, 255, 255))
            }
        }
    }
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

$densities = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }

foreach ($d in $densities.GetEnumerator()) {
    $dir = Join-Path $res ("mipmap-" + $d.Key)
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $px = $d.Value
    $flat = Resize-Into $source $px
    $flat.Save((Join-Path $dir "ic_launcher.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $flat.Save((Join-Path $dir "ic_launcher_round.png"), [System.Drawing.Imaging.ImageFormat]::Png)

    $fg = New-EmptyBitmap $px $true
    $gf = [System.Drawing.Graphics]::FromImage($fg)
    $gf.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $safe = [math]::Round($px * 0.42)
    $rect = New-Object System.Drawing.Rectangle($safe, $safe, ($px - 2 * $safe), ($px - 2 * $safe))
    $gf.DrawImage($source, $rect)
    $gf.Dispose()
    for ($y = 0; $y -lt $px; $y++) {
        for ($x = 0; $x -lt $px; $x++) {
            $c = $fg.GetPixel($x, $y)
            if ($c.A -gt 0 -and $c.R -eq 7 -and $c.G -eq 10 -and $c.B -eq 17) {
                $fg.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            }
        }
    }
    $fg.Save((Join-Path $dir "ic_launcher_foreground.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $fg.Save((Join-Path $dir "ic_launcher_monochrome.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $fg.Dispose()

    $bgBmp = New-EmptyBitmap $px $false
    $gbg = [System.Drawing.Graphics]::FromImage($bgBmp)
    $gbg.Clear($bg)
    $gbg.Dispose()
    $bgBmp.Save((Join-Path $dir "ic_launcher_background.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bgBmp.Dispose()
    $flat.Dispose()
    Write-Host ("mipmap-{0} {1}x{1} ok" -f $d.Key, $px)
}

$drawable = Join-Path $res "drawable-nodpi"
New-Item -ItemType Directory -Force -Path $drawable | Out-Null
$splash = New-EmptyBitmap 1024 $false
$gs = [System.Drawing.Graphics]::FromImage($splash)
$gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gs.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gs.Clear($bg)
$gs.DrawImage($source, 0, 0, 1024, 1024)
$gs.Dispose()
$splash.Save((Join-Path $drawable "nexora_splash_logo.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$splash.Dispose()

New-Item -ItemType Directory -Force -Path $landing | Out-Null
$source.Save((Join-Path $landing "icon-512.png"), [System.Drawing.Imaging.ImageFormat]::Png)

$source.Dispose()
Write-Host "OK"