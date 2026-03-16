# 🎿 Lanceur — Ski Station Tycoon

Ce dossier contient les lanceurs permettant de démarrer facilement **Ski Station Tycoon** sans ouvrir manuellement l'éditeur Godot.

---

## Prérequis

Téléchargez **Godot 4.2+** (version Standard) depuis :
👉 **https://godotengine.org/download**

> Choisissez la version correspondant à votre système d'exploitation (Windows, Linux ou macOS).

---

## Lancer le jeu

### 🪟 Windows — `launch.bat`

Double-cliquez sur le fichier `launcher/launch.bat` ou exécutez-le depuis l'Explorateur Windows.

Le script :
1. Recherche automatiquement Godot 4 dans les emplacements courants.
2. Si Godot n'est pas trouvé, vous demande d'entrer le chemin manuellement.
3. Lance le jeu via `godot --path <projet>`.

```bat
cd launcher
launch.bat
```

---

### 🐧 Linux / 🍎 macOS — `launch.sh`

Ouvrez un terminal, rendez le script exécutable (une seule fois), puis lancez-le :

```bash
chmod +x launcher/launch.sh
./launcher/launch.sh
```

---

### 🐍 Python (cross-platform) — `launch.py`

Nécessite **Python 3.9+** (inclus par défaut sur macOS et la plupart des Linux).

```bash
python3 launcher/launch.py
```

#### Options disponibles

| Option | Description |
|--------|-------------|
| *(aucune)* | Lance le jeu normalement |
| `--editor` | Ouvre le projet dans l'éditeur Godot |
| `--export` | Affiche les instructions d'export |

Exemples :
```bash
# Lancer le jeu
python3 launcher/launch.py

# Ouvrir l'éditeur Godot
python3 launcher/launch.py --editor
```

---

## Configurer le chemin Godot manuellement

Si le lanceur ne trouve pas Godot automatiquement, deux options s'offrent à vous :

### Option 1 — Saisie interactive
Les lanceurs vous demanderont le chemin lors du premier lancement et le mémoriseront dans `launcher/godot_path.txt`.

### Option 2 — Variable d'environnement
Définissez la variable `GODOT_PATH` pointant vers l'exécutable Godot :

```bash
# Linux / macOS
export GODOT_PATH="/usr/local/bin/godot4"

# Windows (PowerShell)
$env:GODOT_PATH = "C:\Program Files\Godot\Godot_v4.2.exe"
```

### Option 3 — Fichier `godot_path.txt`
Créez (ou modifiez) le fichier `launcher/godot_path.txt` avec le chemin absolu vers Godot :

```
C:\Program Files\Godot\Godot_v4.2-stable_win64.exe
```

---

## Fichier `godot_path.txt`

Ce fichier est **auto-généré** par les lanceurs lors de la première saisie du chemin Godot.  
Il est listé dans `.gitignore` à la racine du projet et **ne sera jamais commité** dans le dépôt.

---

## Dépannage

| Problème | Solution |
|----------|----------|
| "Godot non trouvé" | Installez Godot 4.2+ et relancez, ou définissez `GODOT_PATH` |
| "project.godot introuvable" | Vérifiez que le dossier `launcher/` est bien dans la racine du projet |
| Le jeu ne démarre pas | Vérifiez que vous utilisez Godot **4.x** et non Godot 3.x |
| Erreur de permission (Linux/macOS) | Exécutez `chmod +x launcher/launch.sh` |
