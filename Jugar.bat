@echo off
rem Lanza Path Overflow en pantalla completa (F11 o Alt+Enter: ventana / pantalla completa).
rem Si existe el juego exportado (build\PathOverflow.exe), usa ese; si no, el editor sin depurador.
if exist "%~dp0build\PathOverflow.exe" (
  start "" "%~dp0build\PathOverflow.exe"
  exit /b
)
set GODOT=%USERPROFILE%\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe
if not exist "%GODOT%" set GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe
start "" "%GODOT%" --path "%~dp0." --fullscreen
