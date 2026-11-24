#!/bin/sh
# install-skills.sh — install / update the skills in this repo into a
# GitHub Copilot (or any Agent Skills) skills directory.
#
# Behaviour (safe to re-run, idempotent):
#   * Skill missing from target          -> ADDED
#   * Skill present but files differ     -> UPDATED (old copy backed up first)
#   * Skill present and identical        -> SKIPPED (up to date)
#   * Folders in target not in this repo -> LEFT UNTOUCHED (your other skills)
#
# No internet, no Node, no Python required. POSIX sh + diff + cp only.
#
# Usage:
#   sh scripts/install-skills.sh [--target DIR | --project DIR] [options]
#
#   --target DIR     Skills directory to install into.
#                    Default: ~/.copilot/skills  (personal Copilot skills)
#   --project DIR    Install into DIR/.github/skills (project skills) instead.
#   --source DIR     Repo root containing skills/ (default: parent of scripts/)
#   --check          Report only, change nothing. Exit 1 if anything would change.
#   --dry-run        Same as --check but exit 0.
#   --no-backup      On update, replace without keeping a backup copy.
#   --backup-dir DIR Where backups go. Default: <target-parent>/skills-backup
#   --only a,b,c     Only process these skill names.
#   --exclude a,b,c  Skip these skill names.
#   --vscode         Personal install for VS Code: target ~/.copilot/skills
#                    (applies to ALL workspaces) + check the `code` version
#                    afterwards (Agent Skills need VS Code >= 1.109).
#   --with-instructions   (project mode only) Merge the adhd-combo core block
#                    into DIR/.github/copilot-instructions.md (marked block,
#                    replaced on re-run, the rest of the file is untouched).
#   -h, --help       This help.

set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_ROOT=$(dirname -- "$SCRIPT_DIR")
TARGET=""
PROJECT=""
CHECK=0
DRYRUN=0
BACKUP=1
BACKUP_DIR=""
ONLY=""
EXCLUDE=""
WITH_INSTRUCTIONS=0
VSCODE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET=$2; shift 2 ;;
    --project) PROJECT=$2; shift 2 ;;
    --source) SOURCE_ROOT=$2; shift 2 ;;
    --check) CHECK=1; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    --no-backup) BACKUP=0; shift ;;
    --backup-dir) BACKUP_DIR=$2; shift 2 ;;
    --only) ONLY=$2; shift 2 ;;
    --exclude) EXCLUDE=$2; shift 2 ;;
    --with-instructions) WITH_INSTRUCTIONS=1; shift ;;
    --vscode) VSCODE=1; shift ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

SRC_SKILLS="$SOURCE_ROOT/skills"
if [ ! -d "$SRC_SKILLS" ]; then
  echo "ERROR: no skills/ directory found under source: $SOURCE_ROOT" >&2
  echo "Run this script from inside the extracted repo (or pass --source)." >&2
  exit 2
fi

if [ -n "$PROJECT" ]; then
  TARGET="$PROJECT/.github/skills"
  SCOPE="PROJECT - only the workspace at $PROJECT"
elif [ -z "$TARGET" ]; then
  TARGET="$HOME/.copilot/skills"
  SCOPE="PERSONAL - user level, applies to ALL VS Code workspaces"
else
  SCOPE="CUSTOM target"
fi
[ -z "$BACKUP_DIR" ] && BACKUP_DIR="$(dirname -- "$TARGET")/skills-backup"
STAMP=$(date +%Y%m%d-%H%M%S)
REPORT_ONLY=0
[ "$CHECK" = 1 ] || [ "$DRYRUN" = 1 ] && REPORT_ONLY=1

in_list() { # name, comma-list
  case ",$2," in *",$1,"*) return 0 ;; *) return 1 ;; esac
}

echo "Source : $SRC_SKILLS"
echo "Target : $TARGET"
echo "Scope  : $SCOPE"
[ "$REPORT_ONLY" = 1 ] && echo "Mode   : check only (nothing will be changed)"
echo ""

ADDED=0; UPDATED=0; SKIPPED=0; FAILED=0
ADDED_LIST=""; UPDATED_LIST=""

[ "$REPORT_ONLY" = 0 ] && mkdir -p "$TARGET"

for SRC in "$SRC_SKILLS"/*/; do
  NAME=$(basename -- "$SRC")
  [ -f "$SRC/SKILL.md" ] || { echo "WARN  $NAME has no SKILL.md in source, skipped"; continue; }
  [ -n "$ONLY" ] && ! in_list "$NAME" "$ONLY" && continue
  [ -n "$EXCLUDE" ] && in_list "$NAME" "$EXCLUDE" && continue
  DEST="$TARGET/$NAME"

  if [ ! -d "$DEST" ]; then
    if [ "$REPORT_ONLY" = 1 ]; then
      echo "WOULD ADD     $NAME"
    else
      cp -R "$SRC" "$TARGET/" && echo "ADDED         $NAME" || { echo "FAILED        $NAME"; FAILED=$((FAILED+1)); continue; }
    fi
    ADDED=$((ADDED+1)); ADDED_LIST="$ADDED_LIST $NAME"
    continue
  fi

  if diff -r -q "$SRC" "$DEST" >/dev/null 2>&1; then
    echo "UP TO DATE    $NAME"
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  # Present but different -> update, with backup of the old copy first.
  if [ "$REPORT_ONLY" = 1 ]; then
    echo "WOULD UPDATE  $NAME"
  else
    if [ "$BACKUP" = 1 ]; then
      mkdir -p "$BACKUP_DIR/$STAMP"
      cp -R "$DEST" "$BACKUP_DIR/$STAMP/" || { echo "FAILED (backup) $NAME"; FAILED=$((FAILED+1)); continue; }
    fi
    rm -rf "$DEST"
    cp -R "$SRC" "$TARGET/" && echo "UPDATED       $NAME (old copy in $BACKUP_DIR/$STAMP)" || { echo "FAILED        $NAME"; FAILED=$((FAILED+1)); continue; }
  fi
  UPDATED=$((UPDATED+1)); UPDATED_LIST="$UPDATED_LIST $NAME"
done

# Optional: merge the always-on core into the project's Copilot instructions.
if [ "$WITH_INSTRUCTIONS" = 1 ]; then
  SNIPPET="$SOURCE_ROOT/copilot/copilot-instructions.snippet.md"
  if [ -z "$PROJECT" ]; then
    echo "NOTE  --with-instructions needs --project; skipped."
  elif [ ! -f "$SNIPPET" ]; then
    echo "NOTE  snippet not found at $SNIPPET; skipped."
  else
    INSTR="$PROJECT/.github/copilot-instructions.md"
    if [ "$REPORT_ONLY" = 1 ]; then
      echo "WOULD MERGE   core instructions block into $INSTR"
    else
      mkdir -p "$PROJECT/.github"
      [ -f "$INSTR" ] || : > "$INSTR"
      # Remove any previous managed block, then append the fresh one.
      awk '/<!-- BEGIN adhd-combo core -->/{skip=1} !skip{print} /<!-- END adhd-combo core -->/{skip=0}' "$INSTR" > "$INSTR.tmp" && mv "$INSTR.tmp" "$INSTR"
      cat "$SNIPPET" >> "$INSTR"
      echo "MERGED        core instructions block into $INSTR"
    fi
  fi
fi

# Verification pass: every repo skill in target must have a SKILL.md whose
# frontmatter name matches its folder.
echo ""
echo "Verifying..."
VERIFY_FAIL=0
COUNT=0
for SRC in "$SRC_SKILLS"/*/; do
  NAME=$(basename -- "$SRC")
  [ -f "$SRC/SKILL.md" ] || continue
  [ -n "$ONLY" ] && ! in_list "$NAME" "$ONLY" && continue
  [ -n "$EXCLUDE" ] && in_list "$NAME" "$EXCLUDE" && continue
  COUNT=$((COUNT+1))
  if [ "$REPORT_ONLY" = 1 ]; then
    [ -d "$TARGET/$NAME" ] || continue
  fi
  if [ ! -f "$TARGET/$NAME/SKILL.md" ]; then
    echo "VERIFY FAIL   $NAME: SKILL.md missing in target"; VERIFY_FAIL=$((VERIFY_FAIL+1)); continue
  fi
  if ! grep -q "^name:[[:space:]]*$NAME[[:space:]]*$" "$TARGET/$NAME/SKILL.md"; then
    echo "VERIFY FAIL   $NAME: frontmatter name does not match folder"; VERIFY_FAIL=$((VERIFY_FAIL+1))
  fi
done

echo ""
echo "Summary: $COUNT repo skills checked | added:$ADDED updated:$UPDATED up-to-date:$SKIPPED failed:$FAILED verify-failures:$VERIFY_FAIL"
[ -n "$ADDED_LIST" ] && echo "  added:  $ADDED_LIST"
[ -n "$UPDATED_LIST" ] && echo "  updated:$UPDATED_LIST"
echo "Skills already in the target that are not in this repo were left untouched."

# VS Code check (personal installs, or when --vscode is passed): Agent Skills
# are GA and on by default in VS Code >= 1.109 (Jan 2026). Latest is best.
if [ "$VSCODE" = 1 ] || [ -z "$PROJECT" ]; then
  echo ""
  if command -v code >/dev/null 2>&1; then
    V=$(code --version 2>/dev/null | head -n 1)
    echo "VS Code: $V"
    MAJ=$(echo "$V" | cut -d. -f1); MIN=$(echo "$V" | cut -d. -f2)
    case "$MAJ$MIN" in *[!0-9]*|'') echo "  (could not parse version - need >= 1.109)" ;;
      *) if [ "$MAJ" -gt 1 ] || { [ "$MAJ" -eq 1 ] && [ "$MIN" -ge 109 ]; }; then
           echo "  OK - Agent Skills supported and enabled by default."
         else
           echo "  WARNING - VS Code < 1.109: update VS Code, Agent Skills may not load."
         fi ;;
    esac
  else
    echo "VS Code: 'code' not on PATH here - on the target machine use VS Code >= 1.109 (latest recommended)."
  fi
fi

if [ "$FAILED" -gt 0 ] || [ "$VERIFY_FAIL" -gt 0 ]; then
  exit 1
fi
if [ "$CHECK" = 1 ] && { [ "$ADDED" -gt 0 ] || [ "$UPDATED" -gt 0 ]; }; then
  exit 1
fi
exit 0
