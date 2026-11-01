# Prepara una publicación en GitHub Releases (T140): exporta el APK y escribe
# build/latest.json, el archivo que el juego lee
# en la pantalla de título para saber si hay una versión más nueva:
#   {"version": "3.1.0", "url": "https://github.com/<repo>/releases/latest/download/PathOverflow.apk", "notes": "..."}
# (la etiqueta de la release puede ser cualquiera; mejor v<versión> para no liarse)
# La primera vez apunta application/config/update_url de project.godot a
#   https://github.com/<repo>/releases/latest/download/latest.json
# (la última publicación). Después, en GitHub: Releases → «Draft a new release», etiqueta
# v<versión>, y sube build/PathOverflow.apk y build/latest.json. Antes, sube la versión en
# project.godot (application/config/version).
# Firma: para que cada versión se instale encima de la anterior SIN BORRAR LAS PARTIDAS, la
# clave tiene que ser siempre la misma. Por defecto se firma como los APK ya instalados (la
# clave de depuración de este equipo, %APPDATA%\Godot\keystores\debug.keystore: guarda una
# copia; si se pierde o cambias de equipo, hay que llevarla). -ClavePropia firma con la clave
# del preset (Keystore → Release), pero cambiar de clave obliga a desinstalar una vez.
# -Subir: además crea (o actualiza) la release v<versión> en GitHub con el APK y el
# latest.json y la marca como la última, con GitHub CLI (gh). Una sola vez en el equipo:
#   winget install --id GitHub.cli      y luego      gh auth login
# -SoloSubir: sube lo que ya hay en build\ sin exportar de nuevo (equivale a -SinExportar -Subir).
# Uso:  powershell -ExecutionPolicy Bypass -File tools/publicar_version.ps1 -Repo usuario/repositorio [-Notas "Qué trae"] [-SinExportar] [-ClavePropia] [-Subir] [-SoloSubir]

param([Parameter(Mandatory = $true)][string]$Repo, [string]$Notas = "", [switch]$SinExportar, [switch]$ClavePropia,
	[switch]$Subir, [switch]$SoloSubir,
	[string]$Godot = "$env:USERPROFILE\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe")
if ($SoloSubir) { $SinExportar = $true; $Subir = $true }

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
	if ($ClavePropia) {
		& powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\exportar_android.ps1" -Godot $Godot -Release
	} else {
		& powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\exportar_android.ps1" -Godot $Godot
	}
	if ($LASTEXITCODE -ne 0) { Write-Host "La exportación falló."; exit 1 }
}

$latest = [ordered]@{
	version = $version
	# La del APK de la última release, sea cual sea su etiqueta (con la etiqueta en la
	# dirección, una release llamada distinto daba 404 al descargar).
	url = "https://github.com/$Repo/releases/latest/download/PathOverflow.apk"
	notes = $Notas
}
New-Item -ItemType Directory -Force "$root\build" | Out-Null
[IO.File]::WriteAllText("$root\build\latest.json", ($latest | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
if (-not $Subir) {
	Write-Host "Listo para publicar la v${version}:"
	Write-Host "  1. En https://github.com/$Repo/releases/new, etiqueta v$version."
	Write-Host "  2. Sube build\PathOverflow.apk y build\latest.json y publica."
	Write-Host "  3. Haz commit de project.godot si cambió la dirección de las actualizaciones."
	Write-Host "  (O vuelve a correr esto con -SoloSubir para que lo haga GitHub CLI.)"
	exit 0
}

# --- Subir con GitHub CLI ---
# (Si la terminal se abrió antes de instalarlo, gh no está aún en su PATH: se busca donde lo deja el instalador.)
$ghExe = (Get-Command gh -ErrorAction SilentlyContinue).Source
if (-not $ghExe -and (Test-Path "$env:ProgramFiles\GitHub CLI\gh.exe")) { $ghExe = "$env:ProgramFiles\GitHub CLI\gh.exe" }
if (-not $ghExe) {
	Write-Host "Falta GitHub CLI (gh). Instálalo una vez con:  winget install --id GitHub.cli"
	Write-Host "y conéctalo a tu cuenta con:  gh auth login   (luego vuelve a correr esto con -SoloSubir)."
	exit 1
}
& $ghExe auth status *> $null
if ($LASTEXITCODE -ne 0) {
	Write-Host "GitHub CLI no tiene sesión: corre  gh auth login  una vez y vuelve a intentarlo con -SoloSubir."
	exit 1
}
$apk = "$root\build\PathOverflow.apk"
$json = "$root\build\latest.json"
if (-not (Test-Path $apk)) { Write-Host "No está build\PathOverflow.apk: exporta primero (sin -SoloSubir)."; exit 1 }
$tag = "v$version"
$title = "Path Overflow $version"
$body = if ($Notas -ne "") { $Notas } else { "Versión $version." }
& $ghExe release view $tag --repo $Repo *> $null
if ($LASTEXITCODE -eq 0) {
	# Ya existe: se sustituyen los archivos y se vuelve a marcar como la última.
	& $ghExe release upload $tag $apk $json --repo $Repo --clobber
	if ($LASTEXITCODE -ne 0) { Write-Host "No se pudieron subir los archivos a $tag."; exit 1 }
	& $ghExe release edit $tag --repo $Repo --title $title --notes $body --latest | Out-Null
} else {
	& $ghExe release create $tag $apk $json --repo $Repo --title $title --notes $body --latest
	if ($LASTEXITCODE -ne 0) { Write-Host "No se pudo crear la release $tag."; exit 1 }
}
Write-Host "Publicada: https://github.com/$Repo/releases/tag/$tag (el juego la verá en el aviso de actualización)."
