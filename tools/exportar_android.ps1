# Exporta build/PathOverflow.apk con la versión del juego (T139). La versión sale de un solo
# sitio, application/config/version en project.godot (p. ej. "3.1.0"): se copia al preset
# «Android» de export_presets.cfg como version/name, y version/code sube en 1 en cada
# exportación (Android solo instala encima una versión con el código más alto).
# Necesita el JDK y el SDK de Android ya instalados (tools/instalar_android.ps1).
# Uso:  powershell -ExecutionPolicy Bypass -File tools/exportar_android.ps1 [-Release]

param([string]$Godot = "$env:USERPROFILE\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe", [switch]$Release)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$project = Get-Content "$root\project.godot" -Raw -Encoding UTF8
if ($project -notmatch 'config/version="([^"]+)"') { Write-Host "Falta application/config/version en project.godot."; exit 1 }
$version = $Matches[1]

# El preset «Android»: version/name = la del juego y version/code + 1 (en export_presets.cfg,
# que no va al repositorio; en el de ejemplo solo el nombre).
function Set-AndroidVersion([string]$path, [bool]$bump) {
	if (-not (Test-Path $path)) { return $null }
	$lines = [IO.File]::ReadAllLines($path)
	$android = [Array]::IndexOf($lines, 'name="Android"')
	if ($android -lt 0) { return $null }
	$code = $null
	for ($i = $android; $i -lt $lines.Length; $i++) {
		if ($i -gt $android -and $lines[$i] -match '^\[preset\.\d+\]$') { break }
		if ($bump -and $lines[$i] -match '^version/code=(\d+)$') {
			$code = [int]$Matches[1] + 1
			$lines[$i] = "version/code=$code"
		} elseif ($lines[$i] -match '^version/name=') {
			$lines[$i] = "version/name=`"$version`""
		}
	}
	[IO.File]::WriteAllLines($path, $lines, (New-Object Text.UTF8Encoding($false)))
	return $code
}
$code = Set-AndroidVersion "$root\export_presets.cfg" $true
if ($null -eq $code) { Write-Host "No encuentro el preset «Android» en export_presets.cfg (copia export_presets.example.cfg)."; exit 1 }
Set-AndroidVersion "$root\export_presets.example.cfg" $false | Out-Null
Write-Host "Versión $version (código $code)"

if (-not (Test-Path $Godot)) { Write-Host "No encuentro Godot en $Godot (pásalo con -Godot <ruta>)."; exit 1 }
New-Item -ItemType Directory -Force "$root\build" | Out-Null
$ErrorActionPreference = "Continue"
& $Godot --headless --path $root --import | Out-Null
$mode = if ($Release) { "--export-release" } else { "--export-debug" }
& $Godot --headless --path $root $mode "Android" build/PathOverflow.apk
if (Test-Path "$root\build\PathOverflow.apk") { Write-Host "Listo: build\PathOverflow.apk (v$version, código $code)"; exit 0 }
Write-Host "La exportación falló: revisa los mensajes de arriba."
exit 1
