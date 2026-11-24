# adhd_combo_skillset

A personal, batteries-included **skill library for AI coding agents** — 43 skills in one repo, built around an always-on core that changes *how* the agent replies and writes code in every session.

It started as one thing: a Claude Code plugin that keeps **i-have-adhd + caveman + ponytail** switched on at all times. It has since grown into the single source of truth for every skill its owner actually uses — the original combo, Matt Pocock's engineering workflow set, and a handful of hand-picked standalone skills — all vendored here so they can be installed, copied and kept in sync across Claude Code, Muse, OpenMausBot bots and other agents that read `SKILL.md` files.

> **In one line:** install once, and every session answers action-first and token-lean, writes the smallest safe change — and has a full spec → tickets → implement → review workflow on tap when the work gets serious.

---

## Why / benefits

| Problem | What this repo does about it |
|---|---|
| Agent replies bury the next step in paragraphs | **i-have-adhd** shapes every reply: next action first, numbered steps, state restated, lists of 5 or fewer |
| Verbose output wastes tokens and reading time | **caveman** strips filler; code, paths and errors stay verbatim |
| Agents over-engineer and rewrite half the repo | **ponytail** enforces the smallest complete change — and never cuts validation or security |
| Three style skills would fight each other | **adhd-combo** is the referee: one clash rule set, i-have-adhd wins on reply shape |
| "Vibe coding" falls apart on real projects | The **Matt Pocock set** adds the missing engineering loop: spec, tickets, TDD, code review, domain modelling, triage, handoffs |
| Skills scattered across a dozen upstream repos | **One repo, vendored copies, pinned provenance** — clone it and you have the whole working set, offline, versioned |
| Same setup repeated on every machine / bot | Copy a skill folder, install the plugin, or run `scripts/add-to-repo.py` — the same 43 skills everywhere |

Nothing here phones home. The hooks are POSIX `sh`, there is no Node.js dependency for the core plugin, and every skill is plain Markdown you can read before you trust it.

---

## What's inside — all 43 skills

### 1. The always-on core (4)

Loaded by hooks at every session start. This is the original plugin.

| Skill | Decides | Invoke / notes |
|---|---|---|
| **adhd-combo** | The clash rules that let the three below run together | `/adhd-combo` re-enables all three; `/adhd-combo status` shows what's on |
| **i-have-adhd** | Reply shape: next action first, numbered steps, restated state, specific time estimates, wins made visible | On by default; `stop adhd mode` turns it off |
| **caveman** | Wording: terse, no filler, technical facts verbatim | `/caveman`, levels incl. `ultra` and `wenyan` (文言文) |
| **ponytail** | Code: lazy senior dev — smallest change that fully solves the task | `/ponytail lite\|full\|ultra` |

### 2. Caveman & Ponytail families — on demand (7)

| Skill | What it does |
|---|---|
| **caveman-commit** | Conventional Commits message, compressed to intent only |
| **caveman-review** | Code review, one line per finding: location, problem, fix |
| **ultracave** | Caveman at maximum compression — fragments, each fact once |
| **megacave** | Caveman in Classical Chinese (文言文), technical terms verbatim |
| **ponytail-review** | Quality review of a change: logic, safety, load, tests, speed, and whether every line earns its place |
| **ponytail-audit** | Whole-repo quality audit — bugs, security holes, untested risk, slow paths, what to delete/merge/split. Report only, changes nothing |
| **ponytail-debt** | Ledger of every `shortcut:` / `ponytail:` comment in the repo. Report only |

### 3. Engineering workflow — the Matt Pocock set (27)

A complete loop for taking real work from idea to shipped, reviewed code. Start with **ask-matt** if you don't know which one you need — it's a router over the whole set. Run **setup-matt-pocock-skills** once per repo before first use (configures the issue tracker, triage labels and domain-doc layout the others expect).

**Plan & specify**

| Skill | What it does |
|---|---|
| **ask-matt** | Router: asks your situation, points you at the right skill or flow in this repo |
| **wayfinder** | Plans work too big for one session as a shared map of decision tickets, resolved one at a time |
| **grilling** | Relentlessly interviews you to stress-test a plan, decision or idea |
| **grill-me** | The grilling interview, as a standalone sharpening session |
| **grill-with-docs** | Grilling that also writes ADRs and glossary entries as you go |
| **to-spec** | Turns the current conversation into a spec on the issue tracker — synthesis, no interview |
| **to-tickets** | Breaks a plan/spec into tracer-bullet tickets with blocking edges, published to the tracker |
| **to-questionnaire** | Turns a decision you can't answer alone into a questionnaire for someone else |
| **domain-modeling** | Builds/sharpens the project's domain model: `GLOSSARY.md` terminology and ADRs |
| **codebase-design** | Shared vocabulary for designing deep modules: interfaces, seams, testability, AI-navigability |

**Build & verify**

| Skill | What it does |
|---|---|
| **implement** | Implements a piece of work from a spec or set of tickets |
| **implement-spec** | Implements the output of `/to-spec` + `/to-tickets` |
| **tdd** | Test-driven development: red-green-refactor, integration tests |
| **prototype** | Throwaway prototype to answer a design question — state/logic or UI |
| **diagnosing-bugs** | Disciplined diagnosis loop for hard bugs and performance regressions |
| **code-review** | Reviews changes since a fixed point on two axes: repo standards, and match against the spec/issue |
| **improve-codebase-architecture** | Scans for deepening opportunities, presents a visual HTML report, then grills through your pick |

**Run the project**

| Skill | What it does |
|---|---|
| **triage** | Moves issues and external PRs through a triage state machine; verifies, grills if needed, writes agent-ready briefs |
| **pr** | Writes a proper PR body |
| **handoff** | Compacts the current conversation into a handoff doc another agent can pick up |
| **retro** | Retrospective on a coding session |
| **research** | Investigates a question against high-trust primary sources; findings saved as Markdown in the repo |
| **teach** | Teaches you a new skill or concept, in this workspace, with mission/resources/glossary records |
| **wizard** | Generates an interactive bash wizard for steps only a human can do (provisioning, credentials, dashboards) |
| **writing-for-agents** | How to write documents agents actually follow — skills, `AGENTS.md`, `CLAUDE.md` |
| **wait-what** | "That last message didn't land — re-pitch it." Recovery for misunderstood instructions |
| **setup-matt-pocock-skills** | One-time per-repo setup for the engineering skills above |

**A typical flow:** `wayfinder` / `grilling` → `to-spec` → `to-tickets` → `implement` (+ `tdd`) → `code-review` → `pr` → `handoff` / `retro`. The always-on core shapes every reply throughout.

### 4. Standalone additions (5)

| Skill | What it does | Source |
|---|---|---|
| **karpathy-guidelines** | Behavioural guardrails against common LLM coding mistakes: no overcomplication, surgical changes, surface assumptions, verifiable success criteria | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) |
| **archify** | Validated architecture / workflow / sequence / data-flow / lifecycle / ERD / class / tree / timeline diagrams as explorable standalone HTML, with dark/light themes, motion and SVG/WebM export | [tt-a1i/archify](https://github.com/tt-a1i/archify) |
| **security-audit** | Security guidance and vulnerability review for codebases, APIs, services, CLIs and daemons — recon, attack classes, cloud/deployment, supply chain, with coverage-ledger and findings validators | [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) |
| **browser-use-fastlane** | Fast browser automation for **public, no-login** web tasks via browser-use (seconds per task instead of ~a minute). Never for logged-in, account or payment work | Written for this repo |
| **markitdown** | Wrapper for Microsoft MarkItDown: converts PDF, Word, Excel, PowerPoint, images, audio, HTML and EPub files to Markdown for LLM use, notes and indexing (tool installed via pip, not vendored; first pass only for precision tables) | [microsoft/markitdown](https://github.com/microsoft/markitdown) |

---

## Install & use

### Option A — Claude Code plugin (the always-on core)

Send these as two separate prompts in Claude Code:

```
/plugin marketplace add alanlee7219/adhd_combo_skillset
```

```
/plugin install adhd-combo@adhd-combo
```

Start a new session. i-have-adhd, caveman and ponytail are on, and the repo's other skills are available to invoke.

- No Node.js needed. Hooks are POSIX `sh`; on Windows they need Git Bash.
- Uninstall the upstream caveman, ponytail and i-have-adhd plugins first, or their rules load twice.

### Option B — Cloud sessions (claude.ai/code, the Claude app's Code tab, scheduled tasks)

Cloud sessions don't install plugins a repo declares in `.claude/settings.json`, but they do load the repo's `.claude/skills/` and the hooks in its `.claude/settings.json` (single-repository sessions). Copy adhd-combo into each repo:

```
python3 scripts/add-to-repo.py /path/to/your-repo
```

Then commit the repo's `.claude/` and push.

- Run it again to update the copy. Add `--remove` to take it out.
- Your other skills and settings stay as they are. Same-named skills are never overwritten.
- If the plugin is also installed on your machine, the repo copy stays quiet, so the rules load once.

### Option B2 — GitHub Copilot, offline / company-restricted (ZIP install)

If Copilot cannot reach github.com, download this repo as a ZIP, extract it, and follow **[INSTALL_COPILOT.md](INSTALL_COPILOT.md)**. The default install is **personal scope (`~/.copilot/skills`)**, so in VS Code (1.109+, latest recommended) the skills apply to **all workspaces**, not just one project; `scripts/verify-install.sh` / `.ps1` run the full post-install check. It includes a paste-ready prompt for Copilot itself, plus installer scripts (`scripts/install-skills.sh` / `scripts/install-skills.ps1`) that **check first**: missing skills are added, outdated skills are updated to the repo version (old copy backed up), identical skills are skipped, and skills you already have from elsewhere are never touched. The core-instructions snippet for Copilot lives in `copilot/copilot-instructions.snippet.md`.

### Option C — Pick individual skills (any agent)

Every skill is a self-contained folder under `skills/<name>/` with a `SKILL.md` at its root. Copy the folders you want into wherever your agent reads skills from — e.g. `~/.claude/skills/` for Claude Code, your agent's custom-skills directory, or import them into OpenMausBot per bot via its skills API (`POST /api/bots/<botId>/skills`, then enable each one). Skills marked user-invoked in their frontmatter only run when you call them; the rest trigger on their description.

### Switches (always-on core)

| Say or type | Effect |
|---|---|
| `normal mode` | All three off |
| `/adhd-combo` | All three back on |
| `/adhd-combo status` | One line: what is on |
| `stop adhd mode` / `stop caveman` / `stop ponytail` | One skill off |
| `/caveman ultra` · `/caveman wenyan` · `/ponytail lite\|full\|ultra` | Change one skill's level |

---

## How it works

- `hooks/hooks.json` runs `hooks/inject.sh` on SessionStart (startup, resume, clear, compact). One hook per skill keeps each output under Claude Code's 10,000-character limit per hook.
- Subagents get caveman and ponytail through SubagentStart.
- Only the core is forced on. Everything else is invoked or triggered on demand, so the 43-skill library costs no context until you use it.
- `sh tests/test-hooks.sh` checks every hook output. `python3 tests/test_add_to_repo.py` checks the repo copy script.

## Repository layout

```
.claude-plugin/   marketplace.json + plugin.json (name: adhd-combo, v1.1.0)
skills/           all 43 skills, one folder each, SKILL.md at the root
hooks/            SessionStart / SubagentStart injection for the always-on core
scripts/          add-to-repo.py (cloud sessions) + install-skills.sh/.ps1 (Copilot / Agent Skills installer)
copilot/          copilot-instructions.snippet.md — the always-on core as a Copilot instructions block
INSTALL_COPILOT.md  offline ZIP install guide for GitHub Copilot, incl. paste-ready prompt
tests/            hook-output and add-to-repo tests
third_party/      upstream licenses for the vendored originals
NOTICE.md         provenance for the original bundle (see also Credits below)
LICENSE           MIT for this repo's own files
```

## Adding a skill (maintainer notes)

This repo is the single source of truth, and new skills are rolled out three ways, every time:

1. **Muse** — install into the local custom-skills directory and verify it's searchable/usable.
2. **OpenMausBot** — import per bot via the skills API (or replicate the workspace folder + skill-state entry), enable each skill, verify counts via the API.
3. **GitHub** — push the skill folder under `skills/<name>/` here and read it back to verify.

Keep each skill's upstream source and license in its folder, and update the tables above in the same commit.

## Not included

From the original upstreams: statuslines, stats, mode-tracking hooks, the ponytail band, cavecrew agents, and the caveman CLI and cloud features. For those, use the upstream plugins instead of this one.

## Credits and licenses

Unofficial bundle. Not affiliated with or endorsed by the upstream authors. "Caveman" is a trademark of Julius Brussee.

| Bundled from | Skills | License |
|---|---|---|
| [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) | caveman, ultracave, megacave, caveman-commit, caveman-review | Apache-2.0 |
| [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | ponytail, ponytail-review, ponytail-audit, ponytail-debt | MIT |
| [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) | i-have-adhd | MIT |
| [mattpocock/skills](https://github.com/mattpocock/skills) | the 27-skill engineering set | See upstream |
| [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | karpathy-guidelines | See upstream |
| [tt-a1i/archify](https://github.com/tt-a1i/archify) | archify | See folder (`LICENSE`, `NOTICE`) |
| [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | security-audit | See upstream |

Exact commits and license texts for the original three: [NOTICE.md](NOTICE.md) and `third_party/`. Everything else in this repo is MIT ([LICENSE](LICENSE)).

## 中文快速說明

呢個 repo 係一套個人 AI agent 技能庫，共 **43 個 skills**，核心係常開組合：

1. **常開核心**：每個 session 自動開 i-have-adhd（回覆結構：下一步行先）、caveman（措辭精簡）、ponytail（最小而完整嘅 code 改動）；三者衝突時跟 i-have-adhd。用 `normal mode` 全部關，`/adhd-combo` 全部重開。
2. **工程流程（Matt Pocock 27 個）**：`ask-matt` 做路由器；`wayfinder`／`grilling` 規劃 → `to-spec` → `to-tickets` → `implement`／`tdd` → `code-review` → `pr` → `handoff`。
3. **獨立精選**：karpathy-guidelines（防 LLM 常見 coding 錯誤）、archify（架構圖 HTML）、security-audit（安全審計）、browser-use-fastlane（公開網頁快速自動化）、markitdown（文件轉 Markdown）。

安裝：Claude Code 分兩次輸入上面 Option A 兩行指令，再開新 session；雲端 session 用 `scripts/add-to-repo.py` 複製入 repo 嘅 `.claude/`；其他 agent 直接抄 `skills/<name>/` 資料夾即可。
