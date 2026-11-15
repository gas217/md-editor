#!/usr/bin/env python3
"""Exercise Make/score failure reporting without Xcode or a GUI session."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parent.parent


class BuildHarnessTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="mdedit-harness-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copy(REPO / "Makefile", self.root)
        (self.root / "Editor/web/src").mkdir(parents=True)
        (self.root / "Editor/web/src/editor.html").write_text("editor fixture")
        (self.root / "project.yml").touch()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}")
        for key in ("FAST_SCORE", "MAKEFLAGS", "MFLAGS", "MDEDIT_APPLE_ID"):
            self.env.pop(key, None)
        self.stub("xcodegen", "exit 0")
        self.stub("npm", """
if [[ $1 == run ]]; then
    mkdir -p ../../build/editor
    echo bundled > ../../build/editor/editor.js
fi
""")
        self.stub("xcodebuild", """
action=build
configuration=Debug
for arg in "$@"; do
    case "$arg" in build-for-testing|test-without-building|test) action=$arg ;; esac
    [[ $arg != Release ]] || configuration=Release
done
[[ ${FAIL_STAGE:-} != "$action" ]] || exit 65
products=build/Build/Products/$configuration
mkdir -p "$products/MDEditor.app/Contents/MacOS"
mkdir -p "$products/MDEditorE2ETests-Runner.app"
if [[ ${FAIL_STAGE:-} != missing-helper ]]; then
    echo helper > "$products/mdedit"
fi
""")
        self.stub("codesign", '[[ ${FAIL_STAGE:-} != signing ]]')
        self.stub("xcrun", "exit 0")

    def stub(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/bash\nset -eu\n" + body + "\n")
        path.chmod(0o755)

    def run_make(self, target, stage=""):
        return subprocess.run(
            ["make", target], cwd=self.root,
            env=dict(self.env, FAIL_STAGE=stage),
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )

    def test_e2e_success_bundles_editor_and_helper(self):
        result = self.run_make("e2e")
        self.assertEqual(result.returncode, 0, result.stdout)
        app = self.root / "build/Build/Products/Debug/MDEditor.app/Contents"
        for path in ("Resources/editor.html", "Resources/editor.js", "Helpers/mdedit"):
            self.assertTrue((app / path).is_file(), path)

    def test_failures_reach_make(self):
        for stage in ("build", "build-for-testing", "signing", "test-without-building"):
            with self.subTest(stage=stage):
                result = self.run_make("e2e", stage)
                self.assertNotEqual(result.returncode, 0, result.stdout)
        result = self.run_make("test", "test")
        self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_missing_helper_fails_build(self):
        result = self.run_make("build", "missing-helper")
        self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_assembled_bundle_signing_failures_block_both_builds(self):
        for target in ("build", "build-release"):
            with self.subTest(target=target):
                result = self.run_make(target, "signing")
                self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_release_without_credentials_checks_packaging(self):
        scripts = self.root / "scripts"
        scripts.mkdir()
        package = scripts / "build-dmg.sh"
        for exit_code in (0, 7):
            package.write_text(f"#!/bin/bash\necho packaging-invoked\nexit {exit_code}\n")
            package.chmod(0o755)
            result = self.run_make("release")
            self.assertIn("packaging-invoked", result.stdout)
            self.assertEqual(result.returncode == 0, exit_code == 0, result.stdout)

    def test_scoring_does_not_credit_stale_or_skipped_build(self):
        scripts = self.root / "scripts"
        scripts.mkdir()
        shutil.copy(REPO / "scripts/score.sh", scripts)
        # Old implementation awarded 100 merely for these leftover artifacts.
        app = self.root / "build/Build/Products/Debug/MDEditor.app/Contents"
        (app / "MacOS").mkdir(parents=True)
        (app / "Helpers").mkdir()
        helper = app / "Helpers/mdedit"
        helper.touch()
        helper.chmod(0o755)
        (self.root / "MDEditor.xcodeproj").mkdir()
        (self.root / "MDEditor.xcodeproj/project.pbxproj").touch()
        for extra in ({"FAIL_STAGE": "build"}, {"FAST_SCORE": "1"}):
            with self.subTest(extra=extra):
                result = subprocess.run(
                    ["bash", str(scripts / "score.sh")], cwd=self.root,
                    env=dict(self.env, **extra), text=True,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                )
                self.assertEqual(result.returncode, 0, result.stdout)
                score = json.loads((self.root / "score.json").read_text())
                self.assertEqual(score["dimensions"]["build_harness"], 0)
                self.assertFalse(score["gate_met"])


if __name__ == "__main__":
    unittest.main()
