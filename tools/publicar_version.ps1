# Prepara una publicación en GitHub Releases (T140): exporta el APK firmado con tu clave
# (exportar_android.ps1 -Release) y escribe build/latest.json, el archivo que el juego lee
# en la pantalla de título para saber si hay una versión más nueva:
#   {"version": "3.1.0", "url": "https://github.com/<repo>/releases/download/v3.1.0/PathOverflow.apk", "notes": "..."}
# La primera vez apunta application/config/update_url de project.godot a
#   https://github.com/<repo>/releases/latest/download/latest.json
# (la última publicación). Después, en GitHub: Releases → «Draft a new release», etiqueta
# v<versión>, y sube build/PathOverflow.apk y build/latest.json. Antes, sube la versión en
# project.godot (application/config/version).
# Uso:  powershell -ExecutionPolicy Bypass -File tools/publicar_version.ps1 -Repo usuario/repositorio [-Notas "Qué trae"] [-SinExportar]

param([Parameter(Mandatory = $true)][string]$Repo, [string]$Notas = "", [switch]$SinExportar,
	[string]$Godot = "$env:USERPROFILE\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe")

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
if ($Repo -notmatch '^[\w.-]+/[\w.-]+$') { Write-Host "-Repo tiene que ser usuario/repositorio (p. ej. WalBernal/path-overflow)."; exit 1 }
$projectPath = "$root\project.godot"
$project = [IO.File]::ReadAllText($projectPath)
if ($project -notmatch 'config/version="([^"]+)"') { Write-Host "Falta application/config/version en project.godot."; exit 1 }
$version = $Matches[1]

$updateUrl = "https://github.com/$Repo/releases/latest/download/latest.json"
if ($project -match 'config/update_url="([^"]*)"' -and $Matches[1] -ne $updateUrl) {
	$project = $project -replace 'config/update_url="[^"]*"', "config/update_url=`"$updateUrl`""
	[IO.File]::WriteAllText($projectPath, $project, (New-Object Text.UTF8Encoding($false)))
	Write-Host "project.godot: el juego buscará actualizaciones en $updateUrl"
}

if (-not $SinExportar) {
	& powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\exportar_android.ps1" -Godot $Godot -Release
	if ($LASTEXITCODE -ne 0) { Write-Host "La exportación falló (¿está la clave propia en el preset «Android»?)."; exit 1 }
}

$latest = [ordered]@{
	version = $version
	url = "https://github.com/$Repo/releases/download/v$version/PathOverflow.apk"
	notes = $Notas
}
New-Item -ItemType Directory -Force "$root\build" | Out-Null
[IO.File]::WriteAllText("$root\build\latest.json", ($latest | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "Listo para publicar la v$version:"
Write-Host "  1. En https://github.com/$Repo/releases/new, etiqueta v$version."
Write-Host "  2. Sube build\PathOverflow.apk y build\latest.json y publica."
Write-Host "  3. Haz commit de project.godot si cambió la dirección de las actualizaciones."
