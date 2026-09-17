# BoogieCursor uninstaller
# - stops resident, removes startup shortcut
# - restores Windows default (aero) cursors
# - deletes %LOCALAPPDATA%\BoogieCursor
$ErrorActionPreference = 'SilentlyContinue'

Get-CimInstance Win32_Process -Filter "Name like 'powershell%'" |
    Where-Object { $_.CommandLine -like '*FlameClick.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Start-Sleep -Milliseconds 500

$startup = [Environment]::GetFolderPath('Startup')
Remove-Item (Join-Path $startup 'BoogieCursor.lnk') -Force
Remove-Item (Join-Path $startup 'FlameClick.lnk') -Force

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
Add-Type -MemberDefinition $sig -Name U32 -Namespace W2 -ErrorAction SilentlyContinue
[void][W2.U32]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 3)

Remove-Item (Join-Path $env:LOCALAPPDATA 'BoogieCursor') -Recurse -Force
Write-Host 'BoogieCursor removed, Windows default cursors restored.'
