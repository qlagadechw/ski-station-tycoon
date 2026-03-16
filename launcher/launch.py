#!/usr/bin/env python3
"""
Ski Station Tycoon — Lanceur Python cross-platform
Fonctionne sur Windows, Linux et macOS.
"""

import os
import sys
import glob
import platform
import subprocess
import argparse
from pathlib import Path

# ---------------------------------------------------------------------------
# Couleurs ANSI
# ---------------------------------------------------------------------------
RESET  = "\033[0m"
BOLD   = "\033[1m"
RED    = "\033[31m"
GREEN  = "\033[32m"
YELLOW = "\033[33m"
CYAN   = "\033[36m"
WHITE  = "\033[97m"

def _color_supported() -> bool:
    """Retourne True si le terminal supporte les couleurs ANSI."""
    if platform.system() == "Windows":
        # Windows 10+ supporte ANSI dans cmd/PowerShell
        try:
            import ctypes
            kernel = ctypes.windll.kernel32  # type: ignore[attr-defined]
            kernel.SetConsoleMode(kernel.GetStdHandle(-11), 7)
            return True
        except Exception:
            return False
    return hasattr(sys.stdout, "isatty") and sys.stdout.isatty()

USE_COLOR = _color_supported()

def c(color: str, text: str) -> str:
    return f"{color}{text}{RESET}" if USE_COLOR else text

# ---------------------------------------------------------------------------
# Banner ASCII
# ---------------------------------------------------------------------------
BANNER = r"""
  /\    /\    /\      ___  _    _   ___  _____  _ _____ ___ ___  _  _
 /  \  /  \  /  \    / __|| |  | | / __||_   _|/_\_   _|_ _/ _ \| \| |
/    \/    \/    \    \__ \| |__| | \__ \  | | / _ \ | |  | | (_) | .` |
\    /\    /\    /    |___/|____|_| |___/  |_|/_/ \_\|_| |___\___/|_|\_|
 \  /  \  /  \  /
  \/    \/    \/             T Y C O O N   🎿
"""

# ---------------------------------------------------------------------------
# Chemins
# ---------------------------------------------------------------------------
LAUNCHER_DIR = Path(__file__).resolve().parent
PROJECT_DIR  = LAUNCHER_DIR.parent
GODOT_PATH_FILE = LAUNCHER_DIR / "godot_path.txt"

# ---------------------------------------------------------------------------
# Recherche de l'exécutable Godot
# ---------------------------------------------------------------------------

def _find_in_glob(pattern: str) -> str | None:
    """Retourne le premier fichier exécutable correspondant au glob."""
    matches = sorted(glob.glob(os.path.expandvars(os.path.expanduser(pattern))))
    for match in matches:
        if os.path.isfile(match) and os.access(match, os.X_OK):
            return match
    return None


def find_godot() -> str | None:
    """Cherche l'exécutable Godot 4 selon la plateforme."""
    system = platform.system()

    # 1. Fichier sauvegardé
    if GODOT_PATH_FILE.exists():
        saved = GODOT_PATH_FILE.read_text().strip()
        if saved and os.path.isfile(saved) and os.access(saved, os.X_OK):
            print(c(CYAN, " [INFO] Chemin Godot chargé depuis godot_path.txt"))
            return saved

    # 2. Variable d'environnement GODOT_PATH
    env_path = os.environ.get("GODOT_PATH", "")
    if env_path and os.path.isfile(env_path) and os.access(env_path, os.X_OK):
        print(c(CYAN, " [INFO] Godot trouvé via la variable GODOT_PATH"))
        return env_path

    # 3. Chercher dans le PATH
    candidates = ["godot4", "godot"]
    if system == "Windows":
        candidates = ["godot4.exe", "godot.exe"]
    for cmd in candidates:
        import shutil
        found = shutil.which(cmd)
        if found:
            print(c(CYAN, f" [INFO] Godot trouvé dans le PATH : {found}"))
            return found

    # 4. Emplacements spécifiques à l'OS
    if system == "Windows":
        local_app = os.environ.get("LOCALAPPDATA", "")
        user_profile = os.environ.get("USERPROFILE", "")
        prog_files = os.environ.get("ProgramFiles", "C:\\Program Files")
        prog_files_x86 = os.environ.get("ProgramFiles(x86)", "C:\\Program Files (x86)")
        search_patterns = [
            f"{prog_files}\\Godot\\Godot_v4*.exe",
            f"{prog_files_x86}\\Godot\\Godot_v4*.exe",
            f"{local_app}\\Godot\\Godot_v4*.exe",
            f"{user_profile}\\Godot\\Godot_v4*.exe",
        ]
    elif system == "Darwin":
        search_patterns = [
            "/Applications/Godot.app/Contents/MacOS/Godot",
            "/usr/local/bin/godot4",
            "/usr/bin/godot4",
            "/usr/local/bin/godot",
            "/usr/bin/godot",
            "~/Godot/Godot_v4*",
        ]
    else:  # Linux
        search_patterns = [
            "/usr/bin/godot4",
            "/usr/local/bin/godot4",
            "/usr/bin/godot",
            "/usr/local/bin/godot",
            "~/Godot/Godot_v4*",
        ]

    for pattern in search_patterns:
        found = _find_in_glob(pattern)
        if found:
            print(c(CYAN, f" [INFO] Godot trouvé : {found}"))
            return found

    return None


def ask_godot_path() -> str:
    """Demande le chemin Godot à l'utilisateur et le sauvegarde."""
    print(c(YELLOW, " [ATTENTION] Godot 4 n'a pas été trouvé automatiquement."))
    print()
    print(c(WHITE, " Téléchargez Godot 4 sur : https://godotengine.org/download"))
    print(c(WHITE, " Choisissez la version 'Standard' pour votre système."))
    print()
    print(" Entrez le chemin complet vers l'exécutable Godot 4")
    if platform.system() == "Windows":
        print(" (ex: C:\\Program Files\\Godot\\Godot_v4.2.exe)")
    else:
        print(" (ex: /usr/local/bin/godot4)")
    print(" ou laissez vide pour annuler.")
    print()

    try:
        user_input = input(c(BOLD, " Chemin Godot : ")).strip()
    except (EOFError, KeyboardInterrupt):
        print()
        return ""

    if not user_input:
        return ""

    if not os.path.isfile(user_input):
        print(c(RED, f"\n [ERREUR] Fichier introuvable : {user_input}"))
        return ""

    if not os.access(user_input, os.X_OK) and platform.system() != "Windows":
        print(c(RED, f"\n [ERREUR] Fichier non exécutable : {user_input}"))
        return ""

    GODOT_PATH_FILE.write_text(user_input)
    print(c(GREEN, " [INFO] Chemin sauvegardé dans godot_path.txt"))
    return user_input

# ---------------------------------------------------------------------------
# Lancement du jeu
# ---------------------------------------------------------------------------

def launch(godot_exe: str, editor: bool = False) -> int:
    """Lance le jeu (ou l'éditeur) avec Godot."""
    cmd = [godot_exe, "--path", str(PROJECT_DIR)]
    if editor:
        cmd.append("--editor")

    print(c(GREEN, f" Projet  : {PROJECT_DIR}"))
    print(c(GREEN, f" Godot   : {godot_exe}"))
    if editor:
        print(c(YELLOW, " Mode    : Éditeur Godot"))
    print()
    print(c(BOLD, " Lancement de Ski Station Tycoon..."))
    print()

    result = subprocess.run(cmd)
    return result.returncode

# ---------------------------------------------------------------------------
# Point d'entrée
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Lanceur Ski Station Tycoon",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--editor",
        action="store_true",
        help="Ouvrir le projet dans l'éditeur Godot",
    )
    parser.add_argument(
        "--export",
        action="store_true",
        help="Préparer un export du jeu (placeholder)",
    )
    args = parser.parse_args()

    # Afficher le banner
    print(c(CYAN, BANNER))

    # Vérifier project.godot
    if not (PROJECT_DIR / "project.godot").exists():
        print(c(RED, " [ERREUR] Fichier project.godot introuvable dans :"))
        print(c(RED, f"          {PROJECT_DIR}"))
        print()
        print(" Assurez-vous que ce lanceur se trouve bien dans le")
        print(" dossier 'launcher/' du projet Ski Station Tycoon.")
        sys.exit(1)

    # Mode export (placeholder)
    if args.export:
        print(c(YELLOW, " [EXPORT] La fonctionnalité d'export n'est pas encore disponible."))
        print(" Utilisez l'éditeur Godot → Projet → Exporter pour créer un build.")
        sys.exit(0)

    # Trouver Godot
    godot_exe = find_godot()
    if not godot_exe:
        godot_exe = ask_godot_path()

    if not godot_exe:
        print()
        print(c(RED, " Lancement annulé. Godot 4 est requis."))
        sys.exit(1)

    # Lancer
    exit_code = launch(godot_exe, editor=args.editor)
    if exit_code != 0:
        print(c(RED, f"\n [ERREUR] Le jeu s'est terminé avec une erreur (code : {exit_code})"))
        sys.exit(exit_code)


if __name__ == "__main__":
    main()
