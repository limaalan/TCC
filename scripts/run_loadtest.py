#!/usr/bin/env python3
"""One-room manual load pilot; not part of CI. N includes an optional human."""
import argparse
import csv
import hashlib
from datetime import datetime, timezone
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import time


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--players", type=int, default=2)
    parser.add_argument("--human", action="store_true", help="Reserve one of N slots for a graphical human")
    parser.add_argument("--duration", type=float, default=300)
    parser.add_argument("--warmup", type=float, default=30)
    parser.add_argument("--ammo", type=int, default=10000, help="Experimental spawn ammunition per weapon")
    parser.add_argument("--seed", type=int, default=20261029)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=17777)
    parser.add_argument("--preset", choices=("koth_highrise", "tdm_highrise"), default="koth_highrise")
    parser.add_argument("--external-server", action="store_true", help="Do not start or modify a remote server")
    parser.add_argument("--godot", default=shutil.which("Godot_v4.5.1-stable_win64_console.exe")
                        or shutil.which("godot") or shutil.which("godot4"))
    parser.add_argument("--logs", type=Path)
    options = parser.parse_args(argv)
    if not 2 <= options.players <= 64:
        parser.error("--players must be 2..64; experimental matches reuse existing spawn points")
    if not math.isfinite(options.duration) or not 0 < options.duration <= 3600:
        parser.error("--duration must be finite, positive and at most 3600 seconds")
    if not math.isfinite(options.warmup) or not 0 <= options.warmup <= 300:
        parser.error("--warmup must be finite and 0..300 seconds")
    if not 1 <= options.port <= 65535:
        parser.error("--port must be 1..65535")
    if not 1 <= options.ammo <= 2147483647:
        parser.error("--ammo must be 1..2147483647")
    if not options.external_server and options.host != "127.0.0.1":
        parser.error("Local server requires --host 127.0.0.1; use --external-server for a prepared server")
    if not options.godot:
        parser.error("Godot not found; provide --godot with the Godot 4.5.1 console executable")
    return options


def build_commands(options, repo, run):
    overrides = [f"--loadtest-players={options.players}",
                 f"--loadtest-duration={max(900, math.ceil(options.duration + options.warmup + 120))}",
                 "--loadtest-score=10000", f"--loadtest-ammo={options.ammo}"]
    server = None
    if not options.external_server:
        server = [str(options.godot), "--headless", "--path", str(repo / "initial_project/Server"),
                  "--log-file", str(run / "server.engine.log"), "--max-fps", "60", "--",
                  f"--port={options.port}", *overrides, "--record-metrics",
                  f"--metrics-output-dir={run / 'server-metrics'}"]
    clients = []
    for index in range(options.players):
        mode = "human" if options.human and index == 0 else "bot"
        name = f"{mode}-{index + 1}"
        command = [str(options.godot), "--path", str(repo / "initial_project/Client"),
                   "--log-file", str(run / f"{name}.engine.log"), "--max-fps", "60"]
        if mode == "bot":
            command.extend(["--headless", "--audio-driver", "Dummy"])
        command.extend(["--script", str(repo / "scripts/loadtest/client.gd"), "--",
                        f"--host={options.host}", f"--port={options.port}",
                        f"--preset={options.preset}", f"--players={options.players}",
                        f"--duration={options.duration}", f"--warmup={options.warmup}",
                        f"--seed={options.seed + index}", f"--name={name}", f"--mode={mode}",
                        f"--activity-csv={run / (name + '.csv')}",
                        f"--start-file={run / 'start'}", f"--stop-file={run / 'stop'}", *overrides])
        clients.append(dict(name=name, mode=mode, command=command))
    return server, clients


def marker_payload(text, prefix):
    for line in text.splitlines():
        if line.startswith(prefix):
            payload = json.loads(line[len(prefix):])
            if not isinstance(payload, dict):
                raise ValueError(f"Invalid {prefix.strip()} payload")
            return payload
    return None


def validate_activity(sample, duration):
    if float(sample.get("elapsed_sec", 0)) + 0.1 < duration:
        raise ValueError("Client did not complete the measurement duration")
    if int(sample.get("snapshots", 0)) < 2 or int(sample.get("spawns", 0)) < 1:
        raise ValueError("No active match/snapshots/spawn evidence")
    if sample.get("mode") == "bot":
        if (float(sample.get("distance_m", 0)) <= 1 or int(sample.get("shot_attempts", 0)) <= 0
                or int(sample.get("shots", 0)) < 1):
            raise ValueError("Connected but inactive bot: no movement/shooting evidence")
        active = float(sample.get("active_sec", 0))
        # The driver owns window boundaries (including frame overshoot and
        # respawn pauses); recomputing them as exact multiples can reject a
        # valid final remainder. Require its explicit validated verdict.
        windows = int(active >= 5)
        if (sample.get("activity_validated") is not True or active < duration * 0.5
                or int(sample.get("activity_windows_checked", 0)) < windows):
            raise ValueError("Bot did not sustain activity across the measurement window")


def validate_roster(ready, players):
    ids = [sample.get("peer_id") for sample in ready]
    if len(ids) != players or len(set(ids)) != players or any(not isinstance(peer, int) or peer <= 1 for peer in ids):
        raise ValueError("Clients did not obtain distinct real peer IDs")
    lobby = ready[0].get("lobby_name")
    if not lobby:
        raise ValueError("Missing common lobby identity")
    for sample in ready:
        if (sample.get("lobby_name") != lobby or sample.get("players") != players
                or set(sample.get("roster_peer_ids", [])) != set(ids)):
            raise ValueError("Participants are not in the same lobby/roster")


def network_summary(folder, start_ms, end_ms):
    rows = []
    for path in sorted(folder.glob("server_network_metrics_*.csv")):
        with path.open(encoding="utf-8", newline="") as source:
            rows.extend(row for row in csv.DictReader(source)
                        if start_ms <= int(row["timestamp_ms"]) <= end_ms)
    if not rows:
        return dict(samples=0)
    result = dict(samples=len(rows), players_min=min(int(row["players_count"]) for row in rows),
                  players_max=max(int(row["players_count"]) for row in rows),
                  lobbies_max=max(int(row["lobbies_count"]) for row in rows))
    for key in ("rtt_avg_ms", "rtt_max_ms", "packet_loss_avg_percent", "sent_kib_per_sec",
                "received_kib_per_sec", "server_physics_process_ms"):
        values = [float(row[key]) for row in rows if row.get(key)]
        if values:
            result[key] = dict(mean=sum(values) / len(values), max=max(values))
    return result


def read_log(path):
    return path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""


def active_errors(text):
    return [line for line in text.splitlines()
            if line.startswith(("ERROR:", "SCRIPT ERROR:", "USER ERROR:", "LOADTEST_FAILED"))]


def main(argv=None):
    options = parse_args(argv)
    repo = Path(__file__).resolve().parents[1]
    run = (options.logs or repo / "build/loadtest" /
           f"{datetime.now(timezone.utc):%Y%m%dT%H%M%S%fZ}-{options.players}p").resolve()
    # Each run gets a separate results directory.
    run.mkdir(parents=True, exist_ok=False)
    server_command, clients = build_commands(options, repo, run)
    summary = dict(status="running", host=options.host, port=options.port,
                   players=options.players, bots=options.players - int(options.human),
                   humans=int(options.human), duration_sec=options.duration, warmup_sec=options.warmup,
                   preset=options.preset, seed=options.seed, source_tree=str(repo),
                   spawn_ammunition=options.ammo,
                   server_location="external" if options.external_server else "local",
                   playability="not_assessed_automated_run", clients=[],
                   commands=dict(server=server_command, clients=clients))
    summary["source_sha256"] = {
        name: hashlib.sha256((repo / name).read_bytes()).hexdigest()
        for name in ("scripts/run_loadtest.py", "scripts/loadtest/client.gd",
                     "initial_project/shared/loadtest_config.gd",
                     "initial_project/shared/match_preset_registry.gd",
                     "initial_project/Server/server/lobby.gd",
                     "initial_project/Server/player/grenade/grenade.gd",
                     "initial_project/shared/weapons/weapon_catalog.gd")
    }
    try:
        summary["git_head"] = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo,
                                                     text=True).strip()
        summary["git_status"] = subprocess.check_output(["git", "status", "--short"], cwd=repo,
                                                       text=True)
    except (OSError, subprocess.SubprocessError):
        summary["git_head"] = "unavailable"
    processes, handles, client_records = [], [], []

    def save():
        (run / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")

    def start(command, name):
        profile = run / "profiles" / name
        profile.mkdir(parents=True)
        env = os.environ.copy()
        env.update(APPDATA=str(profile / "appdata"), LOCALAPPDATA=str(profile / "localappdata"),
                   XDG_DATA_HOME=str(profile / "data"), XDG_CONFIG_HOME=str(profile / "config"))
        log = run / f"{name}.log"
        handle = log.open("w", encoding="utf-8")
        handles.append(handle)
        process = subprocess.Popen(command, stdout=handle, stderr=subprocess.STDOUT, env=env,
                                   cwd=repo, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        processes.append(process)
        return process, log

    def wait_for_markers(prefix, timeout):
        deadline = time.monotonic() + timeout
        while True:
            payloads = []
            for process, log in client_records:
                text = read_log(log)
                failures = active_errors(text)
                if failures:
                    raise RuntimeError(f"{log.name}: {failures[0]}")
                payload = marker_payload(text, prefix)
                if process.poll() is not None:
                    raise RuntimeError(f"{log.name} exited before {prefix.strip()}")
                payloads.append(payload)
            if server_record is not None:
                if server_record[0].poll() is not None:
                    raise RuntimeError("Local server stopped unexpectedly")
                failures = active_errors(read_log(server_record[1]))
                if failures:
                    raise RuntimeError(f"Server runtime error: {failures[0]}")
            if all(p is not None for p in payloads):
                return payloads
            if time.monotonic() > deadline:
                raise RuntimeError(f"Timed out waiting for {prefix.strip()}")
            time.sleep(0.2)

    server_record = None
    save()
    print(f"Load pilot: {options.players} players, {summary['bots']} bots, {run}", flush=True)
    try:
        summary["godot_version"] = subprocess.check_output([options.godot, "--version"], text=True).strip()
        if server_command is not None:
            server_record = start(server_command, "server")
            deadline = time.monotonic() + 30
            while "Servidor iniciado na porta" not in read_log(server_record[1]):
                if server_record[0].poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError("Local server did not start; see server.log")
                time.sleep(0.2)
        for client in clients:
            client_records.append(start(client["command"], client["name"]))
            time.sleep(0.25)
        ready = wait_for_markers("LOADTEST_READY ", 90)
        validate_roster(ready, options.players)
        summary["ready"] = ready
        summary["barrier_unix_ms"] = int(time.time() * 1000)
        (run / "start").touch()
        save()
        print(f"All {options.players} clients ready; warmup then {options.duration}s measurement", flush=True)
        done = wait_for_markers("LOADTEST_DONE ", options.warmup + options.duration + 30)
        summary["end_unix_ms"] = int(time.time() * 1000)
        for sample in done:
            validate_activity(sample, options.duration)
        summary["clients"] = done
        if server_record:
            server_text = read_log(server_record[1])
            (run / "server-active.log").write_text(server_text, encoding="utf-8")
            failures = active_errors(server_text)
            if failures:
                raise RuntimeError(f"Server runtime error: {failures[0]}")
            metrics = network_summary(run / "server-metrics",
                                      summary["barrier_unix_ms"] + int(options.warmup * 1000),
                                      summary["end_unix_ms"])
            summary["network"] = metrics
            if metrics["samples"] == 0 or metrics["players_min"] != options.players or metrics["lobbies_max"] != 1:
                raise RuntimeError("Server CSV did not confirm N active players in one room")
        else:
            summary["remote_server_csv"] = "Copy from the prepared server separately; not fetched by this launcher"
        (run / "stop").touch()
        for process, log in client_records:
            if process.wait(timeout=10):
                raise RuntimeError(f"Client failed during teardown; see {log.name}")
        summary["status"] = "completed"
        summary["teardown_diagnostics"] = {log.name: active_errors(read_log(log))
                                           for _, log in [*client_records, *([server_record] if server_record else [])]
                                           if active_errors(read_log(log))}
        print("Completed automated run. CSVs retained; human playability not assessed.", flush=True)
        return 0
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        summary.update(status="failed", error=str(error))
        summary["client_failures"] = {
            log.name: active_errors(read_log(log)) for _, log in client_records
            if active_errors(read_log(log))
        }
        print(f"Load pilot failed: {error}; evidence retained at {run}", flush=True)
        return 1
    finally:
        (run / "stop").touch()
        for process in reversed(processes):
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
        for handle in handles:
            handle.close()
        save()


if __name__ == "__main__":
    raise SystemExit(main())
