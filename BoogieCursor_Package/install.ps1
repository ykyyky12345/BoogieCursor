# BoogieCursor one-click installer (Windows 10/11)
# - copies files to %LOCALAPPDATA%\BoogieCursor (stable location)
# - applies cursor scheme (registry + system reload)
# - starts flame-click resident + adds to startup
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$dest = Join-Path $env:LOCALAPPDATA 'BoogieCursor'

Write-Host '== BoogieCursor install =='

# stop any previous resident instance
Get-CimInstance Win32_Process -Filter "Name like 'powershell%'" |
    Where-Object { $_.CommandLine -like '*FlameClick.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 500

# copy files to stable location
New-Item -ItemType Directory -Force -Path (Join-Path $dest 'Cursors') | Out-Null
Copy-Item (Join-Path $src 'Cursors\*') (Join-Path $dest 'Cursors') -Force
Copy-Item (Join-Path $src 'FlameClick.ps1') $dest -Force

# apply cursor scheme
$p = 'HKCU:\Control Panel\Cursors'
Set-ItemProperty -Path $p -Name Arrow       -Value (Join-Path $dest 'Cursors\LighterArrow.cur')
Set-ItemProperty -Path $p -Name IBeam       -Value (Join-Path $dest 'Cursors\LighterIBeam.cur')
Set-ItemProperty -Path $p -Name Hand        -Value (Join-Path $dest 'Cursors\LighterHand.cur')
Set-ItemProperty -Path $p -Name Wait        -Value (Join-Path $dest 'Cursors\LighterBusy.ani')
Set-ItemProperty -Path $p -Name AppStarting -Value (Join-Path $dest 'Cursors\LighterBusy.ani')
Set-ItemProperty -Path $p -Name '(default)' -Value 'Boogie Flame'
$sig = '[DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);'
Add-Type -MemberDefinition $sig -Name U32 -Namespace W -ErrorAction SilentlyContinue
[void][W.U32]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 3)
Write-Host 'cursor scheme applied'

# launch resident now
Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dest\FlameClick.ps1`"" -WindowStyle Hidden
Write-Host 'flame-click resident started'

# startup shortcut (remove legacy name if present)
$startup = [Environment]::GetFolderPath('Startup')
Remove-Item (Join-Path $startup 'FlameClick.lnk') -Force -ErrorAction SilentlyContinue
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut((Join-Path $startup 'BoogieCursor.lnk'))
$sc.TargetPath = 'powershell.exe'
$sc.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dest\FlameClick.ps1`""
$sc.WorkingDirectory = $dest
$sc.WindowStyle = 7
$sc.Save()
Write-Host 'startup shortcut created'

Write-Host ''
Write-Host 'DONE! Hold LEFT mouse button to see the flame. Tray icon = dancing figure (right-click to exit).'
