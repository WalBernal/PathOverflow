# Corre las comprobaciones del proyecto: scripts, pruebas de lógica y prueba de integración.
# Uso:  powershell -File tools/run_checks.ps1 [-Rapida] [-Zonas id1,id2] [-Clases id1,id2]
#   -Rapida: integración de 5 s por zona en vez de 30 (~5 min en total; la estándar de cada tarea).
#   -Zonas / -Clases: la integración solo en esas zonas o clases (30 s, o 5 con -Rapida), para
#   probar a fondo lo que cambió sin esperar las 7 clases × todas las zonas (~30 min).
# Sale con código 1 si algo falla. La salida completa queda en %TEMP%\path_overflow_checks\.
param([switch]$Rapida, [string]$Zonas = "", [string]$Clases = "")

$godot = $env:GODOT
if (-not $godot) {
	foreach ($c in "$env:USERPROFILE\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe", "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe") {
		if (Test-Path $c) { $godot = $c; break }
	}
}
if (-not $godot) { Write-Host "No encuentro Godot 4.7.2: define la variable GODOT con su ruta."; exit 1 }

$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $env:TEMP "path_overflow_checks"
New-Item -ItemType Directory -Force $out | Out-Null
$seconds = if ($Rapida) { "5" } else { "30" }
$integration = @("--headless", "--fixed-fps", "60", "--path", $root, "res://tests/test_integration.tscn", "--", "segundos=$seconds")
if ($Zonas -ne "") { $integration += "zonas=$Zonas" }
if ($Clases -ne "") { $integration += "clases=$Clases" }
$checks = @(
	@{ Name = "scripts"; Args = @("--headless", "--path", $root, "-s", "res://tools/check_scripts.gd") },
	@{ Name = "logica"; Args = @("--headless", "--path", $root, "-s", "res://tests/test_core.gd") },
	@{ Name = "integracion"; Args = $integration }
)
$failed = $false
foreach ($c in $checks) {
	$log = Join-Path $out "$($c.Name).txt"
	$p = Start-Process $godot -ArgumentList $c.Args -NoNewWindow -Wait -PassThru -RedirectStandardOutput $log -RedirectStandardError "$log.err"
	$ok = $p.ExitCode -eq 0
	if (-not $ok) { $failed = $true }
	Write-Host ("[{0}] {1}" -f $(if ($ok) { "OK" } else { "FALLA" }), $c.Name)
	if (-not $ok) {
		Get-Content $log, "$log.err" -Encoding utf8 | Where-Object { $_ -match "FALL|ERROR|Error|error" } | Select-Object -First 30 | ForEach-Object { Write-Host "    $_" }
	}
}
if ($failed) { exit 1 }
exit 0
