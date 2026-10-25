# Convierte a OGG Vorbis la música, los ambientes y el tema del título (los .wav
# que escriben tools/generate_zone_music.gd, generate_sfx.gd y generate_music.gd)
# y borra los .wav y sus .import. Los efectos cortos (assets/audio/sfx) se quedan
# en WAV: son pequeños y suenan al instante.
#
# Los bucles siguen en data/music_loops.json, en muestras (Sfx.load_looped los
# pasa a segundos). Después, importa con Godot (--headless --import) para que
# aparezcan los .ogg.import.
#
# Uso:  powershell -ExecutionPolicy Bypass -File tools/convert_audio.ps1 [-Calidad 4] [-Ffmpeg ruta]

param(
	[int]$Calidad = 4,
	[string]$Ffmpeg = "ffmpeg"
)

$root = Split-Path -Parent $PSScriptRoot
$dirs = @("assets/audio/music", "assets/audio/ambient")
$files = @()
foreach ($d in $dirs) { $files += Get-ChildItem (Join-Path $root $d) -Filter *.wav }
$title = Join-Path $root "assets/audio/title_theme.wav"
if (Test-Path $title) { $files += Get-Item $title }
if ($files.Count -eq 0) { Write-Host "No hay .wav que convertir."; exit 0 }

$before = 0
$after = 0
$failed = 0
foreach ($f in $files) {
	$ogg = [IO.Path]::ChangeExtension($f.FullName, ".ogg")
	& $Ffmpeg -y -loglevel error -i $f.FullName -c:a libvorbis -q:a $Calidad $ogg
	if ($LASTEXITCODE -ne 0 -or -not (Test-Path $ogg)) {
		Write-Host "[FALLA] $($f.Name)"
		$failed++
		continue
	}
	$before += $f.Length
	$after += (Get-Item $ogg).Length
	Remove-Item $f.FullName
	$import = "$($f.FullName).import"
	if (Test-Path $import) { Remove-Item $import }
}
Write-Host ("Convertidos {0} de {1}: {2:N1} MB -> {3:N1} MB" -f ($files.Count - $failed), $files.Count, ($before / 1MB), ($after / 1MB))
if ($failed -gt 0) { exit 1 }
