# Installing this skillset in GitHub Copilot (offline / restricted network)

This repo is a library of **51 Agent Skills** — one folder per skill under `skills/`, each with a `SKILL.md` at its root (frontmatter `name` + `description`, which is the format GitHub Copilot reads). No skill needs internet access, an API key, or a build step.

Use this guide when Copilot **cannot reach github.com** (e.g. a company-restricted environment). Everything Copilot needs is inside the downloaded ZIP.

## VS Code: requirements and scope (read first)

- **Version:** Agent Skills are generally available and **enabled by default in VS Code 1.109 (January 2026) and later**. Use the latest VS Code your company allows; on anything older the skills may silently not load. The installer and the verifier both check the `code` version and warn below 1.109. (Reference: VS Code docs, "Use Agent Skills in VS Code".)
- **Scope — personal by default, so it applies to ALL workspaces:** this guide's default installs into your **personal** skills folder, `~/.copilot/skills/` (Windows: `%USERPROFILE%\.copilot\skills\`). Per the VS Code docs, personal skills live in your home directory and are available **across all workspaces** — they are *not* tied to any single project. The project location (`<project>/.github/skills/`) is the per-workspace option and is only used if you explicitly pass `--project` / `-Project`.
- **One copy only:** VS Code also scans `~/.claude/skills/` and `~/.agents/skills/`. If you previously installed some of these skills there (or into a workspace), you'll get duplicates in the skills list. The verifier (§6) detects this; keep the copy in `~/.copilot/skills/` and remove the others.
- **If skills don't show up:** start a **new chat session** (skills are scanned at session start), check via **Chat: Open Customizations → Skills** (personal skills appear under **User**), or type `/` in chat. Also confirm `chat.useAgentSkills` is not set to `false` in settings — a company managed-settings policy can disable it, in which case no install location will work until IT allows it.

---

## What you need

1. This repo downloaded as a ZIP from GitHub (**Code → Download ZIP**) and extracted. Extraction gives you a folder like `adhd_combo_skillset-main/` — that folder is the *repo root* used below. Keep its structure exactly as extracted; do not rename or move the `skills/` subfolders.
2. One of:
   - a terminal (macOS/Linux: `sh`; Windows: PowerShell), **or**
   - Copilot itself in agent mode, following the manual fallback in §5.

No Node.js, Python or package installs are required. The installer scripts use only `sh`/`diff`/`cp` (macOS/Linux) or built-in PowerShell cmdlets (Windows).

## Where Copilot reads skills from

| Scope | Location |
|---|---|
| **Personal (default in this guide — all workspaces)** | `~/.copilot/skills/<skill-name>/SKILL.md` |
| Project (one workspace only, shared with the repo/team) | `<your-project>/.github/skills/<skill-name>/SKILL.md` |

Copilot also reads the legacy `.claude/skills` and `.agents/skills` locations; the installer can target any of them with `--target` / `-Target`. Pick **one** location — installing the same skill into two locations Copilot scans can load it twice.

A skill only loads if `SKILL.md` sits **directly** inside its named folder (`.../skills/tdd/SKILL.md` ✅, `.../skills/skills/tdd/SKILL.md` ❌, `.../skills/tdd-main/SKILL.md` ❌). The installer guarantees this layout, and verifies it afterwards.

---

## 1. Easiest path: give Copilot this prompt

Open Copilot Chat in agent mode, point it at the extracted folder, and paste:

```text
Install the Agent Skills from the extracted folder <PATH-TO/adhd_combo_skillset-main> into my Copilot skills.

Rules:
1. First CHECK what I already have. The target is ~/.copilot/skills (personal)
   — or <PROJECT>/.github/skills if I say project scope.
2. Install at PERSONAL scope (~/.copilot/skills) so the skills apply to ALL
   VS Code workspaces, not just one project, unless I explicitly say project.
3. For each folder in <PATH>/skills/ that contains a SKILL.md:
   - If the skill is NOT in the target, copy the whole folder in.
   - If it IS in the target, compare every file. If identical, leave it alone.
     If any file differs, replace the target folder with the repo version,
     after copying the old version to a backup folder outside the skills
     directory (skills-backup/<today's date>/).
   - Never delete or modify any skill in the target that is not in this repo.
4. If shell access is available, do this by running the repo's own script
   instead of copying by hand:
   - macOS/Linux:  sh <PATH>/scripts/install-skills.sh [--project <PROJECT>]
   - Windows:      powershell -ExecutionPolicy Bypass -File <PATH>\scripts\install-skills.ps1 [-Project <PROJECT>]
5. Afterwards VERIFY and report: how many skills were added, updated, already
   up to date; confirm the total from this repo is 51; and confirm each
   installed skill has a SKILL.md whose frontmatter name matches its folder.
6. Do not access the internet. Everything needed is in the extracted folder.
   Also run <PATH>/scripts/verify-install.sh (or verify-install.ps1 on
   Windows) at the end and include its RESULT line in your report.
```

## 2. Scripted install (terminal)

Run from anywhere; the script finds `skills/` relative to itself.

**Personal scope (default — all VS Code workspaces):**

```sh
# macOS / Linux
sh scripts/install-skills.sh
```

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File scripts\install-skills.ps1
```

**Project scope** (skills land in `<project>/.github/skills/`):

```sh
sh scripts/install-skills.sh --project /path/to/your-project
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install-skills.ps1 -Project C:\path\to\your-project
```

**Check first, change nothing** — see exactly what would be added/updated:

```sh
sh scripts/install-skills.sh --check          # exit code 1 if changes are pending
sh scripts/install-skills.sh --dry-run        # same report, exit code 0
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install-skills.ps1 -Check
```

**Other options:** `--target DIR` / `-Target DIR` (custom skills directory), `--only a,b` / `-Only a,b`, `--exclude a,b` / `-Exclude a,b`, `--no-backup` / `-NoBackup`. Run with `--help` (sh) or read the header of the `.ps1` for the full list.

## 3. Exactly what the installer does (the check you asked for)

For every one of the 51 skills, on every run:

| State in target | Action |
|---|---|
| Not present | **ADDED** — whole folder copied |
| Present, all files identical | **SKIPPED** — reported `UP TO DATE`, nothing written |
| Present, any file differs (older version, edited copy) | **UPDATED** — old folder first copied to `<skills-parent>/skills-backup/<timestamp>/`, then replaced with the repo version |
| Present in target but **not** in this repo | **UNTOUCHED** — your other skills are never deleted or modified |

Comparison is a full recursive diff (sh) / per-file SHA-256 (PowerShell) — not timestamps, which ZIP extraction makes meaningless. Re-running the installer when everything is current reports 51 × `UP TO DATE` and changes nothing, so the safe way to "update to the latest version" later is simply: download a fresh ZIP, extract, re-run the same command.

After copying, the script verifies every installed skill: `SKILL.md` exists and its frontmatter `name` matches the folder name (a Copilot requirement). It prints a summary (`added / updated / up-to-date / failed / verify-failures`) and exits non-zero if anything failed.

## 4. The always-on core in Copilot (read this — it differs from Claude Code)

In Claude Code, the i-have-adhd + caveman + ponytail core is forced on by plugin hooks. **Copilot has no equivalent hook**, so in Copilot those three skills trigger like any other skill (by description match or when you invoke them by name). To make the core effectively always-on in a **project**, merge the distilled core rules into the project's Copilot instructions:

```sh
sh scripts/install-skills.sh --project /path/to/project --with-instructions
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install-skills.ps1 -Project C:\path\to\project -WithInstructions
```

This appends the block from `copilot/copilot-instructions.snippet.md` to `<project>/.github/copilot-instructions.md`, wrapped in `<!-- BEGIN/END adhd-combo core -->` markers. Re-running replaces only that marked block; the rest of your instructions file is untouched. For personal scope, paste the snippet's contents into your personal Copilot instructions file manually.

## 5. Manual fallback (no script execution allowed)

If company policy blocks running scripts, Copilot (agent mode) or you can do exactly what the script does, by hand:

1. List the folders in the repo's `skills/` — there are 51, each containing `SKILL.md`.
2. List the folders already in the target skills directory. Note them; anything there that is not in step 1's list must not be touched.
3. For each repo skill missing from the target: copy the entire folder into the target.
4. For each repo skill already present: compare file by file (names, then contents/hashes). Identical → leave it. Different → copy the present folder to a backup location outside the skills directory, delete the present folder, copy the repo folder in.
5. Verify: target now contains all 51 repo skill folders, each with `SKILL.md` directly inside, and each `SKILL.md`'s frontmatter `name` equals its folder name.
6. Restart the Copilot session so it rescans the skills directories.

## 6. Verify it worked

Run the standalone verifier — it checks completeness, the VS Code file-format spec, duplicates in other scanned locations, your VS Code version, and the `chat.useAgentSkills` setting:

```sh
sh scripts/verify-install.sh                      # personal scope
sh scripts/verify-install.sh --workspace /path/to/a/workspace   # also check that workspace for duplicates
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts\verify-install.ps1
```

Expect the last line to read `RESULT: PASS`. Then, in VS Code:

1. Start a **new chat session** (skills are scanned at session start).
2. Run **Chat: Open Customizations → Skills**: all 51 skills should be listed under **User** (personal) — visible from any workspace you open, which is how you confirm the all-workspaces scope took effect.
3. Type `/` in chat and invoke one, e.g. `/tdd`, and give it a small task.
4. Spot-check one folder: `~/.copilot/skills/tdd/SKILL.md` exists and its first lines are YAML frontmatter starting with `name: tdd`.

## 7. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Skills don't appear in Copilot | VS Code older than 1.109 → update. Session started before install → start a new session. `chat.useAgentSkills: false` (possibly company managed settings) → enable it / ask IT. Or wrong nesting — `SKILL.md` must be directly in `skills/<name>/`, not one level deeper (common after manual ZIP copying: you copied the repo's `skills/` folder *into* an existing `skills/` folder). Re-run the installer to fix layout. |
| PowerShell: "running scripts is disabled" | Use the `-ExecutionPolicy Bypass -File ...` form in §2 (per-process only, changes no machine policy), or use the §5 manual fallback. |
| A skill loads twice / behaves doubled | It's installed in two scanned locations (e.g. both `~/.copilot/skills` and `~/.claude/skills`, or a workspace's `.github/skills`). Run the verifier (§6) — it lists duplicates. Keep the personal copy in `~/.copilot/skills/`; the installer only manages the target you point it at. |
| Skills work in one workspace but not another | They were installed at project scope (`.github/skills` inside one repo). Re-run the installer with no `--project` flag to install at personal scope (`~/.copilot/skills`), which applies to all workspaces. |
| Installer reports `WOULD UPDATE` for a skill you edited locally | Your local edits differ from the repo version. Updating overwrites them — your old copy is preserved in `skills-backup/<timestamp>/` unless you passed `--no-backup`. To keep local edits instead, exclude it: `--exclude <name>`. |
| `diff` errors / weird characters in paths (Windows, sh script) | Use the PowerShell script on Windows; the `sh` script targets macOS/Linux. |
| Copilot says it can't find the repo / asks to browse GitHub | It is working from the repo name instead of the local files. Re-state the extracted folder's absolute path and rule 5 of the §1 prompt: no internet, local files only. |

## 8. Updating later

Download a fresh ZIP of the repo, extract it (overwriting or beside the old extraction), and re-run the same install command from the **new** extraction. Only skills whose files changed are updated; everything else reports `UP TO DATE`. Your backups accumulate under `skills-backup/` — delete old timestamps freely.
