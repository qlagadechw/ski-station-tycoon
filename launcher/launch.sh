#!/usr/bin/env bash
# Ski Station Tycoon - Lanceur Linux/macOS

set -euo pipefail

# Déterminer les chemins
LAUNCHER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$LAUNCHER_DIR")"
GODOT_PATH_FILE="$LAUNCHER_DIR/godot_path.txt"

echo ""
echo " ========================================"
echo "   SKI STATION TYCOON - Lanceur v1.0"
echo " ========================================"
echo ""

# Vérifier que project.godot existe
if [ ! -f "$PROJECT_DIR/project.godot" ]; then
    echo " [ERREUR] Fichier project.godot introuvable dans :"
    echo "          $PROJECT_DIR"
    echo ""
    echo " Assurez-vous que ce lanceur se trouve bien dans le"
    echo " dossier 'launcher/' du projet Ski Station Tycoon."
    exit 1
fi

GODOT_EXE=""

# 1. Fichier de chemin sauvegardé
if [ -f "$GODOT_PATH_FILE" ]; then
    SAVED_PATH="$(cat "$GODOT_PATH_FILE" | tr -d '[:space:]')"
    if [ -n "$SAVED_PATH" ] && [ -x "$SAVED_PATH" ]; then
        GODOT_EXE="$SAVED_PATH"
        echo " [INFO] Chemin Godot chargé depuis godot_path.txt"
    fi
fi

# 2. Variable d'environnement GODOT_PATH
if [ -z "$GODOT_EXE" ] && [ -n "${GODOT_PATH:-}" ] && [ -x "${GODOT_PATH}" ]; then
    GODOT_EXE="$GODOT_PATH"
    echo " [INFO] Godot trouvé via la variable GODOT_PATH"
fi

# 3. Chercher dans le PATH
if [ -z "$GODOT_EXE" ]; then
    for cmd in godot4 godot; do
        if command -v "$cmd" >/dev/null 2>&1; then
            GODOT_EXE="$(command -v "$cmd")"
            echo " [INFO] Godot trouvé dans le PATH : $GODOT_EXE"
            break
        fi
    done
fi

# 4. Emplacements courants Linux
if [ -z "$GODOT_EXE" ]; then
    for path in /usr/bin/godot4 /usr/local/bin/godot4 /usr/bin/godot /usr/local/bin/godot; do
        if [ -x "$path" ]; then
            GODOT_EXE="$path"
            echo " [INFO] Godot trouvé : $path"
            break
        fi
    done
fi

# 5. Chercher dans ~/Godot/ (Linux)
if [ -z "$GODOT_EXE" ]; then
    for f in "$HOME"/Godot/Godot_v4*; do
        if [ -x "$f" ]; then
            GODOT_EXE="$f"
            echo " [INFO] Godot trouvé dans ~/Godot/ : $f"
            break
        fi
    done
fi

# 6. macOS — application bundle
if [ -z "$GODOT_EXE" ]; then
    MACOS_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
    if [ -x "$MACOS_PATH" ]; then
        GODOT_EXE="$MACOS_PATH"
        echo " [INFO] Godot trouvé sur macOS : $MACOS_PATH"
    fi
fi

# 7. Demander à l'utilisateur
if [ -z "$GODOT_EXE" ]; then
    echo " [ATTENTION] Godot 4 n'a pas été trouvé automatiquement."
    echo ""
    echo " Téléchargez Godot 4 sur : https://godotengine.org/download"
    echo " Choisissez la version 'Standard' pour votre système."
    echo ""
    echo " Entrez le chemin complet vers l'exécutable Godot 4"
    echo " (ex: /usr/local/bin/godot4)"
    echo " ou laissez vide pour annuler."
    echo ""
    read -rp " Chemin Godot : " USER_PATH

    if [ -z "$USER_PATH" ]; then
        echo ""
        echo " Lancement annulé."
        exit 1
    fi

    if [ ! -x "$USER_PATH" ]; then
        echo ""
        echo " [ERREUR] Fichier introuvable ou non exécutable : $USER_PATH"
        exit 1
    fi

    GODOT_EXE="$USER_PATH"
    echo "$GODOT_EXE" > "$GODOT_PATH_FILE"
    echo " [INFO] Chemin sauvegardé dans godot_path.txt"
fi

echo ""
echo " Projet  : $PROJECT_DIR"
echo " Godot   : $GODOT_EXE"
echo ""
echo " Lancement de Ski Station Tycoon..."
echo ""

exec "$GODOT_EXE" --path "$PROJECT_DIR"
