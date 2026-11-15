# adhd-combo

One Claude Code plugin. Three skills on in every session, no setup:

| Skill | Decides | Upstream | License |
|---|---|---|---|
| **i-have-adhd** | Reply shape: next action first, numbered steps, state line, lists of 5 or fewer | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) | MIT |
| **caveman** | Wording: terse, no filler; code, paths and errors verbatim | [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) | Apache-2.0 |
| **ponytail** | Code: smallest complete change; never cuts validation or security | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | MIT |

When they clash, i-have-adhd decides the shape of the reply. Clash rules: [`skills/adhd-combo/SKILL.md`](skills/adhd-combo/SKILL.md).

## Install (Claude Code)

Send these as two separate prompts:

```
/plugin marketplace add alanlee7219/adhd_combo_skillset
```

```
/plugin install adhd-combo@adhd-combo
```

Start a new session. All three are on.

- No Node.js needed. The hooks are POSIX `sh`; on Windows they need Git Bash.
- Uninstall the upstream caveman, ponytail and i-have-adhd plugins first, or their rules load twice.

## Switches

| Say or type | Effect |
|---|---|
| `normal mode` | All three off |
| `/adhd-combo` | All three back on |
| `/adhd-combo status` | One line: what is on |
| `stop adhd mode` / `stop caveman` / `stop ponytail` | One skill off |
| `/caveman ultra` · `/caveman wenyan` · `/ponytail lite\|full\|ultra` | Change one skill's level |

Also bundled: `/caveman-commit`, `/caveman-review`, `/ponytail-review`, `/ponytail-audit`, `/ponytail-debt`.

## How it works

- `hooks/hooks.json` runs `hooks/inject.sh` on SessionStart (startup, resume, clear, compact). One hook per skill keeps each output under Claude Code's 10,000-character limit per hook.
- Subagents get caveman and ponytail through SubagentStart.
- `sh tests/test-hooks.sh` checks every hook output.

## Not included

Upstream statuslines, stats, mode-tracking hooks, the ponytail band, cavecrew agents, and the caveman CLI and cloud features. For those, use the upstream plugins instead of this one.

## Credits and licenses

Unofficial bundle. Not affiliated with or endorsed by the upstream authors. "Caveman" is a trademark of Julius Brussee.

Everything under `skills/` except `skills/adhd-combo/` is an unmodified copy of upstream files. Sources, commits and licenses: [NOTICE.md](NOTICE.md) and `third_party/`. The rest of this repo is MIT ([LICENSE](LICENSE)).

## 中文快速說明

每個 Claude Code session 自動開 i-have-adhd、caveman、ponytail。三者衝突時，回覆結構跟 i-have-adhd。

1. 在 Claude Code 分兩次輸入上面兩行安裝指令
2. 開新 session
3. 說 `normal mode` 全部關；打 `/adhd-combo` 全部重開
