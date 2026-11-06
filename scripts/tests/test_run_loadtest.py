"""Focused checks for the optional, manually invoked load pilot."""
import importlib.util
import contextlib
import io
from pathlib import Path
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "run_loadtest.py"
spec = importlib.util.spec_from_file_location("run_loadtest", SCRIPT)
pilot = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pilot)


class LoadPilotTests(unittest.TestCase):
    def options(self, *args):
        return pilot.parse_args(["--godot", "godot.exe", *args])

    def test_default_is_two_bots_and_no_human(self):
        options = self.options()
        self.assertEqual(options.players, 2)
        self.assertFalse(options.human)

    def test_rejects_counts_without_existing_highrise_spawns(self):
        for count in (0, 1, 65, 128):
            with self.subTest(count=count), contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                self.options("--players", str(count))

    def test_requested_large_bot_counts_are_supported(self):
        for count in (16, 32, 64):
            self.assertEqual(self.options("--players", str(count)).players, count)

    def test_rejects_invalid_durations_and_local_remote_host_mix(self):
        for args in (("--duration", "0"), ("--warmup", "-1"),
                     ("--host", "example.invalid"), ("--port", "0")):
            with self.subTest(args=args), contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                self.options(*args)

    def test_human_reserves_one_slot_without_increasing_room_size(self):
        options = self.options("--players", "8", "--human")
        server, clients = pilot.build_commands(options, Path("repo"), Path("run"))
        self.assertEqual(len(clients), 8)
        self.assertEqual(sum(c["mode"] == "human" for c in clients), 1)
        for client in clients:
            command = client["command"]
            self.assertEqual("--headless" in command, client["mode"] == "bot")
            self.assertIn("--loadtest-players=8", command)
            self.assertIn(f"--start-file={Path('run') / 'start'}", command)
            self.assertIn(f"--stop-file={Path('run') / 'stop'}", command)
        self.assertIn("--record-metrics", server)
        self.assertIn("--loadtest-score=10000", server)

    def test_external_server_is_not_started_by_runner(self):
        options = self.options("--external-server", "--host", "example.invalid")
        server, clients = pilot.build_commands(options, Path("repo"), Path("run"))
        self.assertIsNone(server)
        self.assertEqual(len(clients), 2)

    def test_large_ammunition_is_explicit_for_server_and_all_clients(self):
        with contextlib.redirect_stderr(io.StringIO()):
            options = self.options("--ammo", "15000")
        server, clients = pilot.build_commands(options, Path("repo"), Path("run"))
        self.assertIn("--loadtest-ammo=15000", server)
        for client in clients:
            self.assertIn("--loadtest-ammo=15000", client["command"])

    def test_bad_marker_cannot_be_mistaken_for_success(self):
        with self.assertRaises(ValueError):
            pilot.marker_payload("LOADTEST_DONE not-json", "LOADTEST_DONE ")
        self.assertIsNone(pilot.marker_payload("not ready", "LOADTEST_READY "))
        self.assertEqual(pilot.marker_payload('LOADTEST_READY {"peer_id": 8}',
                                             "LOADTEST_READY ")["peer_id"], 8)

    def test_connected_but_idle_client_does_not_validate_activity(self):
        sample = dict(mode="bot", elapsed_sec=30, snapshots=100, distance_m=0,
                      shot_attempts=10, shots=3, spawns=1, active_sec=25,
                      activity_windows_checked=2, activity_validated=True)
        with self.assertRaises(ValueError):
            pilot.validate_activity(sample, 30)
        sample["distance_m"] = 3
        pilot.validate_activity(sample, 30)
        sample["elapsed_sec"] = 5
        with self.assertRaises(ValueError):
            pilot.validate_activity(sample, 30)

    def test_early_activity_cannot_validate_a_long_idle_window(self):
        sample = dict(mode="bot", elapsed_sec=300, snapshots=100, distance_m=3,
                      shot_attempts=10, shots=1, spawns=1, active_sec=5,
                      activity_windows_checked=0, activity_validated=False)
        with self.assertRaises(ValueError):
            pilot.validate_activity(sample, 300)

    def test_real_peers_must_share_the_same_lobby_and_roster(self):
        ready = [dict(peer_id=10, players=2, lobby_name="Lobby0", roster_peer_ids=[10, 20]),
                 dict(peer_id=20, players=2, lobby_name="Lobby0", roster_peer_ids=[20, 10])]
        pilot.validate_roster(ready, 2)
        ready[1]["lobby_name"] = "Lobby1"
        with self.assertRaises(ValueError):
            pilot.validate_roster(ready, 2)
        ready[1]["lobby_name"] = "Lobby0"
        ready[1]["roster_peer_ids"] = [20, 30]
        with self.assertRaises(ValueError):
            pilot.validate_roster(ready, 2)

    def test_valid_windows_may_include_small_frame_time_overshoots(self):
        sample = dict(mode="bot", elapsed_sec=120, snapshots=500, distance_m=100,
                      shot_attempts=80, shots=100, spawns=4, active_sec=105.01,
                      activity_windows_checked=5, activity_validated=True)
        pilot.validate_activity(sample, 120)

    def test_network_summary_preserves_single_room_evidence(self):
        temporary_root = Path(__file__).resolve().parents[2] / "tmp/loadtest-unit-tests"
        temporary_root.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=temporary_root) as folder:
            path = Path(folder) / "server_network_metrics_1.csv"
            path.write_text("timestamp_ms,players_count,lobbies_count,rtt_avg_ms\n"
                            "1000,0,0,\n2000,4,1,2\n3000,4,1,3\n", encoding="utf-8")
            result = pilot.network_summary(Path(folder), 1500, 3500)
            self.assertEqual(result["samples"], 2)
            self.assertEqual(result["players_min"], 4)
            self.assertEqual(result["lobbies_max"], 1)


if __name__ == "__main__":
    unittest.main()
