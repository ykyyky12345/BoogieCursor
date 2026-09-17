# Restore Windows default cursors, stop flame-click effect, remove startup shortcut
$ErrorActionPreference = 'SilentlyContinue'

# 1. stop resident script
Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*FlameClick.ps1*' -and $_.ProcessId -ne $PID } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force; Write-Host "stopped pid $($_.ProcessId)" }

# 2. remove startup shortcut
$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'FlameClick.lnk'
if (Test-Path $lnk) { Remove-Item $lnk -Force; Write-Host 'startup shortcut removed' }

# 3. restore default cursor registry values
$cur = "$env:WINDIR\cursors"
$p = 'HKCU:\Control Panel\Cursors'
$defaults = @{
    Arrow = 'aero_arrow.cur';      Help = 'aero_helpsel.cur'
    AppStarting = 'aero_working.ani'; Wait = 'aero_busy.ani'
    Crosshair = 'aero_cross.cur';  IBeam = 'aero_ibeam.cur'
    No = 'aero_unavail.cur';       SizeNS = 'aero_ns.cur'
    SizeNESW = 'aero_nesw.cur';    SizeWE = 'aero_ew.cur'
    SizeNWSE = 'aero_nwse.cur';    Up = 'aero_up.cur'
    Hand = 'aero_link.cur';        Pin = 'aero_pin.cur'
    Person = 'aero_person.cur'
}
foreach ($k in $defaults.Keys) {
    $f = Join-Path $cur $defaults[$k]
    if (Test-Path $f) { Set-ItemProperty -Path $p -Name $k -Value $f }
}
Set-ItemProperty -Path $p -Name '(default)' -Value 'Windows Default'

$sig = '[DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);'
Add-Type -MemberDefinition $sig -Name U32 -Namespace W
[void][W.U32]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 3)
Write-Host 'Default Windows cursors restored.'
