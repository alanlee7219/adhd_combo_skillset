#!/usr/bin/env python3
"""Checks scripts/add-to-repo.py. Run: python3 tests/test_add_to_repo.py"""
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOL = [sys.executable, str(ROOT / "scripts" / "add-to-repo.py")]
ORIGINAL = {
    "permissions": {"allow": ["Bash(ls:*)"]},
    "hooks": {"SessionStart": [{"hooks": [{"type": "command", "command": "echo mine"}]}]},
}
failures = 0


def check(ok, what):
    global failures
    print(("ok   " if ok else "FAIL ") + what)
    failures += not ok


def run_hooks(repo, config_dir):
    """Run every adhd-combo hook command the way Claude Code would."""
    settings = json.loads((repo / ".claude" / "settings.json").read_text())
    env = {**os.environ, "CLAUDE_PROJECT_DIR": str(repo), "CLAUDE_CONFIG_DIR": str(config_dir)}
    out = []
    for groups in settings["hooks"].values():
        for group in groups:
            for h in group["hooks"]:
                if "adhd-combo" in h["command"]:
                    r = subprocess.run(["sh", "-c", h["command"]], capture_output=True,
                                       text=True, env=env, timeout=h["timeout"])
                    out.append((r.returncode, r.stdout))
    return out


with tempfile.TemporaryDirectory() as tmp:
    repo = Path(tmp) / "my repo"
    (repo / ".claude" / "skills" / "mine").mkdir(parents=True)
    (repo / ".claude" / "skills" / "mine" / "SKILL.md").write_text("---\nname: mine\n---\n")
    (repo / ".claude" / "settings.json").write_text(json.dumps(ORIGINAL))

    # 1. Install twice: idempotent, other settings and skills kept.
    for _ in range(2):
        r = subprocess.run(TOOL + [str(repo)], capture_output=True, text=True)
    check(r.returncode == 0, "install runs twice")
    s = json.loads((repo / ".claude" / "settings.json").read_text())
    ours = [g for g in s["hooks"]["SessionStart"] if "adhd-combo" in json.dumps(g)]
    check(s["permissions"] == ORIGINAL["permissions"], "permissions kept")
    check(len(s["hooks"]["SessionStart"]) == 2 and len(ours) == 1, "one adhd-combo SessionStart group, user group kept")
    check(len(ours[0]["hooks"]) == 4 and len(s["hooks"]["SubagentStart"][0]["hooks"]) == 2, "4 session hooks, 2 subagent hooks")
    check((repo / ".claude" / "skills" / "mine" / "SKILL.md").exists(), "existing project skill untouched")
    check((repo / ".claude" / "skills" / "i-have-adhd" / "SKILL.md").exists(), "bundled skills copied")

    # 2. Hooks print the rules (path has a space), under the 10,000-char cap.
    empty_config = Path(tmp) / "config"
    empty_config.mkdir()
    out = run_hooks(repo, empty_config)
    check(len(out) == 6 and all(code == 0 and 0 < len(text) < 10000 for code, text in out),
          "6 hooks print rules under the cap")
    json.loads(out[-1][1])  # subagent output is JSON

    # 3. Plugin installed for the user: repo copy stays quiet.
    plugin_config = Path(tmp) / "config-with-plugin"
    (plugin_config / "plugins").mkdir(parents=True)
    (plugin_config / "plugins" / "installed_plugins.json").write_text(
        json.dumps({"version": 2, "plugins": {"adhd-combo@adhd-combo": [{"scope": "user"}]}}))
    check(all(code == 0 and text == "" for code, text in run_hooks(repo, plugin_config)),
          "quiet when the plugin is installed")

    # 4. Remove: back to the original settings, own files gone, user skill kept.
    r = subprocess.run(TOOL + [str(repo), "--remove"], capture_output=True, text=True)
    s = json.loads((repo / ".claude" / "settings.json").read_text())
    check(r.returncode == 0 and s == ORIGINAL, "remove restores settings")
    check(not (repo / ".claude" / "adhd-combo").exists()
          and not (repo / ".claude" / "skills" / "caveman").exists()
          and (repo / ".claude" / "skills" / "mine").exists(), "remove deletes only its own files")

    # 5. A same-named skill that isn't ours: refuse.
    other = Path(tmp) / "other"
    (other / ".claude" / "skills" / "caveman").mkdir(parents=True)
    r = subprocess.run(TOOL + [str(other)], capture_output=True, text=True)
    check(r.returncode != 0 and "Not overwriting" in r.stderr, "refuses to overwrite a foreign skill")

    # 6. Fresh repo without .claude/: install then remove leaves nothing behind.
    fresh = Path(tmp) / "fresh"
    fresh.mkdir()
    subprocess.run(TOOL + [str(fresh)], capture_output=True, text=True)
    subprocess.run(TOOL + [str(fresh), "--remove"], capture_output=True, text=True)
    check(not (fresh / ".claude").exists(), "fresh repo: remove leaves nothing")

print("all checks passed" if not failures else f"{failures} failed")
sys.exit(1 if failures else 0)
