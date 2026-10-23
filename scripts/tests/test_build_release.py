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
        (target / "shrooter-client.exe").write_bytes(b"exe")
        (target / "dependency.dll").write_bytes(b"dll")
        metadata = {"version": "local", "commit": "abc123", "godot": "4.5.1"}
        archive = self.builder.package_target(target, "windows", metadata, self.root)
        with zipfile.ZipFile(archive) as package:
            self.assertIn("dependency.dll", package.namelist())
            self.assertEqual(json.loads(package.read("BUILD.json")), metadata)

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
