# FlameClick v2 - polling based, NO low-level hook
# v1 used WH_MOUSE_LL; Windows silently removes the hook after accumulated
# callback timeouts (SetSystemCursor is slow), killing the effect after hours.
# v2 polls GetAsyncKeyState on a dedicated C# thread (15ms) -> immune forever.
# Exit via tray icon -> Exit
$ErrorActionPreference = 'Stop'
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

namespace Flame {
public static class Fx {
    const uint OCR_NORMAL = 32512, OCR_IBEAM = 32513, OCR_HAND = 32649;
    static readonly uint[] _ids = { OCR_NORMAL, OCR_IBEAM, OCR_HAND };
    static string[] _restorePaths = new string[_ids.Length];
    static string _aniPath;
    static volatile bool _on = false;
    static volatile bool _running = false;
    static Thread _thread;

    [DllImport("user32.dll")] static extern bool SetSystemCursor(IntPtr hcur, uint id);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern IntPtr LoadImage(IntPtr h, string f, uint t, int cx, int cy, uint fl);
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int vKey);
    [DllImport("user32.dll")] static extern bool DestroyIcon(IntPtr h);

    static void Apply() {
        _on = true;
        foreach (uint id in _ids) {
            IntPtr h = LoadImage(IntPtr.Zero, _aniPath, 2, 0, 0, 0x10);  // IMAGE_CURSOR, LR_LOADFROMFILE
            if (h != IntPtr.Zero) SetSystemCursor(h, id);                 // SetSystemCursor destroys h
        }
    }

    static void Restore() {
        _on = false;
        for (int i = 0; i < _ids.Length; i++) {
            IntPtr h = IntPtr.Zero;
            if (!string.IsNullOrEmpty(_restorePaths[i])) h = LoadImage(IntPtr.Zero, _restorePaths[i], 2, 0, 0, 0x10);
            if (h != IntPtr.Zero) SetSystemCursor(h, _ids[i]);
        }
    }

    static void Loop() {
        while (_running) {
            bool down = (GetAsyncKeyState(0x01) & 0x8000) != 0;  // VK_LBUTTON
            if (down && !_on) Apply();
            else if (_on && !down) Restore();
            Thread.Sleep(15);
        }
    }

    static object _keepAlive;  // roots the mutex so GC cannot release single-instance lock
    public static void SetKeepAlive(object o) { _keepAlive = o; }

    public static void Start(string aniPath, string[] restorePaths) {
        _aniPath = aniPath;
        for (int i = 0; i < _ids.Length; i++) _restorePaths[i] = restorePaths[i];
        _running = true;
        _thread = new Thread(Loop);
        _thread.IsBackground = true;
        _thread.Start();
    }

    public static void Stop() {
        _running = false;
        if (_thread != null && _thread.IsAlive) _thread.Join(1000);
        if (_on) Restore();
    }

    public static bool IsOn() { return _on; }

    public static void SafeDestroyIcon(IntPtr h) { if (h != IntPtr.Zero) DestroyIcon(h); }
}
}
"@

# single-instance guard (abandoned-mutex safe, GC-proof via C# static root)
$mtx = New-Object System.Threading.Mutex($false, 'Global\FlameCursorClick')
$owned = $false
try { $owned = $mtx.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $owned = $true }
if (-not $owned) { return }
[Flame.Fx]::SetKeepAlive($mtx)

$curDir = Join-Path $PSScriptRoot 'Cursors'
$aniPath = Join-Path $curDir 'LighterFlame.ani'
if (-not (Test-Path $aniPath)) { throw "missing $aniPath - run make-cursors.ps1 first" }

[System.Windows.Forms.Application]::EnableVisualStyles()
$reg = Get-ItemProperty 'HKCU:\Control Panel\Cursors'
$restorePaths = @($reg.Arrow, $reg.IBeam, $reg.Hand)
[Flame.Fx]::Start($aniPath, $restorePaths)

# tray icon: boogie frames if available, else flame fallback
$script:iconBmps = @()
Get-ChildItem $curDir -Filter 'BoogieIcon_*.png' | Sort-Object Name | ForEach-Object {
    $script:iconBmps += ,(New-Object System.Drawing.Bitmap($_.FullName))
}
if ($script:iconBmps.Count -eq 0) {
    $b = New-Object System.Drawing.Bitmap(16, 16)
    $ig = [System.Drawing.Graphics]::FromImage($b)
    $ig.SmoothingMode = 'AntiAlias'
    $fp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $fp.AddBezier(8, 2, 3, 7, 5, 11, 8, 14)
    $fp.AddBezier(8, 14, 11, 11, 13, 7, 8, 2)
    $fp.CloseFigure()
    $ib = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 150, 30))
    $ig.FillPath($ib, $fp)
    $ig.Dispose(); $ib.Dispose(); $fp.Dispose()
    $script:iconBmps += ,$b
}
$script:hicon = [IntPtr]::Zero
$script:tIdx = 0

$icon = New-Object System.Windows.Forms.NotifyIcon
$icon.Text = 'Boogie Cursor - hold LMB for flame'
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$mi = New-Object System.Windows.Forms.ToolStripMenuItem('Exit')
$mi.Add_Click({
    $timer.Stop()
    [Flame.Fx]::Stop()
    $icon.Visible = $false
    [Flame.Fx]::SafeDestroyIcon($script:hicon)
    [System.Windows.Forms.Application]::Exit()
})
$menu.Items.Add($mi) | Out-Null
$icon.ContextMenuStrip = $menu

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 130
$timer.Add_Tick({
    $script:tIdx = ($script:tIdx + 1) % $script:iconBmps.Count
    $new = $script:iconBmps[$script:tIdx].GetHicon()
    $icon.Icon = [System.Drawing.Icon]::FromHandle($new)
    [Flame.Fx]::SafeDestroyIcon($script:hicon)
    $script:hicon = $new
})
$timer.Start()
$first = $script:iconBmps[0].GetHicon()
$icon.Icon = [System.Drawing.Icon]::FromHandle($first)
$script:hicon = $first
$icon.Visible = $true

Write-Host 'Flame click effect running (polling mode) - hold LEFT button to see flame'
[System.Windows.Forms.Application]::Run()
