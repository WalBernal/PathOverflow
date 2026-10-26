@echo off
rem Abre el editor de historia (NPC, dialogos, escenas, misiones y tutorial).
rem Guarda en data\*.json; desde el propio editor se puede probar el juego y generar build\PathOverflow.exe.
set GODOT=%USERPROFILE%\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe
if not exist "%GODOT%" set GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe
if not exist "%GODOT%" (
  echo No encuentro Godot_v4.7.2-stable_win64.exe en el Escritorio ni en Descargas.
  pause
  exit /b 1
)
start "" "%GODOT%" --path "%~dp0." --windowed --resolution 1600x900 res://tools/story_editor.tscn
