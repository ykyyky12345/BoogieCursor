# Generate Boogie-theme cursor files (.cur / .ani)  v3
#  - Arrow        : Boogieing figure (chroma-keyed), NO flame
#  - IBeam/Hand   : unchanged
#  - Flame click  : Boogieing figure + animated flame on head, hotspot follows flame tip
#  - Busy         : Boogieing rocking dance + warm glow
#  - Tray icons   : dance frames
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$OutDir = Join-Path $PSScriptRoot 'Cursors'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$BoogieSrc = 'D:\我的下载\Boogieing.png'
if (-not (Test-Path $BoogieSrc)) { throw "missing $BoogieSrc" }

function New-Canvas {
    $bmp = New-Object System.Drawing.Bitmap(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    return @{ Bmp = $bmp; G = $g }
}

function Add-RoundRect {
    param($path, [double]$x, [double]$y, [double]$w, [double]$h, [double]$r)
    $d = 2 * $r
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc(($x + $w - $d), $y, $d, $d, 270, 90)
    $path.AddArc(($x + $w - $d), ($y + $h - $d), $d, $d, 0, 90)
    $path.AddArc($x, ($y + $h - $d), $d, $d, 90, 90)
    $path.CloseFigure()
}

function New-FlamePath {
    param([double]$cx, [double]$baseY, [double]$h, [double]$w, [double]$lean)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $lx = $cx - $w / 2.0; $rx = $cx + $w / 2.0
    $tx = $cx + $lean;    $ty = $baseY - $h
    $p.AddBezier($lx, $baseY, ($lx - $w * 0.08), ($baseY - $h * 0.45), ($tx - $w * 0.34), ($ty + $h * 0.28), $tx, $ty)
    $p.AddBezier($tx, $ty, ($tx + $w * 0.34), ($ty + $h * 0.28), ($rx + $w * 0.08), ($baseY - $h * 0.45), $rx, $baseY)
    $p.AddBezier($rx, $baseY, ($cx + 4), ($baseY + 3), ($cx - 4), ($baseY + 3), $lx, $baseY)
    $p.CloseFigure()
    return $p
}

function Draw-Flame {
    param($g, [double]$cx, [double]$baseY, [double]$h, [double]$w, [double]$lean, [double]$glowScale = 1.55)
    $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $gr = $w * $glowScale
    $gy = $baseY - $h * 0.55
    $gp.AddEllipse(($cx - $gr), ($gy - $gr), (2 * $gr), (2 * $gr))
    $pb = New-Object System.Drawing.Drawing2D.PathGradientBrush($gp)
    $pb.CenterColor = [System.Drawing.Color]::FromArgb(70, 255, 130, 0)
    $pb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 255, 130, 0))
    $g.FillPath($pb, $gp)
    $pb.Dispose(); $gp.Dispose()

    $rect = New-Object System.Drawing.RectangleF(([single]($cx - $w)), ([single]($baseY - $h)), ([single](2 * $w)), ([single]($h + 4)))
    $p1 = New-FlamePath $cx $baseY $h $w $lean
    $b1 = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(255, 255, 100, 0), [System.Drawing.Color]::FromArgb(255, 255, 190, 40), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $g.FillPath($b1, $p1); $b1.Dispose()
    $p2 = New-FlamePath $cx ($baseY + 1) ($h * 0.62) ($w * 0.6) ($lean * 0.55)
    $b2 = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(255, 255, 205, 60), [System.Drawing.Color]::FromArgb(255, 255, 245, 190), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $g.FillPath($b2, $p2); $b2.Dispose()
    $cw = $w * 0.34
    $coreRect = New-Object System.Drawing.RectangleF(([single]($cx - $cw / 2)), ([single]($baseY - $h * 0.22)), ([single]$cw), ([single]($h * 0.22)))
    $cb = New-Object System.Drawing.Drawing2D.GraphicsPath
    $cb.AddEllipse($coreRect)
    $b3 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, 150, 205, 255))
    $g.FillPath($b3, $cb)
    $b3.Dispose(); $cb.Dispose()
    $p1.Dispose(); $p2.Dispose()
}

function Invoke-ChromaKeyWhite {
    param($bmp)
    $r = New-Object System.Drawing.Rectangle(0, 0, $bmp.Width, $bmp.Height)
    $bd = $bmp.LockBits($r, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $len = $bd.Stride * $bmp.Height
    $px = New-Object byte[] $len
    [System.Runtime.InteropServices.Marshal]::Copy($bd.Scan0, $px, 0, $len)
    for ($i = 0; $i -lt $len; $i += 4) {
        $mn = [Math]::Min($px[$i + 2], [Math]::Min($px[$i + 1], $px[$i]))
        if ($mn -ge 235) { $px[$i + 3] = 0 }
        elseif ($mn -ge 180) { $px[$i + 3] = [byte]((235 - $mn) * 4) }
        else { $px[$i + 3] = 255 }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($px, 0, $bd.Scan0, $len)
    $bmp.UnlockBits($bd)
}

function Invoke-RemoveFlame {
    # erase the STATIC flame baked into the source artwork (warm colors, top region only)
    param($bmp, [int]$maxY)
    $w = $bmp.Width; $h = $bmp.Height
    $r = New-Object System.Drawing.Rectangle(0, 0, $w, [Math]::Min($h, $maxY))
    $bd = $bmp.LockBits($r, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $s = $bd.Stride; $rows = $r.Height
    $px = New-Object byte[] ($s * $rows)
    [System.Runtime.InteropServices.Marshal]::Copy($bd.Scan0, $px, 0, $px.Length)
    $mask = New-Object bool[] ($w * $rows)
    $removed = 0
    # pass 1: strong flame core
    for ($y = 0; $y -lt $rows; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $i = ($y * $s) + ($x * 4)
            $R = $px[$i + 2]; $G = $px[$i + 1]; $B = $px[$i]
            if ($R -gt 170 -and ($R - $B) -gt 70 -and $G -gt 50) { $mask[$y * $w + $x] = $true }
        }
    }
    # pass 2: halo dilation (2 iterations)
    for ($iter = 0; $iter -lt 2; $iter++) {
        $new = $mask.Clone()
        for ($y = 1; $y -lt ($rows - 1); $y++) {
            for ($x = 1; $x -lt ($w - 1); $x++) {
                if ($mask[$y * $w + $x]) { continue }
                $nb = $false
                foreach ($d in @(-1, 0, 1)) {
                    foreach ($e in @(-1, 0, 1)) {
                        if ($mask[($y + $d) * $w + ($x + $e)]) { $nb = $true; break }
                    }
                    if ($nb) { break }
                }
                if (-not $nb) { continue }
                $i = ($y * $s) + ($x * 4)
                $R = $px[$i + 2]; $G = $px[$i + 1]; $B = $px[$i]
                if (($R - $B) -gt 40 -and $R -gt 200) { $new[$y * $w + $x] = $true }
            }
        }
        $mask = $new
    }
    # pass 3: dark outline fragments surrounded by removed pixels
    for ($y = 1; $y -lt ($rows - 1); $y++) {
        for ($x = 1; $x -lt ($w - 1); $x++) {
            if ($mask[$y * $w + $x]) { continue }
            $i = ($y * $s) + ($x * 4)
            $mx = [Math]::Max($px[$i + 2], [Math]::Max($px[$i + 1], $px[$i]))
            if ($mx -ge 110) { continue }
            $cnt = 0
            foreach ($d in @(-1, 0, 1)) { foreach ($e in @(-1, 0, 1)) { if ($mask[($y + $d) * $w + ($x + $e)]) { $cnt++ } } }
            if ($cnt -ge 5) { $mask[$y * $w + $x] = $true }
        }
    }
    # apply
    for ($y = 0; $y -lt $rows; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            if ($mask[$y * $w + $x]) { $px[($y * $s) + ($x * 4) + 3] = 0; $removed++ }
        }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($px, 0, $bd.Scan0, $px.Length)
    $bmp.UnlockBits($bd)
    Write-Host ("  removed {0} static-flame pixels from source art" -f $removed)
}

function Shrink-To32 {
    param($bmp)
    $cur = $bmp
    $created = @()
    while ($cur.Width -gt 32) {
        $nw = [int]($cur.Width / 2)
        $nb = New-Object System.Drawing.Bitmap($nw, $nw, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($nb)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.DrawImage($cur, 0, 0, $nw, $nw)
        $g.Dispose()
        $created += $nb
        $cur = $nb
    }
    return @{ Result = $cur; Temp = $created }
}

function Get-CurBytes {
    param($bmp32, [int]$hx, [int]$hy)
    $rect = New-Object System.Drawing.Rectangle(0, 0, 32, 32)
    $bd = $bmp32.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $px = New-Object byte[] (32 * 32 * 4)
    [System.Runtime.InteropServices.Marshal]::Copy($bd.Scan0, $px, 0, $px.Length)
    $bmp32.UnlockBits($bd)
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $bw.Write([uint16]0); $bw.Write([uint16]2); $bw.Write([uint16]1)
    $bw.Write([byte]32); $bw.Write([byte]32); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([uint16]$hx); $bw.Write([uint16]$hy)
    $imgLen = 40 + 4096 + 128
    $bw.Write([uint32]$imgLen); $bw.Write([uint32]22)
    $bw.Write([uint32]40); $bw.Write([int32]32); $bw.Write([int32]64); $bw.Write([uint16]1); $bw.Write([uint16]32)
    $bw.Write([uint32]0); $bw.Write([uint32]4224); $bw.Write([int32]0); $bw.Write([int32]0); $bw.Write([uint32]0); $bw.Write([uint32]0)
    for ($y = 31; $y -ge 0; $y--) { $bw.Write($px, ($y * 128), 128) }
    $and = New-Object byte[] 128
    $bw.Write($and)
    $bw.Flush()
    $bytes = $ms.ToArray()
    $bw.Dispose(); $ms.Dispose()
    return $bytes
}

function Save-Ani {
    param($curFrames, [int]$jifRate, [string]$path)
    $fp = New-Object System.IO.MemoryStream
    $fw = New-Object System.IO.BinaryWriter($fp)
    foreach ($c in $curFrames) {
        $fw.Write([System.Text.Encoding]::ASCII.GetBytes('icon'))
        $fw.Write([uint32]$c.Length)
        $fw.Write([byte[]]$c)
    }
    $fw.Flush(); $framPayload = $fp.ToArray()
    $fw.Dispose(); $fp.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $enc = [System.Text.Encoding]::ASCII
    $riffSize = 4 + (8 + 36) + (8 + 4 + $framPayload.Length)
    $bw.Write($enc.GetBytes('RIFF')); $bw.Write([uint32]$riffSize)
    $bw.Write($enc.GetBytes('ACON'))
    $bw.Write($enc.GetBytes('anih')); $bw.Write([uint32]36)
    $bw.Write([uint32]36); $bw.Write([uint32]$curFrames.Count); $bw.Write([uint32]$curFrames.Count)
    $bw.Write([uint32]32); $bw.Write([uint32]32); $bw.Write([uint32]32); $bw.Write([uint32]1)
    $bw.Write([uint32]$jifRate); $bw.Write([uint32]1)
    $bw.Write($enc.GetBytes('LIST')); $bw.Write([uint32](4 + $framPayload.Length))
    $bw.Write($enc.GetBytes('fram'))
    $bw.Write($framPayload)
    $bw.Flush()
    [System.IO.File]::WriteAllBytes($path, $ms.ToArray())
    $bw.Dispose(); $ms.Dispose()
}

# ---- load figure: prefer bundled processed asset (portable), else process raw source ----
$assetPath = Join-Path $PSScriptRoot 'assets\Boogieing_processed.png'
if (Test-Path $assetPath) {
    $big = New-Object System.Drawing.Bitmap($assetPath)
    Write-Host 'using bundled processed figure asset'
} else {
    if (-not (Test-Path $BoogieSrc)) { throw "missing $BoogieSrc and no bundled asset" }
    $src = New-Object System.Drawing.Bitmap($BoogieSrc)
    $big = New-Object System.Drawing.Bitmap(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $bg = [System.Drawing.Graphics]::FromImage($big)
    $bg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $bg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $bg.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, 512, 512)), (New-Object System.Drawing.Rectangle(299, 259, 1749, 1749)), [System.Drawing.GraphicsUnit]::Pixel)
    $bg.Dispose(); $src.Dispose()
    Invoke-RemoveFlame $big 235
    Invoke-ChromaKeyWhite $big
    $assetDir = Split-Path $assetPath
    New-Item -ItemType Directory -Force -Path $assetDir | Out-Null
    $big.Save($assetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host 'processed figure asset saved for portable reuse'
}

# plain figure: tilted-pointer use, 190px tall (slightly bigger), flame base on head top
# figure aspect 1366/1749 = 0.781 -> 190 tall = 148.4 wide, centered x=128, top y=46
$figPlain = New-Canvas
$figPlain.G.DrawImage($big, 54, 46, 148, 190)

# glowing centered figure for busy/tray (also slightly bigger)
$figGlow = New-Canvas
$glowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$glowPath.AddEllipse(16, 16, 224, 224)
$pgb = New-Object System.Drawing.Drawing2D.PathGradientBrush($glowPath)
$pgb.CenterColor = [System.Drawing.Color]::FromArgb(80, 255, 150, 40)
$pgb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 255, 150, 40))
$figGlow.G.FillPath($pgb, $glowPath)
$pgb.Dispose(); $glowPath.Dispose()
$figGlow.G.DrawImage($big, 33, 33, 190, 190)
$big.Dispose()

# tilt: -28 deg around flame base (128,50) placed at (72,46) -> body stays in canvas
$TILT = -28.0
$cosT = [Math]::Cos($TILT * [Math]::PI / 180.0)
$sinT = [Math]::Sin($TILT * [Math]::PI / 180.0)

# flame flicker params (256-space): h, lean, w  -- flame base sits on head top (y=50)
$flick = @(
    @{ h = 44; lean = -6; w = 26 },
    @{ h = 37; lean = 4;  w = 22 },
    @{ h = 48; lean = -3; w = 27 },
    @{ h = 40; lean = 6;  w = 23 },
    @{ h = 42; lean = 0;  w = 25 },
    @{ h = 35; lean = -5; w = 21 }
)

Write-Host '[1/6] Arrow = tilted Boogieing figure (no flame)...'
$c = New-Canvas
$c.G.TranslateTransform(72, 46)
$c.G.RotateTransform($TILT)
$c.G.TranslateTransform(-128, -50)
$c.G.DrawImage($figPlain.Bmp, 0, 0, 256, 256)
$c.G.ResetTransform()
$c.Bmp.Save((Join-Path $OutDir 'preview_arrow.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$s = Shrink-To32 $c.Bmp
[System.IO.File]::WriteAllBytes((Join-Path $OutDir 'LighterArrow.cur'), (Get-CurBytes $s.Result 9 6))
$s.Result.Dispose(); $s.Temp | ForEach-Object { $_.Dispose() }; $c.G.Dispose(); $c.Bmp.Dispose()

Write-Host '[2/6] IBeam cursor (unchanged)...'
$c = New-Canvas
$p = New-Object System.Drawing.Drawing2D.GraphicsPath
$p.FillMode = [System.Drawing.Drawing2D.FillMode]::Winding
Add-RoundRect $p 124 34 8 188 4
Add-RoundRect $p 96 22 64 18 9
Add-RoundRect $p 96 216 64 18 9
$b = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(96, 22, 64, 212)), [System.Drawing.Color]::FromArgb(255, 255, 140, 26), [System.Drawing.Color]::FromArgb(255, 255, 210, 63), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$c.G.FillPath($b, $p); $b.Dispose()
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(240, 255, 255, 255), 7)
$c.G.DrawPath($pen, $p); $pen.Dispose(); $p.Dispose()
$c.Bmp.Save((Join-Path $OutDir 'preview_ibeam.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$s = Shrink-To32 $c.Bmp
[System.IO.File]::WriteAllBytes((Join-Path $OutDir 'LighterIBeam.cur'), (Get-CurBytes $s.Result 16 16))
$s.Result.Dispose(); $s.Temp | ForEach-Object { $_.Dispose() }; $c.G.Dispose(); $c.Bmp.Dispose()

Write-Host '[3/6] Hand cursor (unchanged)...'
$c = New-Canvas
$p = New-Object System.Drawing.Drawing2D.GraphicsPath
$p.FillMode = [System.Drawing.Drawing2D.FillMode]::Winding
Add-RoundRect $p 64 112 128 112 46
Add-RoundRect $p 92 30 40 100 20
$b = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(64, 30, 128, 194)), [System.Drawing.Color]::FromArgb(255, 66, 72, 82), [System.Drawing.Color]::FromArgb(255, 22, 25, 30), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$c.G.FillPath($b, $p); $b.Dispose()
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(240, 255, 255, 255), 8)
$pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$c.G.DrawPath($pen, $p); $pen.Dispose()
$kPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(140, 255, 255, 255), 5)
$c.G.DrawLine($kPen, 108, 160, 108, 200)
$c.G.DrawLine($kPen, 148, 160, 148, 200)
$kPen.Dispose()
$p.Dispose()
$c.Bmp.Save((Join-Path $OutDir 'preview_hand.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$s = Shrink-To32 $c.Bmp
[System.IO.File]::WriteAllBytes((Join-Path $OutDir 'LighterHand.cur'), (Get-CurBytes $s.Result 14 4))
$s.Result.Dispose(); $s.Temp | ForEach-Object { $_.Dispose() }; $c.G.Dispose(); $c.Bmp.Dispose()

Write-Host '[4/6] Flame click = tilted Boogieing + animated flame on head...'
$frames = @()
for ($i = 0; $i -lt $flick.Count; $i++) {
    $f = $flick[$i]
    # compose upright: figure + flame on head, then tilt whole thing
    $up = New-Canvas
    $up.G.DrawImage($figPlain.Bmp, 0, 0, 256, 256)
    Draw-Flame $up.G 128 50 $f.h $f.w $f.lean 1.4
    $c = New-Canvas
    $c.G.TranslateTransform(72, 46)
    $c.G.RotateTransform($TILT)
    $c.G.TranslateTransform(-128, -50)
    $c.G.DrawImage($up.Bmp, 0, 0, 256, 256)
    $c.G.ResetTransform()
    if ($i -eq 0) { $c.Bmp.Save((Join-Path $OutDir 'preview_flame.png'), [System.Drawing.Imaging.ImageFormat]::Png) }
    # hotspot at rotated flame tip: v = (lean, -h) from pivot
    $vx = $f.lean; $vy = -$f.h
    $rx = 72 + ($vx * $cosT - $vy * $sinT)
    $ry = 46 + ($vx * $sinT + $vy * $cosT)
    $hx = [int][Math]::Round($rx / 8.0)
    $hy = [int][Math]::Round($ry / 8.0)
    if ($hx -lt 0) { $hx = 0 }; if ($hy -lt 0) { $hy = 0 }
    $s = Shrink-To32 $c.Bmp
    $frames += ,(Get-CurBytes $s.Result $hx $hy)
    $s.Result.Dispose(); $s.Temp | ForEach-Object { $_.Dispose() }; $c.G.Dispose(); $c.Bmp.Dispose(); $up.G.Dispose(); $up.Bmp.Dispose()
}
Save-Ani $frames 8 (Join-Path $OutDir 'LighterFlame.ani')

Write-Host '[5/6] Busy animation - Boogieing dance...'
$c = New-Canvas
$c.G.DrawImage($figGlow.Bmp, 0, 0, 256, 256)
$c.Bmp.Save((Join-Path $OutDir 'preview_busy.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$c.G.Dispose(); $c.Bmp.Dispose()
$angles = @(-12, -5, 4, 12, 4, -5)
$bobs   = @(2, 0, -2, -4, -2, 0)
$frames = @()
for ($i = 0; $i -lt $angles.Count; $i++) {
    $c = New-Canvas
    $g = $c.G
    $g.TranslateTransform(128, (128 + $bobs[$i]))
    $g.RotateTransform($angles[$i])
    $g.TranslateTransform(-128, -128)
    $g.DrawImage($figGlow.Bmp, 0, 0, 256, 256)
    $g.ResetTransform()
    $s = Shrink-To32 $c.Bmp
    $frames += ,(Get-CurBytes $s.Result 16 16)
    $s.Result.Dispose(); $s.Temp | ForEach-Object { $_.Dispose() }; $c.G.Dispose(); $c.Bmp.Dispose()
}
Save-Ani $frames 7 (Join-Path $OutDir 'LighterBusy.ani')

Write-Host '[6/6] Tray icon frames...'
for ($i = 0; $i -lt $angles.Count; $i++) {
    $c = New-Canvas
    $g = $c.G
    $g.TranslateTransform(128, (128 + $bobs[$i]))
    $g.RotateTransform($angles[$i])
    $g.TranslateTransform(-128, -128)
    $g.DrawImage($figGlow.Bmp, 0, 0, 256, 256)
    $g.ResetTransform()
    $small = New-Object System.Drawing.Bitmap(32, 32, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $sg = [System.Drawing.Graphics]::FromImage($small)
    $sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $sg.DrawImage($c.Bmp, 0, 0, 32, 32)
    $sg.Dispose()
    $small.Save((Join-Path $OutDir ('BoogieIcon_{0}.png' -f $i)), [System.Drawing.Imaging.ImageFormat]::Png)
    $small.Dispose(); $c.G.Dispose(); $c.Bmp.Dispose()
}

$figPlain.G.Dispose(); $figPlain.Bmp.Dispose()
$figGlow.G.Dispose(); $figGlow.Bmp.Dispose()

Write-Host ''
Write-Host 'Generated files:'
Get-ChildItem $OutDir -Filter *.cur | ForEach-Object { Write-Host ('  {0}  {1} bytes' -f $_.Name, $_.Length) }
Get-ChildItem $OutDir -Filter *.ani | ForEach-Object { Write-Host ('  {0}  {1} bytes' -f $_.Name, $_.Length) }
