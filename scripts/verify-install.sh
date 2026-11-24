#!/bin/sh
# verify-install.sh — comprehensive check that the skills from this repo are
# correctly installed for GitHub Copilot / VS Code.
#
# Checks:
#   1. Target directory exists and which scope it is (personal = all workspaces)
#   2. Every repo skill is present, with SKILL.md directly inside its folder
#   3. VS Code spec: frontmatter name matches folder, name is lowercase
#      letters/numbers/hyphens and <= 64 chars, description present and
#      <= 1024 chars (violations make VS Code silently skip the skill)
#   4. Installed files are identical to this repo (no stale/partial copies)
#   5. No duplicate copies in other locations VS Code scans (double-loading)
#   6. VS Code present and >= 1.109 (Agent Skills GA, on by default), and
#      chat.useAgentSkills is not disabled in user settings
#
# Usage:
#   sh scripts/verify-install.sh [--target DIR | --project DIR]
#                                [--source DIR] [--workspace DIR]
# Exit code 0 = PASS, 1 = FAIL (warnings alone do not fail).

set -u
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_ROOT=$(dirname -- "$SCRIPT_DIR")
TARGET=""; PROJECT=""; WORKSPACE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET=$2; shift 2 ;;
    --project) PROJECT=$2; shift 2 ;;
    --source) SOURCE_ROOT=$2; shift 2 ;;
    --workspace) WORKSPACE=$2; shift 2 ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

SRC_SKILLS="$SOURCE_ROOT/skills"
[ -d "$SRC_SKILLS" ] || { echo "FAIL: no skills/ under source $SOURCE_ROOT"; exit 1; }

if [ -n "$PROJECT" ]; then TARGET="$PROJECT/.github/skills"; SCOPE="PROJECT (one workspace only)"
elif [ -z "$TARGET" ]; then TARGET="$HOME/.copilot/skills"; SCOPE="PERSONAL (all VS Code workspaces)"
else SCOPE="CUSTOM"; fi

PASS=0; FAILN=0; WARNS=0
ok()   { PASS=$((PASS+1));  echo "PASS  $1"; }
bad()  { FAILN=$((FAILN+1)); echo "FAIL  $1"; }
warn() { WARNS=$((WARNS+1)); echo "WARN  $1"; }

echo "Target : $TARGET"
echo "Scope  : $SCOPE"
echo ""

[ -d "$TARGET" ] && ok "target directory exists" || { bad "target directory missing: $TARGET"; echo ""; echo "RESULT: FAIL (target missing)"; exit 1; }

# --- per-skill checks -------------------------------------------------------
desc_len() { # unfold the YAML description scalar of $1/SKILL.md, print CHARACTER count
  # (UTF-8 aware: delete continuation bytes 0x80-0xBF, remaining bytes = chars;
  #  a plain byte count would false-fail descriptions containing CJK text)
  _s=$(awk '
    /^---[[:space:]]*$/ { fm = !fm; next }
    fm && /^description:/ {
      line=$0; sub(/^description:[[:space:]]*/, "", line); gsub(/[[:space:]]+$/, "", line)
      if (line == ">" || line == "|" || line == ">-" || line == "|-") { folded=1; next }
      buf=line; folded=0; found=1; next
    }
    folded && /^[[:space:]]+[^[:space:]]/ { s=$0; gsub(/^[[:space:]]+/, "", s); gsub(/[[:space:]]+$/, "", s); buf = buf " " s; found=1; next }
    folded { folded=0 }
    END { if (found) printf "%s", buf; else printf "%s", "" }
  ' "$1/SKILL.md")
  if [ -z "$_s" ]; then echo -1; return; fi
  printf %s "$_s" | tr -d '\200-\277' | wc -c | tr -d ' '
}

COUNT=0
for SRC in "$SRC_SKILLS"/*/; do
  NAME=$(basename -- "$SRC")
  [ -f "$SRC/SKILL.md" ] || continue
  COUNT=$((COUNT+1))
  DEST="$TARGET/$NAME"
  if [ ! -f "$DEST/SKILL.md" ]; then bad "$NAME: missing (no $DEST/SKILL.md)"; continue; fi
  # name matches folder + VS Code charset/length
  FNAME=$(sed -n 's/^name:[[:space:]]*//p' "$DEST/SKILL.md" | head -n 1 | tr -d ' \r"'"'"'')
  if [ "$FNAME" != "$NAME" ]; then bad "$NAME: frontmatter name is '$FNAME'"; continue; fi
  case "$NAME" in *[!a-z0-9-]*) bad "$NAME: name has characters VS Code rejects"; continue ;; esac
  [ ${#NAME} -le 64 ] || { bad "$NAME: name longer than 64 chars"; continue; }
  DL=$(desc_len "$DEST")
  if [ "$DL" = "-1" ]; then bad "$NAME: no description in frontmatter"; continue; fi
  if [ "$DL" -gt 1024 ]; then bad "$NAME: description $DL chars > 1024 (VS Code limit)"; continue; fi
  if diff -r -q "$SRC" "$DEST" >/dev/null 2>&1; then ok "$NAME"
  else bad "$NAME: installed files differ from repo (stale or partial - re-run installer)"; fi
done
echo "Checked $COUNT repo skills."

# --- duplicates in other scanned locations ----------------------------------
echo ""
DUPS=""
check_dup() { # dir, label
  [ -d "$1" ] || return 0
  [ "$1" = "$TARGET" ] && return 0
  for SRC in "$SRC_SKILLS"/*/; do
    NAME=$(basename -- "$SRC")
    [ -d "$1/$NAME" ] && DUPS="$DUPS $NAME@$2"
  done
}
check_dup "$HOME/.copilot/skills" "~/.copilot/skills"
check_dup "$HOME/.claude/skills" "~/.claude/skills"
check_dup "$HOME/.agents/skills" "~/.agents/skills"
if [ -n "$WORKSPACE" ]; then
  check_dup "$WORKSPACE/.github/skills" "workspace/.github/skills"
  check_dup "$WORKSPACE/.claude/skills" "workspace/.claude/skills"
  check_dup "$WORKSPACE/.agents/skills" "workspace/.agents/skills"
fi
if [ -n "$DUPS" ]; then warn "same skill also present elsewhere (VS Code may list/load it twice):$DUPS"
else ok "no duplicates in other scanned locations"; fi

# --- VS Code ----------------------------------------------------------------
echo ""
if command -v code >/dev/null 2>&1; then
  V=$(code --version 2>/dev/null | head -n 1)
  MAJ=$(echo "$V" | cut -d. -f1); MIN=$(echo "$V" | cut -d. -f2)
  case "$MAJ$MIN" in *[!0-9]*|'') warn "VS Code version unparsable: $V (need >= 1.109)" ;;
    *) if [ "$MAJ" -gt 1 ] || { [ "$MAJ" -eq 1 ] && [ "$MIN" -ge 109 ]; }; then ok "VS Code $V (>= 1.109, Agent Skills GA)"
       else bad "VS Code $V < 1.109 - update VS Code, Agent Skills may not load"; fi ;;
  esac
else
  warn "'code' not on PATH here - verify on the target machine: VS Code >= 1.109 (latest recommended)"
fi

SETTINGS=""
for f in "$HOME/.config/Code/User/settings.json" \
         "$HOME/Library/Application Support/Code/User/settings.json"; do
  [ -f "$f" ] && SETTINGS=$f
done
if [ -n "$SETTINGS" ]; then
  if grep -q '"chat.useAgentSkills"[[:space:]]*:[[:space:]]*false' "$SETTINGS"; then
    bad "chat.useAgentSkills is false in $SETTINGS - Agent Skills are disabled"
  else
    ok "chat.useAgentSkills not disabled in user settings"
  fi
else
  warn "no VS Code user settings.json found here (fine if VS Code is on another machine)"
fi

echo ""
echo "RESULT: $([ "$FAILN" = 0 ] && echo PASS || echo FAIL) - $PASS passed, $FAILN failed, $WARNS warnings"
[ "$FAILN" = 0 ]
