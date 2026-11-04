from pathlib import Path
import shutil


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "static"
DESTINATION = ROOT / "public" / "static"

if not SOURCE.is_dir():
    raise SystemExit(f"Le dossier des ressources est introuvable : {SOURCE}")

shutil.copytree(SOURCE, DESTINATION, dirs_exist_ok=True)
print(f"Ressources Vercel préparées dans {DESTINATION}")
