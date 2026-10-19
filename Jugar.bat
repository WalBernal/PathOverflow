@echo off
rem Lanza Path Overflow fuera del editor (sin depurador), en pantalla completa.
rem F11 o Alt+Enter cambian entre pantalla completa y ventana.
set GODOT=%USERPROFILE%\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe
if not exist "%GODOT%" set GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe
start "" "%GODOT%" --path "%~dp0." --fullscreen
