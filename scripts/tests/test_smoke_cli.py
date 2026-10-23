"""CLI guardrails: fail clearly before attempting a connection."""
from pathlib import Path
import subprocess
import unittest


class SmokeCliTests(unittest.TestCase):
    def test_invalid_port_is_rejected_before_starting_godot(self):
        script = Path(__file__).resolve().parents[1] / "smoke-test.sh"
        result = subprocess.run(["bash", str(script), "localhost", "0"],
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Invalid port", result.stderr)

    def test_unbounded_timeout_is_rejected(self):
        script = Path(__file__).resolve().parents[1] / "smoke-test.sh"
        result = subprocess.run(["bash", str(script), "localhost", "7777", "0"],
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Invalid timeout", result.stderr)


if __name__ == "__main__":
    unittest.main()
