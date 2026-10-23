#!/usr/bin/env python3
"""Run on a Linux Docker host: deploy a digest, verify ENet, roll back on failure."""
import argparse
import ipaddress
import json
import os
from pathlib import Path
import platform
import re
import subprocess
import tempfile
import time
import uuid
import zipfile


def validate_image(image):
    if not re.fullmatch(r"ghcr\.io/[a-z0-9][a-z0-9._/-]*@sha256:[0-9a-f]{64}", image):
        raise ValueError("Expected an immutable ghcr.io image@sha256:digest")
    return image


def run(command, env=None, timeout=120):
    result = subprocess.run(command, env=env, capture_output=True, text=True,
                            errors="replace", timeout=timeout)
    if result.returncode:
        raise RuntimeError(f"Command failed: {' '.join(map(str, command))}\n{result.stdout}{result.stderr}")
    return result.stdout + result.stderr


class Deployer:
    def __init__(self, directory, project):
        self.directory = Path(directory).resolve()
        if not re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,63}", project):
            raise ValueError("Invalid Compose project name")
        self.project = project

    def read_state(self, name):
        path = self.directory / f"{name}.json"
        if not path.exists():
            return None
        state = json.loads(path.read_text(encoding="utf-8"))
        self.validate(state)
        return state

    def validate(self, state):
        validate_image(state["image"])
        if not 1 <= state["port"] <= 65535:
            raise ValueError("Invalid game port")
        ipaddress.IPv4Address(state["bind_address"])
        compose = Path(state["compose_file"]).resolve()
        if not compose.is_relative_to(self.directory) or not compose.is_file():
            raise ValueError("Compose file must exist inside the deployment directory")

    def compose(self, state, *arguments):
        env = os.environ.copy()
        env.update(SERVER_IMAGE=state["image"], SERVER_PORT=str(state["port"]),
                   SERVER_BIND_ADDRESS=state["bind_address"])
        return run(["docker", "compose", "--project-name", self.project,
                    "--project-directory", str(self.directory), "-f", state["compose_file"],
                    *arguments], env=env)

    def prepare(self, state, previous):
        self.validate(state)
        if platform.machine() not in ("x86_64", "amd64"):
            raise RuntimeError("This release requires a Linux x86_64 VPS")
        if run(["docker", "info", "--format", "{{.Architecture}}"]).strip() not in ("x86_64", "amd64"):
            raise RuntimeError("Docker must run on x86_64")
        self.compose(state, "config", "--quiet")
        if previous is None and self.compose(state, "ps", "--all", "--quiet", "server").strip():
            raise RuntimeError("Unmanaged server exists in this Compose project; migrate it first")
        # Pull before touching a healthy running service. Uses this VPS user's Docker login.
        run(["docker", "pull", state["image"]], timeout=300)

    def apply(self, state):
        self.compose(state, "up", "-d", "--no-build", "--pull", "never", "server")

    def stop(self, state):
        # Remove only the failed first container, so a retry isn't mistaken for an unmanaged service.
        self.compose(state, "rm", "--stop", "--force", "server")

    def verify(self, state):
        # Replace the embedded game pack for this separate probe process: no Server autoload.
        # The runtime's own Godot binary can load this small ZIP without an editor on the VPS.
        probe = Path(__file__).resolve().parent / "smoke" / "enet_probe.gd"
        with tempfile.TemporaryDirectory(prefix=".probe-", dir=self.directory) as temporary:
            pack = Path(temporary) / "probe.zip"
            with zipfile.ZipFile(pack, "w") as archive:
                archive.writestr("project.godot", 'config_version=5\n[application]\nconfig/name="ENet probe"\n')
                archive.writestr(".godot/global_script_class_cache.cfg", "list=[]\n")
                archive.write(probe, "enet_probe.gd")
            pack.chmod(0o644)
            host = state["bind_address"] if state["bind_address"] != "0.0.0.0" else "127.0.0.1"
            failure = "Server did not become ready"
            for attempt in range(3):
                name = "jumpnshoot-probe-" + uuid.uuid4().hex
                try:
                    logs = self.compose(state, "logs", "--no-color", "--tail", "100", "server")
                    if "Servidor iniciado na porta 7777." not in logs:
                        raise RuntimeError("Server startup marker is missing")
                    if re.search(r"(?m)^(?:.*\| )?(?:SCRIPT ERROR:|ERROR:|USER ERROR:)", logs):
                        raise RuntimeError(f"Server reported an error:\n{logs}")
                    output = run([
                        "docker", "run", "--rm", "--name", name, "--network", "host",
                        "--read-only", "--tmpfs", "/tmp", "--cap-drop", "ALL",
                        "--security-opt", "no-new-privileges:true", "-e", "HOME=/tmp",
                        "-e", "XDG_CACHE_HOME=/tmp/cache", "-e", "XDG_DATA_HOME=/tmp/data",
                        "-e", "XDG_CONFIG_HOME=/tmp/config", "--volume", f"{pack}:/probe.zip:ro",
                        "--entrypoint", "/app/jumpnshoot-server.x86_64", state["image"],
                        "--headless", "--main-pack", "/probe.zip", "--script", "res://enet_probe.gd",
                        "--", f"--host={host}", f"--port={state['port']}", "--timeout=5",
                    ], timeout=15)
                    if "ENET_PROBE_CONNECTED" not in output or re.search(
                        r"(?m)^(?:SCRIPT ERROR:|ERROR:|USER ERROR:)", output
                    ):
                        raise RuntimeError(f"ENet verification failed:\n{output}")
                    return
                except (RuntimeError, subprocess.TimeoutExpired) as error:
                    failure = str(error)
                    if attempt < 2:
                        time.sleep(2)
                finally:
                    # Also remove a probe left behind if the Docker CLI timed out.
                    subprocess.run(["docker", "rm", "-f", name], capture_output=True, timeout=15)
            raise RuntimeError(failure)

    def write_state(self, name, state):
        path = self.directory / f"{name}.json"
        temporary = path.with_suffix(".tmp")
        temporary.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
        temporary.replace(path)

    def deploy(self, state):
        self.validate(state)
        previous = self.read_state("current")
        self.prepare(state, previous)
        try:
            self.apply(state)
            self.verify(state)
            if previous:
                self.write_state("previous", previous)
            self.write_state("current", state)
        except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
            if previous:
                try:
                    self.apply(previous)
                    self.verify(previous)
                except (RuntimeError, OSError, subprocess.TimeoutExpired) as rollback_error:
                    raise RuntimeError(f"Deploy failed: {error}; rollback FAILED: {rollback_error}") from error
                raise RuntimeError(f"Deploy failed: {error}; rollback completed") from error
            self.stop(state)
            raise RuntimeError(f"first deployment failed; service stopped: {error}") from error
        print(f"DEPLOY_OK {state['image']}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path("/opt/jumpnshoot"))
    parser.add_argument("--project", default="jumpnshoot")
    parser.add_argument("--image")
    parser.add_argument("--port", type=int, default=7777)
    parser.add_argument("--bind-address", default="0.0.0.0")
    parser.add_argument("--rollback", action="store_true")
    args = parser.parse_args()
    if bool(args.image) == args.rollback:
        parser.error("Choose --image or --rollback")
    args.directory.mkdir(parents=True, exist_ok=True)
    manager = Deployer(args.directory, args.project)
    # Shared by automatic deployments and manual rollbacks, including separate SSH sessions.
    import fcntl
    with (manager.directory / ".deploy.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("Another deployment/rollback is already running") from None
        if args.rollback:
            state = manager.read_state("previous")
            if state is None:
                raise RuntimeError("No previous successful deployment is recorded")
        else:
            state = {"image": args.image, "port": args.port, "bind_address": args.bind_address,
                     "compose_file": str(Path(__file__).resolve().parents[1] / "compose.prod.yaml")}
        manager.deploy(state)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        raise SystemExit(str(error)) from error
