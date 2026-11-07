"""Behavioral tests for the release builder; standard library only."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        path = Path(__file__).resolve().parents[1] / "build_release.py"
        self.assertTrue(path.is_file(), "Release builder is not implemented yet")
        spec = importlib.util.spec_from_file_location("release_builder", path)
        self.builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.builder)

    def test_version_cannot_escape_output_directory(self):
        for version in ("../outside", "a/b", "", "v1\nother"):
            with self.subTest(version=version), self.assertRaises(ValueError):
                self.builder.validate_version(version)
        self.assertEqual(self.builder.validate_version("v0.1.0-rc.1"), "v0.1.0-rc.1")

    def test_snapshot_materializes_shared_without_local_cache_or_links(self):
        project = self.root / "source" / "Client"
        project.mkdir(parents=True)
        (project / "project.godot").write_text("config_version=5")
        (project / "model.blend").write_bytes(b"source")
        (project / ".godot").mkdir()
        (project / ".godot" / "stale").write_text("stale")
        shared = project.parent / "shared"
        shared.mkdir()
        (shared / "contract.gd").write_text("extends RefCounted")
        (project / "shared").symlink_to(shared, target_is_directory=True)
        outside = self.root / "secret.txt"
        outside.write_text("never package me")
        (project / "escape.txt").symlink_to(outside)
        destination = self.root / "snapshot"
        self.builder.snapshot_project(project, shared, destination)
        self.assertTrue((destination / "shared" / "contract.gd").is_file())
        self.assertFalse((destination / "shared").is_symlink())
        self.assertFalse((destination / ".godot").exists())
        self.assertFalse((destination / "escape.txt").exists())
        self.assertEqual((destination / "model.blend").read_bytes(), b"source")

    def test_engine_errors_fail_build_even_when_process_returns_zero(self):
        process = subprocess.CompletedProcess([], 0, "SCRIPT ERROR: broken resource\n")
        with patch.object(self.builder.subprocess, "run", return_value=process):
            with self.assertRaises(RuntimeError):
                self.builder.run_checked(["godot"], self.root / "import.log")

    def test_package_contains_dependencies_and_manifest(self):
        target = self.root / "client-windows"
        target.mkdir()
        (target / "jumpnshoot-client.exe").write_bytes(b"exe")
        (target / "dependency.dll").write_bytes(b"dll")
        metadata = {"version": "local", "commit": "abc123", "godot": "4.5.1"}
        archive = self.builder.package_target(target, "windows", metadata, self.root)
        with zipfile.ZipFile(archive) as package:
            self.assertIn("dependency.dll", package.namelist())
            self.assertEqual(json.loads(package.read("BUILD.json")), metadata)


    def test_build_supports_packaged_and_unpacked_linux_exports(self):
        source = self.root / "source"
        projects = source / "initial_project"
        for name in ("Client", "Server"):
            project = projects / name
            project.mkdir(parents=True)
            (project / "project.godot").write_text("config_version=5")
        shared = projects / "shared"
        shared.mkdir()
        (shared / "contract.gd").write_text("extends RefCounted")

        def fake_run(command, log):
            if "--version" in command:
                return "4.5.1.stable.official"
            if "--export-release" in command:
                executable = Path(command[-1])
                executable.parent.mkdir(parents=True, exist_ok=True)
                executable.write_bytes(b"exported binary")
            if "--script" in command:
                return "EXPORT_SERVER_READY"
            return ""

        for no_package in (False, True):
            with self.subTest(no_package=no_package):
                output = self.root / ("unpacked" if no_package else "packed")
                argv = ["build_release.py", "--source", str(source),
                        "--output", str(output), "--version", "ci-test",
                        "--commit", "a" * 40,
                        "--targets", "client-linux", "server-linux"]
                if no_package:
                    argv.append("--no-package")
                with patch("sys.argv", argv), patch.object(
                    self.builder, "run_checked", side_effect=fake_run
                ):
                    self.builder.main()

                release = output / "ci-test"
                metadata = json.loads((release / "BUILD.json").read_text())
                self.assertEqual(metadata["packaged"], not no_package)
                self.assertEqual(metadata["targets"], ["client-linux", "server-linux"])
                self.assertEqual(len(list(release.glob("*.tar.gz"))),
                                 0 if no_package else 2)
                self.assertEqual((release / "server-linux" / "BUILD.json").exists(),
                                 not no_package)
                for role in ("client", "server"):
                    executable = release / f"{role}-linux" / f"jumpnshoot-{role}.x86_64"
                    self.assertEqual(executable.read_bytes(), b"exported binary")
                for entry in (release / "SHA256SUMS").read_text().splitlines():
                    digest, relative_path = entry.split("  ", 1)
                    self.assertEqual(self.builder.sha256(release / relative_path), digest)

    def test_existing_release_is_preserved_instead_of_overwritten(self):
        staging = self.root / "staging"
        staging.mkdir()
        (staging / "partial.exe").write_bytes(b"bad")
        output = self.root / "release"
        output.mkdir()
        (output / "keep.txt").write_text("previous release")
        with self.assertRaises(FileExistsError):
            self.builder.publish_release(staging, output)
        self.assertEqual((output / "keep.txt").read_text(), "previous release")


if __name__ == "__main__":
    unittest.main()
