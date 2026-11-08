"""Test installer discovery, safety, and deployment using isolated fixtures.

Mocked commands avoid changing host packages or configuration. Only script copies
have system paths redirected; production installers have no test-mode bypass.
"""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

REPOSITORY = Path(__file__).resolve().parents[1]
MOCK = r'''
import json, os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["CALLS"], "a") as file:
    file.write(json.dumps([name, *args]) + "\n")
version = os.environ.get("OFFERED", "5.9-1")
if name == "zsh":
    if os.environ.get("BROKEN_ZSH"):
        sys.exit(2)
    if args == ["--version"]:
        print(os.environ.get("ZSH_OUTPUT", "zsh 5.9 (fixture)"))
elif name == "uname":
    print(os.environ.get("PLATFORM", "Linux") if args == ["-s"] else "x86_64")
elif name == "id":
    print("1000")
elif name == "sudo":
    os.execvp(args[0], args)
elif name == "apt-cache":
    print("  Candidate: " + version)
elif name == "dnf" and "repoquery" in args:
    if os.environ.get("QUERY_FAIL"):
        sys.exit(2)
    print(version)
elif name == "pacman" and "-Si" in args:
    print("Version : " + version)
elif name == "brew" and "info" in args:
    print("==> zsh: stable " + version + " (bottled)")
elif name == "brew" and "--prefix" in args:
    print(os.environ["BREW_PREFIX"])
elif name in ("apt-get", "dnf", "pacman", "brew"):
    if "install" in args or "-S" in args:
        if os.environ.get("INSTALL_FAIL"):
            sys.exit(2)
        target = pathlib.Path(os.environ["INSTALLED_ZSH"])
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(os.environ["MOCK_SCRIPT"])
        target.chmod(0o755)
elif name == "git":
    if "fetch" in args and os.environ.get("FETCH_FAIL"):
        sys.exit(2)
    if "init" in args:
        (pathlib.Path(args[-1]) / ".git").mkdir(parents=True)
'''


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="zsh-fixture.")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.repo = self.root / "repo"
        (self.repo / "zsh").mkdir(parents=True)
        self.calls_file = self.root / "calls"
        self.shells = self.root / "shells"
        self.shells.write_text("/bin/sh\n/missing/zsh\n")
        self.os_release = self.root / "os-release"
        self.os_release.write_text('ID=ubuntu\n')
        self.system_paths = [self.root / "system" / str(i) / "zsh" for i in range(5)]
        for path in self.system_paths:
            path.parent.mkdir(parents=True)
        self.installed = self.system_paths[1]
        self.mock_script = f"#!{sys.executable}\n" + MOCK
        for name in ("uname", "id", "sudo", "apt-get", "apt-cache", "dnf", "pacman", "brew", "git", "fzf"):
            self.mock(self.bin / name)
        # An allowlist of real utilities, deliberately excluding the host's Zsh.
        for name in ("dirname", "awk", "sort", "env", "mktemp", "rm", "mkdir", "mv", "ln"):
            executable = shutil.which(name)
            self.assertIsNotNone(executable, f"fixture needs {name}")
            (self.bin / name).symlink_to(executable)
        source = (REPOSITORY / "zsh/install.sh").read_text()
        replacements = {
            "SHELLS_FILE=/etc/shells": f'SHELLS_FILE="{self.shells}"',
            "OS_RELEASE_FILE=/etc/os-release": f'OS_RELEASE_FILE="{self.os_release}"',
            "SYSTEM_ZSH_PATHS='/bin/zsh /usr/bin/zsh /usr/local/bin/zsh /opt/homebrew/bin/zsh /opt/local/bin/zsh'":
                "SYSTEM_ZSH_PATHS='" + " ".join(map(str, self.system_paths)) + "'",
            "installed_zsh=/usr/bin/zsh": f'installed_zsh="{self.installed}"',
            "[ ! -e /run/ostree-booted ]": f'[ ! -e "{self.root}/ostree-booted" ]',
        }
        for old, new in replacements.items():
            self.assertEqual(source.count(old), 1, f"fixture path must track production: {old}")
            source = source.replace(old, new)
        (self.repo / "zsh/install.sh").write_text(source)
        shutil.copyfile(REPOSITORY / "bootstrap.sh", self.repo / "bootstrap.sh")
        for name in (".zshrc", ".zprofile", ".p10k.zsh"):
            shutil.copyfile(REPOSITORY / "zsh" / name, self.repo / "zsh" / name)
        self.env = {
            "HOME": str(self.home), "PATH": str(self.bin), "SHELL": "/bin/sh",
            "CALLS": str(self.calls_file), "MOCK_SCRIPT": self.mock_script,
            "INSTALLED_ZSH": str(self.installed), "BREW_PREFIX": str(self.root / "brew"),
        }

    def mock(self, path):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(self.mock_script)
        path.chmod(0o755)

    def run_script(self, script="zsh/install.sh", *args):
        return subprocess.run(["/bin/sh", str(self.repo / script), *args],
                              env=self.env, cwd=self.root, text=True,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=20)

    def calls(self):
        if not self.calls_file.exists():
            return []
        return [json.loads(line) for line in self.calls_file.read_text().splitlines()]

    def snapshot(self):
        return {str(p.relative_to(self.home)):
                ("link", os.readlink(p)) if p.is_symlink() else
                ("dir",) if p.is_dir() else ("file", p.read_bytes())
                for p in self.home.rglob("*")}

    def refusal(self, expected, code=1):
        before = self.snapshot()
        result = self.run_script()
        self.assertEqual(result.returncode, code, result.stdout)
        self.assertIn(expected, result.stdout)
        self.assertIn("README.md#existing-installations", result.stdout)
        self.assertEqual(before, self.snapshot())
        self.assertFalse(any(c[0] in ("apt-get", "apt-cache", "dnf", "pacman", "brew", "sudo", "git")
                             for c in self.calls()), self.calls())

    def test_path_skip_does_not_require_zsh_login_shell_or_package_manager(self):
        self.mock(self.bin / "zsh")
        (self.home / ".zshrc").write_text("keep my existing shell\n")
        self.refusal("SKIPPED", code=0)

    def test_conventional_locations_outside_path(self):
        for path in self.system_paths:
            with self.subTest(path=path):
                self.mock(path)
                self.refusal(str(path), code=0)
                path.unlink()

    def test_registered_shell(self):
        custom = self.root / "custom" / "zsh"
        self.mock(custom)
        self.shells.write_text(f"/missing/zsh\n{custom}")
        self.refusal(str(custom), code=0)

    def test_shell_environment(self):
        custom = self.root / "another location" / "zsh"
        self.mock(custom)
        self.env["SHELL"] = str(custom)
        self.refusal(str(custom), code=0)

    def test_local_bin(self):
        custom = self.home / ".local/bin/zsh"
        self.mock(custom)
        self.refusal(str(custom), code=0)

    def test_broken_candidate(self):
        self.system_paths[0].symlink_to(self.root / "missing")
        self.refusal("cannot execute")

    def test_non_executable_candidate_on_path(self):
        (self.bin / "zsh").write_text("not executable")
        self.refusal("cannot execute")

    def test_failed_candidate(self):
        self.mock(self.bin / "zsh")
        self.env["BROKEN_ZSH"] = "1"
        self.refusal("candidate failed")

    def test_wrong_executable(self):
        self.mock(self.bin / "zsh")
        self.env["ZSH_OUTPUT"] = "not actually zsh"
        self.refusal("unexpected version")

    def test_unreadable_shell_registry(self):
        if os.getuid() == 0:
            self.skipTest("root can read permission-denied files")
        self.shells.chmod(0)
        self.refusal("cannot read")

    def test_broken_shell_registry(self):
        self.shells.unlink()
        self.shells.symlink_to(self.root / "missing")
        self.refusal("cannot read")

    def test_unsearchable_candidate_directory(self):
        if os.getuid() == 0:
            self.skipTest("root bypasses directory permissions")
        directory = self.system_paths[0].parent
        directory.chmod(0)
        self.addCleanup(directory.chmod, 0o755)
        self.refusal("cannot search Zsh candidate directory")

    def test_destination_conflicts(self):
        for name in (".zshrc", ".zprofile", ".p10k.zsh", ".oh-my-zsh", ".zshenv", ".zlogin", ".zlogout"):
            for kind in ("file", "directory", "broken link"):
                with self.subTest(name=name, kind=kind):
                    path = self.home / name
                    if kind == "file":
                        path.write_text("preserve")
                    elif kind == "directory":
                        path.mkdir()
                    else:
                        path.symlink_to(self.root / "missing")
                    self.refusal("existing destination")
                    path.rmdir() if kind == "directory" else path.unlink()

    def test_redirected_layouts(self):
        for name in ("ZDOTDIR", "ZSH", "ZSH_CUSTOM"):
            with self.subTest(name=name):
                self.env[name] = str(self.root / "custom")
                self.refusal(f"custom {name}")
                del self.env[name]

    def test_success_and_repeat_skip(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("INSTALLED", result.stdout)
        for name in (".zshrc", ".zprofile", ".p10k.zsh"):
            link = self.home / name
            self.assertTrue(link.is_symlink())
            self.assertEqual(link.resolve(strict=True), (self.repo / "zsh" / name).resolve(strict=True))
        self.assertTrue((self.home / ".oh-my-zsh/custom/plugins/fzf-tab/.git").is_dir())
        self.assertFalse(list(self.home.glob(".dotfiles-zsh.*")))
        self.assertEqual(sum("fetch" in c for c in self.calls()), 5)
        self.calls_file.unlink()
        self.refusal("SKIPPED", code=0)

    def test_platform_families(self):
        for family, manager in (("ubuntu", "apt-get"), ("fedora", "dnf"), ("arch", "pacman")):
            with self.subTest(family=family):
                self.os_release.write_text(f'ID=derivative\nID_LIKE="{family}"\n')
                result = self.run_script()
                self.assertEqual(result.returncode, 0, result.stdout)
                self.assertIn(f"using {manager}", result.stdout)
                calls = self.calls()
                if manager == "pacman":
                    self.assertFalse(any("-Sy" in c or "-Syu" in c for c in calls))
                self.installed.unlink()
                for path in self.home.iterdir():
                    shutil.rmtree(path) if path.is_dir() and not path.is_symlink() else path.unlink()
                self.calls_file.unlink()

    def test_homebrew_absent_shell_branch(self):
        self.env.update(PLATFORM="Darwin", OFFERED="5.9", INSTALLED_ZSH=str(self.root / "brew/bin/zsh"))
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("using brew", result.stdout)
        self.assertFalse(any(c[0] == "sudo" for c in self.calls()))

    def test_unsupported_family(self):
        self.os_release.write_text("ID=unrelated\nID_LIKE=unknown\n")
        self.refusal("unsupported Linux family")

    def test_immutable_family(self):
        self.os_release.write_text("ID=fedora\n")
        (self.root / "ostree-booted").touch()
        self.refusal("immutable/OSTree")

    def test_missing_package_manager(self):
        (self.bin / "apt-get").unlink()
        self.refusal("must already be installed")

    def test_supported_version_limits(self):
        for version in ("4.9", "5.7.1", "6.0", "5", "5.9-rc1", "5.9\n Candidate: 6.0", "(none)"):
            with self.subTest(version=version):
                self.env["OFFERED"] = version
                result = self.run_script()
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn("unsupported Zsh", result.stdout)
                self.assertFalse(self.installed.exists())
                self.assertEqual(self.snapshot(), {})
        self.env["OFFERED"] = "1:5.8.1-ubuntu1"
        self.assertEqual(self.run_script().returncode, 0)

    def test_package_failure_preserves_config(self):
        self.env["INSTALL_FAIL"] = "1"
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("README.md#verification-and-partial-failures", result.stdout)
        self.assertEqual(self.snapshot(), {})

    def test_plugin_failure_never_activates_configs(self):
        self.env["FETCH_FAIL"] = "1"
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("README.md#verification-and-partial-failures", result.stdout)
        self.assertEqual(self.snapshot(), {})
        self.assertTrue(self.installed.exists())
        self.calls_file.unlink()
        self.refusal("SKIPPED", code=0)

    def test_installed_version_is_checked_before_activation(self):
        self.env["ZSH_OUTPUT"] = "zsh 6.0"
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.snapshot(), {})

    def test_root_launcher_skip_continues_and_errors_stop(self):
        launcher = self.repo / "bootstrap.sh"
        # Inject a future second tool only in this fixture to exercise sequencing.
        source = launcher.read_text()
        self.assertEqual(source.count("for tool in zsh; do"), 1)
        launcher.write_text(source.replace("for tool in zsh; do", "for tool in zsh sentinel; do"))
        (self.repo / "sentinel").mkdir()
        (self.repo / "sentinel/install.sh").write_text("printf 'SENTINEL ran\\n'\n")
        self.mock(self.bin / "zsh")
        # The launcher uses sh on PATH; use the real shell, not an installer mock.
        (self.bin / "sh").symlink_to("/bin/sh")
        result = self.run_script("bootstrap.sh")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("SENTINEL ran", result.stdout)
        self.env["BROKEN_ZSH"] = "1"
        result = self.run_script("bootstrap.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("SENTINEL ran", result.stdout)
        self.assertIn("stopping bootstrap", result.stdout)

    def test_help_and_removed_flags(self):
        for script in ("zsh/install.sh", "bootstrap.sh"):
            self.assertEqual(self.run_script(script, "--help").returncode, 0)
            self.assertNotEqual(self.run_script(script, "--links-only").returncode, 0)
        self.assertEqual(self.calls(), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
