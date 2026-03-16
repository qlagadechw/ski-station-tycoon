@echo off
title Ski Station Tycoon - Lanceur
setlocal EnableDelayedExpansion

:: Déterminer le dossier du projet (parent du dossier launcher/)
set "LAUNCHER_DIR=%~dp0"
set "PROJECT_DIR=%LAUNCHER_DIR%.."
pushd "%PROJECT_DIR%"
set "PROJECT_DIR=%CD%"
popd

echo.
echo  ========================================
echo    SKI STATION TYCOON - Lanceur v1.0
echo  ========================================
echo.

:: Vérifier que project.godot existe
if not exist "%PROJECT_DIR%\project.godot" (
    echo  [ERREUR] Fichier project.godot introuvable dans :
    echo           %PROJECT_DIR%
    echo.
    echo  Assurez-vous que ce lanceur se trouve bien dans le
    echo  dossier "launcher/" du projet Ski Station Tycoon.
    pause
    exit /b 1
)

set "GODOT_EXE="

:: 1. Fichier de chemin sauvegardé
if exist "%LAUNCHER_DIR%godot_path.txt" (
    set /p GODOT_EXE=<"%LAUNCHER_DIR%godot_path.txt"
    if exist "!GODOT_EXE!" (
        echo  [INFO] Chemin Godot chargé depuis godot_path.txt
        goto :launch
    ) else (
        set "GODOT_EXE="
    )
)

:: 2. Variable d'environnement GODOT_PATH
if defined GODOT_PATH (
    if exist "%GODOT_PATH%" (
        set "GODOT_EXE=%GODOT_PATH%"
        echo  [INFO] Godot trouvé via la variable GODOT_PATH
        goto :launch
    )
)

:: 3. Recherche dans le PATH
for %%X in (godot4.exe godot.exe) do (
    if "!GODOT_EXE!"=="" (
        where %%X >nul 2>&1
        if !errorlevel! == 0 (
            set "GODOT_EXE=%%X"
            echo  [INFO] Godot trouvé dans le PATH : %%X
        )
    )
)
if defined GODOT_EXE goto :launch

:: 4. Emplacements courants
for %%D in (
    "%ProgramFiles%\Godot"
    "%ProgramFiles(x86)%\Godot"
    "%LOCALAPPDATA%\Godot"
    "%USERPROFILE%\Godot"
) do (
    if "!GODOT_EXE!"=="" (
        for %%F in ("%%~D\Godot_v4*.exe") do (
            if exist "%%F" (
                set "GODOT_EXE=%%F"
                echo  [INFO] Godot trouvé dans : %%~D
            )
        )
    )
)
if defined GODOT_EXE goto :launch

:: 5. Demander à l'utilisateur
echo  [ATTENTION] Godot 4 n'a pas été trouvé automatiquement.
echo.
echo  Téléchargez Godot 4 sur : https://godotengine.org/download
echo  Choisissez la version "Standard" pour votre système.
echo.
echo  Entrez le chemin complet vers l'exécutable Godot 4
echo  (ex: C:\Program Files\Godot\Godot_v4.2.exe)
echo  ou laissez vide pour annuler.
echo.
set /p "GODOT_EXE=Chemin Godot : "

if "!GODOT_EXE!"=="" (
    echo.
    echo  Lancement annulé.
    pause
    exit /b 1
)

if not exist "!GODOT_EXE!" (
    echo.
    echo  [ERREUR] Fichier introuvable : !GODOT_EXE!
    pause
    exit /b 1
)

:: Sauvegarder pour les prochains lancements
echo !GODOT_EXE!>"%LAUNCHER_DIR%godot_path.txt"
echo  [INFO] Chemin sauvegardé dans godot_path.txt

:launch
echo.
echo  Projet  : %PROJECT_DIR%
echo  Godot   : !GODOT_EXE!
echo.
echo  Lancement de Ski Station Tycoon...
echo.

"!GODOT_EXE!" --path "%PROJECT_DIR%"

if !errorlevel! neq 0 (
    echo.
    echo  [ERREUR] Le jeu s'est terminé avec une erreur (code : !errorlevel!)
    pause
)

endlocal
