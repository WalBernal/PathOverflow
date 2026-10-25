# Exporta el juego para Windows, Linux y macOS (las que tengan su plantilla de
# exportación instalada) y arma el instalador de Windows (installer/Setup.cs, con el
# compilador de C# que trae .NET Framework: no hay que instalar nada):
#   build/PathOverflow.exe           Windows (un solo archivo, como antes)
#   build/PathOverflow-Setup.exe     instalador: lo pone en %LOCALAPPDATA%\Programs\PathOverflow,
#                                    con accesos directos y desinstalador (installer/)
#   build/linux/PathOverflow.x86_64  Linux
#   build/mac/PathOverflow.zip       macOS (app universal, firmada ad hoc)
# Las plantillas de Linux y macOS se instalan desde el editor (Editor → Administrar
# plantillas de exportación); sin ellas, esas exportaciones se saltan con un aviso.
#
# Uso:  powershell -ExecutionPolicy Bypass -File tools/build_release.ps1 [-Godot ruta] [-SinInstalador]

param(
	[string]$Godot = "$env:USERPROFILE\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe",
	[switch]$SinInstalador
)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not (Test-Path "export_presets.cfg")) {
	Copy-Item "export_presets.example.cfg" "export_presets.cfg"
	Write-Host "export_presets.cfg creado desde export_presets.example.cfg"
}
$templates = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable"
$targets = @(
	@{ Preset = "Windows"; Path = "build/PathOverflow.exe"; Template = "windows_release_x86_64.exe" },
	@{ Preset = "Linux"; Path = "build/linux/PathOverflow.x86_64"; Template = "linux_release.x86_64" },
	@{ Preset = "macOS"; Path = "build/mac/PathOverflow.zip"; Template = "macos.zip" }
)
$failed = 0
foreach ($t in $targets) {
	if (-not (Test-Path (Join-Path $templates $t.Template))) {
		Write-Host "[SALTA] $($t.Preset): falta la plantilla $($t.Template) (Editor → Administrar plantillas de exportación)"
		continue
	}
	New-Item -ItemType Directory -Force (Split-Path -Parent $t.Path) | Out-Null
	if (Test-Path $t.Path) { Remove-Item $t.Path -Force }
	# Canalizado: si no, PowerShell no espera a Godot (es una aplicación de ventana).
	& $Godot --headless --path $root --export-release $t.Preset $t.Path 2>&1 | Out-Null
	if (Test-Path $t.Path) {
		Write-Host ("[OK] {0}: {1} ({2:N0} MB)" -f $t.Preset, $t.Path, ((Get-Item $t.Path).Length / 1MB))
	} else {
		Write-Host "[FALLA] $($t.Preset): no se generó $($t.Path)"
		$failed++
	}
}

if (-not $SinInstalador) {
	$exe = Join-Path $root "build/PathOverflow.exe"
	$csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
	if (-not (Test-Path $exe)) {
		Write-Host "[SALTA] instalador: no hay build/PathOverflow.exe"
	} elseif (-not (Test-Path $csc)) {
		Write-Host "[SALTA] instalador: falta el compilador de .NET Framework 4 ($csc)"
	} else {
		# installer/Setup.cs con el juego y el desinstalador dentro, como recursos.
		$setup = Join-Path $root "build/PathOverflow-Setup.exe"
		if (Test-Path $setup) { Remove-Item $setup -Force }
		& $csc /nologo /target:winexe /optimize "/out:$setup" "/resource:$exe,PathOverflow.exe" "/resource:$(Join-Path $root 'installer/uninstall.ps1'),uninstall.ps1" /r:System.Windows.Forms.dll (Join-Path $root "installer/Setup.cs") 2>&1 | Out-Host
		if (Test-Path $setup) {
			Write-Host ("[OK] instalador: build/PathOverflow-Setup.exe ({0:N0} MB)" -f ((Get-Item $setup).Length / 1MB))
		} else {
			Write-Host "[FALLA] instalador: csc no generó build/PathOverflow-Setup.exe"
			$failed++
		}
	}
}
if ($failed -gt 0) { exit 1 }
