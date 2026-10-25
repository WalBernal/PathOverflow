# Desinstala Path Overflow (lo que puso PathOverflow-Setup.exe, installer/Setup.cs). Las partidas guardadas
# (%APPDATA%\Godot\app_userdata\Path Overflow) se quedan.

$target = Join-Path $env:LOCALAPPDATA "Programs\PathOverflow"
$menu = Join-Path ([Environment]::GetFolderPath("Programs")) "Path Overflow"
$desktop = Join-Path ([Environment]::GetFolderPath("Desktop")) "Path Overflow.lnk"

Add-Type -AssemblyName System.Windows.Forms
$answer = [System.Windows.Forms.MessageBox]::Show("¿Desinstalar Path Overflow? Tus partidas guardadas no se borran.", "Path Overflow", "YesNo")
if ($answer -ne "Yes") { exit 0 }
foreach ($p in @($desktop, $menu)) {
	if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}
# La carpeta del juego, al final (este script vive ahí).
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NoProfile -Command Start-Sleep 1; Remove-Item -LiteralPath '$target' -Recurse -Force"
