#!/usr/bin/env python3
"""Copy adhd-combo into a repository's .claude/ so cloud sessions load it.

Cloud sessions (claude.ai/code, the Code tab in the Claude app, scheduled
tasks) don't install plugins that a repo declares in .claude/settings.json.
They do load the repo's .claude/skills/ and the hooks in .claude/settings.json.

Usage: python3 scripts/add-to-repo.py <repo-dir> [--remove]
Run it again to update the copy. --remove takes everything back out.
"""
import json
import shutil
import subprocess
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent
SKILLS = sorted(p.parent.name for p in (SRC / "skills").glob("*/SKILL.md"))
SCRIPT = ".claude/adhd-combo/inject.sh"  # marks the hook entries this script owns
SESSION = ["adhd-combo", "i-have-adhd", "caveman", "ponytail"]
SUBAGENT = ["caveman", "ponytail"]

README = """# adhd-combo (repo copy)

Copied from https://github.com/alanlee7219/adhd_combo_skillset (commit {commit})
by `scripts/add-to-repo.py`. Cloud Claude Code sessions don't install plugins
a repo declares, so the skills live in `../skills/` and the hooks in
`../settings.json`.

- Update: run `python3 scripts/add-to-repo.py <this repo>` from a fresh checkout of adhd_combo_skillset
- Remove: the same command with `--remove`
- With the adhd-combo plugin installed for your user, these hooks stay quiet, so the rules load once
- Licenses: `third_party/` and `NOTICE.md`
"""


def hook(event, skill):
    return {
        "type": "command",
        "command": f'sh "$CLAUDE_PROJECT_DIR/{SCRIPT}" {event} {skill} project',
        "timeout": 10,
    }


def strip_ours(hooks):
    """Drop this script's hook entries; keep everything else as it was."""
    for event in list(hooks):
        groups = []
        for group in hooks[event]:
            entries = group.get("hooks", [])
            kept = [h for h in entries if SCRIPT not in str(h.get("command", ""))]
            if len(kept) == len(entries):
                groups.append(group)
            elif kept:
                groups.append({**group, "hooks": kept})
        if groups:
            hooks[event] = groups
        else:
            del hooks[event]


def main():
    args = [a for a in sys.argv[1:] if a != "--remove"]
    remove = len(args) < len(sys.argv) - 1
    if len(args) != 1 or not Path(args[0]).is_dir():
        sys.exit(__doc__)
    claude = Path(args[0]).resolve() / ".claude"
    home = claude / "adhd-combo"
    settings_path = claude / "settings.json"

    settings = {}
    if settings_path.exists():
        try:
            settings = json.loads(settings_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as err:
            sys.exit(f"{settings_path} is not plain JSON ({err}). Edit it by hand.")
    if not isinstance(settings, dict) or not isinstance(settings.get("hooks", {}), dict):
        sys.exit(f"{settings_path}: unexpected shape. Edit it by hand.")

    manifest = home / "skills.txt"
    ours = set(manifest.read_text().split()) if manifest.exists() else set()
    clash = [n for n in SKILLS if (claude / "skills" / n).exists() and n not in ours]
    if clash and not remove:
        sys.exit("Not overwriting project skills with the same names: " + ", ".join(clash))

    for name in ours:
        shutil.rmtree(claude / "skills" / name, ignore_errors=True)
    shutil.rmtree(home, ignore_errors=True)
    hooks = settings.setdefault("hooks", {})
    strip_ours(hooks)

    if not remove:
        for name in SKILLS:
            shutil.copytree(SRC / "skills" / name, claude / "skills" / name)
        home.mkdir(parents=True)
        shutil.copy2(SRC / "hooks" / "inject.sh", home / "inject.sh")
        shutil.copytree(SRC / "third_party", home / "third_party")
        shutil.copy2(SRC / "NOTICE.md", home / "NOTICE.md")
        manifest.write_text("\n".join(SKILLS) + "\n")
        commit = subprocess.run(["git", "-C", str(SRC), "rev-parse", "HEAD"],
                                capture_output=True, text=True).stdout.strip() or "unknown"
        (home / "README.md").write_text(README.format(commit=commit))
        hooks.setdefault("SessionStart", []).append({
            "matcher": "startup|resume|clear|compact",
            "hooks": [hook("session", s) for s in SESSION],
        })
        hooks.setdefault("SubagentStart", []).append({
            "hooks": [hook("subagent", s) for s in SUBAGENT],
        })

    if not hooks:
        del settings["hooks"]
    if settings:
        settings_path.parent.mkdir(parents=True, exist_ok=True)
        settings_path.write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n",
                                 encoding="utf-8")
    elif settings_path.exists():
        settings_path.unlink()
    for empty in (claude / "skills", claude):
        if empty.is_dir() and not any(empty.iterdir()):
            empty.rmdir()
    print(("Removed adhd-combo from " if remove else "Added adhd-combo to ") + str(claude))


if __name__ == "__main__":
    main()
