"""Install verified official Godot editor and only the required export templates."""
import hashlib
from pathlib import Path
import tempfile
import urllib.request
import zipfile

RELEASE = "4.5.1-stable"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{RELEASE}"
DOWNLOADS = {
    "Godot_v4.5.1-stable_linux.x86_64.zip":
        "02ec53d1cc7dbb9cc6355393c61b9ab43d1244751a124f10248a4802830788cd",
    "Godot_v4.5.1-stable_export_templates.tpz":
        "1998af37f1387684e2c211cdb483daf492fc64dc6b12096bddcdca25b6910c86",
}
TEMPLATES = {"linux_release.x86_64", "windows_release_x86_64.exe",
             "windows_release_x86_64_console.exe", "version.txt"}
template_dir = Path("/opt/godot/templates/4.5.1.stable")
template_dir.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory() as temp:
    for filename, checksum in DOWNLOADS.items():
        archive = Path(temp) / filename
        print(f"Downloading {filename}", flush=True)
        urllib.request.urlretrieve(f"{BASE}/{filename}", archive)
        with archive.open("rb") as stream:
            actual = hashlib.file_digest(stream, "sha256").hexdigest()
        if actual != checksum:
            raise RuntimeError(f"Checksum mismatch: {filename}")
        with zipfile.ZipFile(archive) as package:
            for member in package.namelist():
                name = Path(member).name
                destination = None
                if filename.endswith(".zip") and name == "Godot_v4.5.1-stable_linux.x86_64":
                    destination = Path("/usr/local/bin/godot")
                elif filename.endswith(".tpz") and name in TEMPLATES:
                    destination = template_dir / name
                if destination:
                    destination.write_bytes(package.read(member))
                    destination.chmod(0o755)
        archive.unlink()
