#!/usr/bin/env python3
"""Exercise actual exported clients, optionally starting an exported local server."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time


def check_log(text, marker, known_errors=()):
    # Godot 4.5.1 can report retained resources during client shutdown.
    shutdown = re.compile(r"^ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.$")
    warnings = []
    for line in text.splitlines():
        if shutdown.fullmatch(line) or line in known_errors:
            warnings.append(line)
        elif line.startswith(("ERROR:", "SCRIPT ERROR:", "USER ERROR:")):
            raise RuntimeError(line)
    if marker not in text:
        raise RuntimeError(f"Missing success marker: {marker}")
    return warnings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", type=Path, required=True)
    parser.add_argument("--platform", choices=("windows", "linux"), required=True)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=17777)
    parser.add_argument("--preset", choices=("tdm_highrise", "koth_highrise"), default="tdm_highrise")
    parser.add_argument("--mode", choices=("connect", "match"), default="match")
    parser.add_argument("--local-server", action="store_true")
    parser.add_argument("--logs", type=Path, default=Path("build/smoke/exports"))
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error("--port must be 1..65535")
    if args.local_server and args.host != "127.0.0.1":
        parser.error("--local-server requires --host 127.0.0.1")
    args.logs.mkdir(parents=True, exist_ok=True)
    suffix = ".exe" if args.platform == "windows" else ".x86_64"
    release = args.release.resolve()
    client = release / f"client-{args.platform}" / f"jumpnshoot-client{suffix}"
    server = release / f"server-{args.platform}" / f"jumpnshoot-server{suffix}"
    driver = Path(__file__).resolve().parent / "smoke" / "export_client.gd"
    server_driver = driver.with_name("export_server.gd")
    processes, handles, clients = [], [], []
    with tempfile.TemporaryDirectory(prefix=".profile-", dir=args.logs.resolve()) as temp:
        def start(command, name):
            profile = Path(temp) / name
            profile.mkdir()
            env = os.environ.copy()
            env.update({"APPDATA": str(profile / "appdata"), "LOCALAPPDATA": str(profile / "localappdata"),
                        "XDG_DATA_HOME": str(profile / "data"), "XDG_CONFIG_HOME": str(profile / "config"),
                        "HOME": str(profile), "GODOT_SILENCE_ROOT_WARNING": "1"})
            log = args.logs.resolve() / f"{name}.log"
            handle = log.open("w", encoding="utf-8")
            handles.append(handle)
            process = subprocess.Popen(list(map(str, command)), stdout=handle, stderr=subprocess.STDOUT,
                                       env=env, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
            processes.append(process)
            return process, log

        try:
            if args.local_server:
                process, log = start([server, "--headless", "--script", server_driver,
                                      "--", f"--port={args.port}"], "server")
                deadline = time.monotonic() + 10
                while "EXPORT_SERVER_READY" not in log.read_text(encoding="utf-8", errors="replace"):
                    if process.poll() is not None or time.monotonic() > deadline:
                        raise RuntimeError(f"Exported server did not start; see {log}")
                    time.sleep(0.1)
            count = 2 if args.mode == "match" else 1
            for index in range(count):
                clients.append(start([client, "--headless", "--script", driver, "--",
                                      f"--host={args.host}", f"--port={args.port}",
                                      f"--preset={args.preset}", f"--mode={args.mode}",
                                      f"--name=Smoke{index + 1}"], f"client{index + 1}"))
            deadline = time.monotonic() + 45
            marker = "EXPORT_MATCH_OK" if args.mode == "match" else "EXPORT_CONNECT_OK"
            server_checked_before_teardown = False
            while any(process.poll() is None for process, _ in clients):
                if args.local_server and not server_checked_before_teardown and all(
                    marker in log.read_text(encoding="utf-8", errors="replace") for _, log in clients
                ):
                    check_log((args.logs / "server.log").read_text(encoding="utf-8", errors="replace"),
                              "EXPORT_SERVER_READY")
                    server_checked_before_teardown = True
                if time.monotonic() > deadline:
                    raise RuntimeError(f"Exported client smoke timed out; see {args.logs}")
                time.sleep(0.2)
            for process, log in clients:
                if process.returncode:
                    raise RuntimeError(f"Exported client failed ({process.returncode}); see {log}")
                warnings = check_log(log.read_text(encoding="utf-8", errors="replace"), marker)
                print(f"PASS {log}: {marker}", flush=True)
                for warning in warnings:
                    print(f"Known shutdown warning: {warning}", flush=True)
            if args.local_server:
                known_errors = ()
                if server_checked_before_teardown:
                    known_errors = ("ERROR: Unable to send packet on channel 0, max channels: 0",)
                warnings = check_log((args.logs / "server.log").read_text(encoding="utf-8", errors="replace"),
                                     "EXPORT_SERVER_READY", known_errors=known_errors)
                for warning in warnings:
                    print(f"Known server teardown warning: {warning}", flush=True)
        finally:
            for process in processes:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
            for handle in handles:
                handle.close()


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError) as error:
        raise SystemExit(str(error)) from error
