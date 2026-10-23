import importlib.util
from pathlib import Path
import unittest


class ExportSmokeTests(unittest.TestCase):
    def setUp(self):
        path = Path(__file__).resolve().parents[1] / "test_exports.py"
        self.assertTrue(path.is_file(), "Export smoke runner is not implemented yet")
        spec = importlib.util.spec_from_file_location("export_smoke", path)
        self.smoke = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.smoke)

    def test_success_marker_does_not_hide_script_errors(self):
        with self.assertRaises(RuntimeError):
            self.smoke.check_log("SCRIPT ERROR: broken map\nEXPORT_MATCH_OK\n", "EXPORT_MATCH_OK")

    def test_missing_marker_is_not_success(self):
        with self.assertRaises(RuntimeError):
            self.smoke.check_log("Godot started\n", "EXPORT_MATCH_OK")

    def test_known_engine_shutdown_resource_warning_is_reported_separately(self):
        log = "EXPORT_MATCH_OK\nERROR: 2 resources still in use at exit (run with --verbose for details).\n"
        warnings = self.smoke.check_log(log, "EXPORT_MATCH_OK")
        self.assertEqual(len(warnings), 1)

    def test_disconnect_error_requires_explicit_teardown_context(self):
        line = "ERROR: Unable to send packet on channel 0, max channels: 0"
        with self.assertRaises(RuntimeError):
            self.smoke.check_log("EXPORT_SERVER_READY\n" + line, "EXPORT_SERVER_READY")
        warnings = self.smoke.check_log("EXPORT_SERVER_READY\n" + line, "EXPORT_SERVER_READY",
                                        known_errors=(line,))
        self.assertEqual(warnings, [line])


if __name__ == "__main__":
    unittest.main()
