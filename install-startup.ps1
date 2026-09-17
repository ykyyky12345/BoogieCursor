# Install: launch flame-click effect now + add to startup
$dir = $PSScriptRoot
$arg = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dir\FlameClick.ps1`""

# launch now (hidden)
Start-Process powershell.exe -ArgumentList $arg -WindowStyle Hidden

# startup shortcut
$startup = [Environment]::GetFolderPath('Startup')
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut((Join-Path $startup 'FlameClick.lnk'))
$sc.TargetPath = 'powershell.exe'
$sc.Arguments = $arg
$sc.WorkingDirectory = $dir
$sc.WindowStyle = 7
$sc.Save()
Write-Host "Started FlameClick + shortcut created at $startup\FlameClick.lnk"
