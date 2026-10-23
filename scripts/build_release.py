#!/usr/bin/env python3
"""Single release builder used locally and by CI. Python standard library only."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
import zipfile

GODOT_VERSION = "4.5.1"
TARGETS = {
    "client-windows": ("Client", "Windows Client", "shrooter-client.exe", "windows"),
    "client-linux": ("Client", "Linux Client", "shrooter-client.x86_64", "linux"),
    "server-windows": ("Server", "Windows Server", "shrooter-server.exe", "windows"),
    "server-linux": ("Server", "Linux Server", "shrooter-server.x86_64", "linux"),
}
ENGINE_ERROR = re.compile(r"(?:^|\n)(?:SCRIPT ERROR:|ERROR:|USER ERROR:)")


def validate_version(version):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,79}", version):
        raise ValueError("invalid version: use 1-80 letters, digits, dots, underscores or hyphens")
    return version


def snapshot_project(project, shared, destination):
    def ignore(directory, names):
        excluded = {".godot", ".git", "build", "__pycache__"}
        if Path(directory) == project:
            excluded.add("shared")
        return [name for name in names if name in excluded
                or (Path(directory) / name).is_symlink()
                or name.endswith((".exe", ".x86_64", ".pck", ".tmp"))]

    shutil.copytree(project, destination, ignore=ignore)
    shutil.copytree(shared, destination / "shared", ignore=ignore)


def run_checked(command, log):
    print("+", " ".join(map(str, command)), flush=True)
    result = subprocess.run(list(map(str, command)), stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, errors="replace")
    log.parent.mkdir(parents=True, exist_ok=True)
    log.write_text(result.stdout, encoding="utf-8")
    if result.returncode or ENGINE_ERROR.search(result.stdout):
        print(result.stdout[-12000:], flush=True)
        raise RuntimeError(f"Command failed ({result.returncode}); see {log}")
    print(f"OK: {log.name}", flush=True)
    return result.stdout


def package_target(directory, platform, metadata, output):
    (directory / "BUILD.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    readme = "Server" if directory.name.startswith("server") else "Client"
    instructions = f"Shrooter {readme} - {metadata['version']}\nCommit: {metadata['commit']}\n"
    if readme == "Server":
        executable = "shrooter-server.exe" if platform == "windows" else "./shrooter-server.x86_64"
        instructions += f"Run: {executable} --headless -- --port=7777\nNetwork: UDP 7777.\n"
    else:
        instructions += "Open shrooter-client and configure the server address/port in Settings.\n"
    instructions += "Use Client and Server from the same release. Keep all package files together.\n"
    (directory / "README.txt").write_text(instructions, encoding="utf-8")
    name = f"shrooter-{directory.name}-x86_64-{metadata['version']}"
    if platform == "windows":
        archive = output / f"{name}.zip"
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as package:
            for path in sorted(directory.rglob("*")):
                if path.is_file():
                    package.write(path, path.relative_to(directory).as_posix())
    else:
        archive = output / f"{name}.tar.gz"
        with tarfile.open(archive, "w:gz") as package:
            for path in sorted(directory.iterdir()):
                package.add(path, arcname=path.name)
    return archive


def publish_release(staging, destination):
    # Never replace a previous release or merge old/partial files into a new one.
    if destination.exists():
        raise FileExistsError(f"Release already exists: {destination}; choose another --version")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".publishing-", dir=destination.parent) as temp:
        ready = Path(temp) / "ready"
        shutil.copytree(staging, ready)
        ready.rename(destination)


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def get_revision(source):
    args = ["git", "-c", f"safe.directory={source}", "-C", str(source)]
    result = subprocess.run(args + ["rev-parse", "HEAD"], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError("Cannot identify commit; provide --commit for source without .git")
    dirty = subprocess.run(args + ["status", "--porcelain", "--untracked-files=all", "--",
                                  "initial_project", "scripts", "docker", "compose.yaml", ".dockerignore"],
                           capture_output=True, text=True, check=True)
    return result.stdout.strip(), bool(dirty.stdout.strip())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path, default=Path("build/releases"))
    parser.add_argument("--version", default="local")
    parser.add_argument("--commit")
    parser.add_argument("--targets", nargs="+", choices=TARGETS, default=list(TARGETS))
    parser.add_argument("--godot", default="godot")
    args = parser.parse_args()
    version = validate_version(args.version)
    source = args.source.resolve()
    destination = args.output.resolve() / version
    if destination.exists():
        parser.error(f"Release already exists: {destination}; choose another --version")
    if args.commit:
        if not re.fullmatch(r"[0-9a-fA-F]{7,40}", args.commit):
            parser.error("--commit must be a Git commit SHA")
        commit, dirty = args.commit, None
    else:
        commit, dirty = get_revision(source)
    args.output.mkdir(parents=True, exist_ok=True)
    logs = args.output.resolve() / f"{version}.logs"
    engine = run_checked([args.godot, "--version"], logs / "godot.log").strip()
    if not engine.startswith(GODOT_VERSION + ".stable."):
        raise RuntimeError(f"Expected Godot {GODOT_VERSION}.stable, got {engine}")
    metadata = {"version": version, "commit": commit, "dirty": dirty,
                "godot": engine, "architecture": "x86_64", "targets": args.targets}
    with tempfile.TemporaryDirectory(prefix="shrooter-build-") as temp:
        workspace = Path(temp)
        staging = workspace / "release"
        staging.mkdir()
        for project_name in dict.fromkeys(TARGETS[name][0] for name in args.targets):
            project = workspace / project_name
            snapshot_project(source / "initial_project" / project_name,
                             source / "initial_project" / "shared", project)
            run_checked([args.godot, "--headless", "--path", project, "--import"],
                        logs / f"{project_name.lower()}-import.log")
        for name in args.targets:
            project_name, preset, filename, platform = TARGETS[name]
            target = staging / name
            target.mkdir()
            executable = target / filename
            run_checked([args.godot, "--headless", "--path", workspace / project_name,
                         "--export-release", preset, executable], logs / f"{name}-export.log")
            if not executable.is_file() or not executable.stat().st_size:
                raise RuntimeError(f"Missing exported executable: {executable}")
            if platform == "linux":
                executable.chmod(0o755)
            if name == "server-linux":
                result = run_checked([executable, "--headless", "--script",
                                      source / "scripts/smoke/export_server.gd",
                                      "--quit-after", "3", "--", "--port=17779"],
                                     logs / "server-dedicated-check.log")
                if "EXPORT_SERVER_READY" not in result:
                    raise RuntimeError("Dedicated server/stripped resource check did not pass")
            package_target(target, platform, metadata, staging)
        (staging / "BUILD.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
        files = sorted(path for path in staging.rglob("*") if path.is_file())
        checksums = [f"{sha256(path)}  "
                     f"{path.relative_to(staging).as_posix()}\n" for path in files]
        (staging / "SHA256SUMS").write_text("".join(checksums), encoding="utf-8")
        publish_release(staging, destination)
    print(f"Release ready: {destination}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError, OSError, subprocess.SubprocessError) as error:
        raise SystemExit(str(error)) from error
