"""Opt in on a Linux Docker host with DEPLOY_TEST_IMAGE=<existing local runtime>."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import uuid


@unittest.skipUnless(os.environ.get("DEPLOY_TEST_IMAGE"), "Set DEPLOY_TEST_IMAGE for real Docker deployment tests")
class DockerDeploymentTests(unittest.TestCase):
    def test_real_enet_failure_restores_previous_container(self):
        source = Path(__file__).resolve().parents[2]
        spec = importlib.util.spec_from_file_location("deploy_integration", source / "scripts/deploy_server.py")
        deploy = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(deploy)
        with tempfile.TemporaryDirectory(prefix="jumpnshoot-deploy-test-") as temporary:
            directory = Path(temporary)
            good = directory / "good.yaml"
            bad = directory / "bad.yaml"
            text = (source / "compose.prod.yaml").read_text()
            good.write_text(text)
            # Server boots, but the published port forwards to a port without an ENet listener.
            bad.write_text(text.replace(":7777/udp", ":7778/udp"))
            state = {"image": os.environ["DEPLOY_TEST_IMAGE"], "port": 17992,
                     "bind_address": "127.0.0.1", "compose_file": str(good)}
            broken = dict(state, compose_file=str(bad))
            manager = deploy.Deployer(directory, "jumpnshoot-test-" + uuid.uuid4().hex[:8])
            actual_run = deploy.run

            def local_run(command, **kwargs):
                # No registry publication/login required: only pull/digest validation are substituted.
                if command[:2] == ["docker", "pull"]:
                    return "Using existing local test image"
                return actual_run(command, **kwargs)

            with patch.object(deploy, "validate_image", side_effect=lambda image: image), \
                    patch.object(deploy, "run", side_effect=local_run):
                try:
                    with self.assertRaisesRegex(RuntimeError, "first deployment failed"):
                        manager.deploy(broken)
                    self.assertFalse((directory / "current.json").exists())
                    # A failed first attempt must not prevent retrying the same managed project.
                    manager.deploy(state)
                    with self.assertRaisesRegex(RuntimeError, "rollback completed"):
                        manager.deploy(broken)
                    self.assertEqual(json.loads((directory / "current.json").read_text()), state)
                    manager.verify(state)
                finally:
                    manager.compose(state, "down", "--remove-orphans")
