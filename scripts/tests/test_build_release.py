"""Behavioral tests for the release builder; standard library only."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
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

    def test_unpacked_output_preserves_manifest_instructions_and_dependencies(self):
        for platform in ("linux", "windows"):
            with self.subTest(platform=platform):
                target = self.root / f"client-{platform}"
                target.mkdir()
                (target / "dependency.bin").write_bytes(b"keep dependency")
                metadata = {"version": "preview", "commit": "abc123"}
                archive = self.builder.package_target(target, platform, metadata, self.root,
                                                      create_archive=False)
                self.assertIsNone(archive)
                self.assertEqual(json.loads((target / "BUILD.json").read_text()), metadata)
                self.assertIn("Jump'n'Shoot", (target / "README.txt").read_text())
                self.assertEqual((target / "dependency.bin").read_bytes(), b"keep dependency")
                self.assertFalse(list(self.root.glob("*.zip")))
                self.assertFalse(list(self.root.glob("*.tar.gz")))

    def test_preview_cli_builds_selected_targets_without_archives(self):
        source = self.root / "source"
        for project in ("Client", "Server", "shared"):
            directory = source / "initial_project" / project
            directory.mkdir(parents=True)
            (directory / "project.godot").write_text("config_version=5\n")

        def engine(command, log):
            if "--version" in command:
                return "4.5.1.stable.official.test"
            if "--export-release" in command:
                Path(command[-1]).write_bytes(b"exported game")
            if "--script" in command:
                return "EXPORT_SERVER_READY dedicated_server=true strip_visuals=true"
            return ""

        arguments = ["build_release.py", "--source", str(source), "--output", str(self.root / "out"),
                     "--version", "preview", "--commit", "abcdef0", "--no-package",
                     "--targets", "client-linux", "server-linux"]
        with patch.object(sys, "argv", arguments), patch.object(self.builder, "run_checked", side_effect=engine):
            self.builder.main()
        output = self.root / "out/preview"
        metadata = json.loads((output / "BUILD.json").read_text())
        self.assertFalse(metadata["packaged"])
        self.assertEqual(metadata["targets"], ["client-linux", "server-linux"])
        self.assertTrue((output / "server-linux/jumpnshoot-server.x86_64").is_file())
        self.assertFalse((output / "client-windows").exists())
        self.assertFalse(list(output.glob("*.tar.gz")))
        self.assertIn("server-linux/jumpnshoot-server.x86_64", (output / "SHA256SUMS").read_text())


if __name__ == "__main__":
    unittest.main()
