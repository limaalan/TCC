"""Deployment transitions: a failed update must never become the current release."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        path = Path(__file__).resolve().parents[1] / "deploy_server.py"
        self.assertTrue(path.is_file(), "Deployment script is not implemented yet")
        spec = importlib.util.spec_from_file_location("deploy_server", path)
        self.deploy = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.deploy)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.compose = self.root / "compose.prod.yaml"
        self.compose.write_text("services: {}\n")
        self.old = self.state("a")
        self.new = self.state("b")
        self.manager = self.deploy.Deployer(self.root, "jumpnshoot")

    def state(self, character):
        return {"image": "ghcr.io/limaalan/jumpnshoot-server@sha256:" + character * 64,
                "compose_file": str(self.compose), "port": 17777, "bind_address": "127.0.0.1"}

    def current(self):
        return json.loads((self.root / "current.json").read_text())

    def seed(self):
        (self.root / "current.json").write_text(json.dumps(self.old))

    def test_mutable_tag_or_shell_input_is_rejected_before_docker(self):
        for image in ("ghcr.io/limaalan/jumpnshoot-server:latest", "$(echo injected)"):
            with self.subTest(image=image), self.assertRaises(ValueError):
                self.deploy.validate_image(image)

    def test_failed_pull_does_not_interrupt_running_release(self):
        self.seed()
        with patch.object(self.manager, "prepare", side_effect=RuntimeError("pull failed")), \
                patch.object(self.manager, "apply") as apply:
            with self.assertRaisesRegex(RuntimeError, "pull failed"):
                self.manager.deploy(self.new)
        apply.assert_not_called()
        self.assertEqual(self.current(), self.old)

    def test_success_records_previous_release_only_after_health_check(self):
        self.seed()
        with patch.object(self.manager, "prepare"), patch.object(self.manager, "apply"), \
                patch.object(self.manager, "verify") as verify:
            self.manager.deploy(self.new)
        verify.assert_called_once_with(self.new)
        self.assertEqual(self.current(), self.new)
        self.assertEqual(json.loads((self.root / "previous.json").read_text()), self.old)

    def test_failed_update_restores_previous_and_still_fails_deployment(self):
        self.seed()
        with patch.object(self.manager, "prepare"), patch.object(self.manager, "apply") as apply, \
                patch.object(self.manager, "verify", side_effect=[RuntimeError("ENet failed"), None]):
            with self.assertRaisesRegex(RuntimeError, "rollback completed"):
                self.manager.deploy(self.new)
        self.assertEqual([call.args[0] for call in apply.call_args_list], [self.new, self.old])
        self.assertEqual(self.current(), self.old)

    def test_failed_first_deployment_stops_only_its_service(self):
        with patch.object(self.manager, "prepare"), patch.object(self.manager, "apply"), \
                patch.object(self.manager, "verify", side_effect=RuntimeError("ENet failed")), \
                patch.object(self.manager, "stop") as stop:
            with self.assertRaisesRegex(RuntimeError, "first deployment failed"):
                self.manager.deploy(self.new)
        stop.assert_called_once_with(self.new)
        self.assertFalse((self.root / "current.json").exists())

    def test_failed_rollback_is_reported_without_claiming_success(self):
        self.seed()
        with patch.object(self.manager, "prepare"), patch.object(self.manager, "apply"), \
                patch.object(self.manager, "verify", side_effect=RuntimeError("ENet failed")):
            with self.assertRaisesRegex(RuntimeError, "rollback FAILED"):
                self.manager.deploy(self.new)
        self.assertEqual(self.current(), self.old)

    def test_state_write_failure_restores_previous_running_release(self):
        self.seed()
        with patch.object(self.manager, "prepare"), patch.object(self.manager, "apply") as apply, \
                patch.object(self.manager, "verify"), \
                patch.object(self.manager, "write_state", side_effect=OSError("disk full")):
            with self.assertRaisesRegex(RuntimeError, "rollback completed"):
                self.manager.deploy(self.new)
        self.assertEqual([call.args[0] for call in apply.call_args_list], [self.new, self.old])
        self.assertEqual(self.current(), self.old)


if __name__ == "__main__":
    unittest.main()
