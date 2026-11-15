#!/usr/bin/env sh
# adhd-combo hook: print one bundled skill's rules so Claude Code adds them to
# the model's context. hooks.json calls this once per skill, so each output
# stays under Claude Code's 10,000-character limit per hook command.
#
# Usage: inject.sh session|subagent <skill>
#   session   plain text on stdout (SessionStart adds it to context)
#   subagent  JSON with hookSpecificOutput.additionalContext (SubagentStart)
#
# Never blocks a session: any failure exits 0 with no output.

event=$1
skill=$2

case $skill in
  adhd-combo | i-have-adhd | caveman | ponytail) ;;
  *) exit 0 ;;
esac

# Find skills/ from this script's own path, not from an env var.
dir=$(dirname -- "$0") || exit 0
file="$dir/../skills/$skill/SKILL.md"
[ -f "$file" ] || exit 0

# Drop the leading YAML frontmatter (--- ... ---) and keep the rest.
body=$(awk '
  NR == 1 && /^---[[:space:]]*$/ { fm = 1; next }
  fm && /^---[[:space:]]*$/      { fm = 0; next }
  !fm
' "$file") || exit 0
[ -n "$body" ] || exit 0

if [ "$skill" = adhd-combo ]; then
  text=$body
else
  text="ON NOW (adhd-combo bundle, always on): $skill. Its full rules follow. Where they clash with the other bundled skills, the adhd-combo rules decide.

$body"
fi

if [ "$event" = subagent ]; then
  tab=$(printf '\t')
  esc=$(printf '%s' "$text" | tr -d '\r' |
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e "s/$tab/\\\\t/g" |
    awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }') || exit 0
  printf '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"%s"}}\n' "$esc"
else
  printf '%s\n' "$text"
fi
exit 0
