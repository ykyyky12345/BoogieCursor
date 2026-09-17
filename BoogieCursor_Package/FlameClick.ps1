# Resident: hold left mouse button -> cursor becomes tilted lighter with animated flame
# Tray icon: dancing Boogieing animation (frames from Cursors\BoogieIcon_*.png)
# Exit via tray icon -> Exit
$ErrorActionPreference = 'Stop'
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace Flame {
public static class Fx {
    const uint WM_LBUTTONDOWN = 0x0201;
    const uint WM_LBUTTONUP   = 0x0202;
    const uint OCR_NORMAL = 32512, OCR_IBEAM = 32513, OCR_HAND = 32649;
    static readonly uint[] _ids = { OCR_NORMAL, OCR_IBEAM, OCR_HAND };
    static IntPtr[] _saved = new IntPtr[_ids.Length];
    static string[] _restorePaths = new string[_ids.Length];
    static IntPtr _hHook = IntPtr.Zero;
    static string _aniPath;
    static bool _on = false;

    delegate IntPtr HookProc(int nCode, IntPtr wp, IntPtr lp);
    static HookProc _proc = HookCallback;

    [DllImport("user32.dll")] static extern IntPtr SetWindowsHookEx(int id, HookProc cb, IntPtr hMod, uint tid);
    [DllImport("user32.dll")] static extern IntPtr CallNextHookEx(IntPtr hh, int nCode, IntPtr wp, IntPtr lp);
    [DllImport("user32.dll")] static extern bool UnhookWindowsHookEx(IntPtr hh);
    [DllImport("user32.dll")] static extern bool SetSystemCursor(IntPtr hcur, uint id);
    [DllImport("user32.dll")] static extern IntPtr LoadCursor(IntPtr h, uint id);
    [DllImport("user32.dll")] static extern IntPtr CopyIcon(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern IntPtr LoadImage(IntPtr h, string f, uint t, int cx, int cy, uint fl);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode)] static extern IntPtr GetModuleHandle(string n);
    [DllImport("user32.dll")] static extern bool DestroyIcon(IntPtr h);
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int vKey);

    static IntPtr HookCallback(int nCode, IntPtr wp, IntPtr lp) {
        if (nCode >= 0) {
            uint msg = (uint)wp.ToInt64();
            if (msg == WM_LBUTTONDOWN && !_on) Apply();
            else if (msg == WM_LBUTTONUP && _on) Restore();
        }
        return CallNextHookEx(_hHook, nCode, wp, lp);
    }

    static void Apply() {
        _on = true;
        foreach (uint id in _ids) {
            IntPtr h = LoadImage(IntPtr.Zero, _aniPath, 2, 0, 0, 0x10);
            if (h != IntPtr.Zero) SetSystemCursor(h, id);
        }
    }

    static void Restore() {
        _on = false;
        for (int i = 0; i < _ids.Length; i++) {
            // prefer reloading from registry scheme (deterministic, never flame)
            IntPtr h = IntPtr.Zero;
            if (!string.IsNullOrEmpty(_restorePaths[i])) h = LoadImage(IntPtr.Zero, _restorePaths[i], 2, 0, 0, 0x10);
            if (h != IntPtr.Zero) SetSystemCursor(h, _ids[i]);
            else if (_saved[i] != IntPtr.Zero) SetSystemCursor(CopyIcon(_saved[i]), _ids[i]);
        }
    }

    // self-heal: if a WM_LBUTTONUP was ever missed, put out the flame
    public static void Sync() {
        if (_on && ((GetAsyncKeyState(0x01) & 0x8000) == 0)) Restore();
    }

    public static void Install(string aniPath, string[] restorePaths) {
        _aniPath = aniPath;
        for (int i = 0; i < _ids.Length; i++) _restorePaths[i] = restorePaths[i];
        for (int i = 0; i < _ids.Length; i++) {
            IntPtr h = LoadCursor(IntPtr.Zero, _ids[i]);
            _saved[i] = CopyIcon(h);
        }
        _hHook = SetWindowsHookEx(14, _proc, GetModuleHandle(null), 0);
        if (_hHook == IntPtr.Zero) throw new Exception("SetWindowsHookEx failed: " + Marshal.GetLastWin32Error());
    }

    public static void Uninstall() {
        if (_hHook != IntPtr.Zero) { UnhookWindowsHookEx(_hHook); _hHook = IntPtr.Zero; }
        if (_on) Restore();
    }

    public static void SafeDestroyIcon(IntPtr h) { if (h != IntPtr.Zero) DestroyIcon(h); }
}
}
"@

# single-instance guard
$mtx = New-Object System.Threading.Mutex($false, 'Global\FlameCursorClick')
if (-not $mtx.WaitOne(0)) { return }

$curDir = Join-Path $PSScriptRoot 'Cursors'
$aniPath = Join-Path $curDir 'LighterFlame.ani'
if (-not (Test-Path $aniPath)) { throw "missing $aniPath - run make-cursors.ps1 first" }

[System.Windows.Forms.Application]::EnableVisualStyles()
$reg = Get-ItemProperty 'HKCU:\Control Panel\Cursors'
$restorePaths = @($reg.Arrow, $reg.IBeam, $reg.Hand)
[Flame.Fx]::Install($aniPath, $restorePaths)

# safety sync: extinguish flame if button-up was missed
$safety = New-Object System.Windows.Forms.Timer
$safety.Interval = 250
$safety.Add_Tick({ [Flame.Fx]::Sync() })
$safety.Start()

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
$icon.Text = 'Lighter Cursor - hold LMB for flame'
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$mi = New-Object System.Windows.Forms.ToolStripMenuItem('Exit')
$mi.Add_Click({
    $timer.Stop()
    $safety.Stop()
    [Flame.Fx]::Uninstall()
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

Write-Host 'Flame click effect running - hold LEFT button to see lighter flame'
[System.Windows.Forms.Application]::Run()
