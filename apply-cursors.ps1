# Apply lighter cursor scheme (registry + system reload)
$ErrorActionPreference = 'Stop'
$Cur = Join-Path $PSScriptRoot 'Cursors'
$p = 'HKCU:\Control Panel\Cursors'
Set-ItemProperty -Path $p -Name Arrow       -Value (Join-Path $Cur 'LighterArrow.cur')
Set-ItemProperty -Path $p -Name IBeam       -Value (Join-Path $Cur 'LighterIBeam.cur')
Set-ItemProperty -Path $p -Name Hand        -Value (Join-Path $Cur 'LighterHand.cur')
Set-ItemProperty -Path $p -Name Wait        -Value (Join-Path $Cur 'LighterBusy.ani')
Set-ItemProperty -Path $p -Name AppStarting -Value (Join-Path $Cur 'LighterBusy.ani')
Set-ItemProperty -Path $p -Name '(default)' -Value 'Lighter Flame'

$sig = '[DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);'
Add-Type -MemberDefinition $sig -Name U32 -Namespace W
[void][W.U32]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 3)  # SPI_SETCURSORS + update + sendchange
Write-Host 'Cursor scheme applied: Arrow / IBeam / Hand / Busy (lighter theme)'
