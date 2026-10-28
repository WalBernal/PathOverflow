# Instala lo necesario para exportar el APK de Android (T110) y lo exporta a build/PathOverflow.apk.
# Descarga (si falta) el JDK 17 de Adoptium a %LOCALAPPDATA%\PathOverflowAndroid y las herramientas
# de línea de comandos de Android a %LOCALAPPDATA%\Android\Sdk, y apunta el editor de Godot a ellos.
# Te pide aceptar las licencias de Android (responde «y» a cada una): eso lo decides tú.
# Uso:  powershell -ExecutionPolicy Bypass -File tools/instalar_android.ps1

param([string]$Godot = "$env:USERPROFILE\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe")

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$base = "$env:LOCALAPPDATA\PathOverflowAndroid"
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
New-Item -ItemType Directory -Force "$base\descargas" | Out-Null

$jdk = Get-ChildItem $base -Directory | Where-Object Name -like 'jdk-17*' | Select-Object -First 1
if (-not $jdk) {
	Write-Host "1/5 · Descargando el JDK 17 (unos 190 MB)…"
	$zip = "$base\descargas\jdk17.zip"
	Invoke-WebRequest "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse" -OutFile $zip
	Expand-Archive $zip $base -Force
	$jdk = Get-ChildItem $base -Directory | Where-Object Name -like 'jdk-17*' | Select-Object -First 1
} else { Write-Host "1/5 · JDK 17 ya instalado." }
$env:JAVA_HOME = $jdk.FullName

$sm = "$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
if (-not (Test-Path $sm)) {
	Write-Host "2/5 · Descargando las herramientas de Android (unos 150 MB)…"
	$zip = "$base\descargas\cmdline-tools.zip"
	Invoke-WebRequest "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip" -OutFile $zip
	$tmp = "$base\descargas\cmdline-tools"
	if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
	Expand-Archive $zip $tmp -Force
	New-Item -ItemType Directory -Force "$sdk\cmdline-tools" | Out-Null
	Move-Item "$tmp\cmdline-tools" "$sdk\cmdline-tools\latest"
} else { Write-Host "2/5 · Herramientas de Android ya instaladas." }

Write-Host "3/5 · Licencias del SDK de Android (léelas y responde y/N):"
$ErrorActionPreference = "Continue"
& $sm --sdk_root="$sdk" --licenses
Write-Host "4/5 · platform-tools, build-tools 36.1.0 y la plataforma Android 36:"
& $sm --sdk_root="$sdk" "platform-tools" "build-tools;36.1.0" "platforms;android-36"
if (-not (Test-Path "$sdk\build-tools\36.1.0\apksigner.bat")) { Write-Host "Algo no se instaló: falta $sdk\build-tools\36.1.0."; exit 1 }

# Que el editor de Godot sepa dónde están el JDK y el SDK.
$settings = "$env:APPDATA\Godot\editor_settings-4.7.tres"
if (Test-Path $settings) {
	$text = Get-Content $settings -Raw -Encoding UTF8
	foreach ($pair in @(@("export/android/java_sdk_path", $jdk.FullName), @("export/android/android_sdk_path", $sdk))) {
		$line = "$($pair[0]) = `"$($pair[1] -replace '\\', '/')`""
		if ($text -match [regex]::Escape($pair[0]) + " = .*") { $text = $text -replace ([regex]::Escape($pair[0]) + " = .*"), $line.Replace('$', '$$') }
		else { $text = $text.TrimEnd() + "`n$line`n" }
	}
	[IO.File]::WriteAllText($settings, $text)
}

Write-Host "5/5 · Exportando build/PathOverflow.apk…"
# Con la versión de project.godot y el código de versión subido (T139).
& powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\exportar_android.ps1" -Godot $Godot
exit $LASTEXITCODE
