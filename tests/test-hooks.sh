#!/usr/bin/env sh
# Checks every hook command adhd-combo registers. Run: sh tests/test-hooks.sh
set -u
root=$(cd "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0
ok() { printf 'ok   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fail=1; }

# 1. SessionStart: plain text, frontmatter stripped, under the 10,000-char cap.
for skill in adhd-combo i-have-adhd caveman ponytail; do
  sh "$root/hooks/inject.sh" session "$skill" > "$tmp/$skill.txt"
  n=$(wc -m < "$tmp/$skill.txt" | tr -d ' ')
  if [ "$n" -eq 0 ]; then bad "session $skill: empty"; continue; fi
  [ "$n" -lt 10000 ] && ok "session $skill: $n chars" || bad "session $skill: $n chars, over the cap"
  head -n 5 "$tmp/$skill.txt" | grep -qE '^(---|name:|description:)' &&
    bad "session $skill: frontmatter leaked"
done

# 2. SubagentStart: valid JSON carrying the same text.
if command -v python3 > /dev/null 2>&1; then
  for skill in caveman ponytail; do
    sh "$root/hooks/inject.sh" subagent "$skill" > "$tmp/$skill.json"
    if python3 - "$tmp/$skill.json" "$tmp/$skill.txt" << 'PY'
import json, sys
out = json.load(open(sys.argv[1], encoding="utf-8"))["hookSpecificOutput"]
text = open(sys.argv[2], encoding="utf-8").read().rstrip("\n")
assert out["hookEventName"] == "SubagentStart"
assert out["additionalContext"] == text, "text differs from session output"
assert len(out["additionalContext"]) < 10000
PY
    then ok "subagent $skill: valid JSON, same text"; else bad "subagent $skill"; fi
  done
else
  printf 'skip subagent JSON checks: python3 not found\n'
fi

# 3. Bad input: no output, exit 0, never blocks a session.
for args in "session nope" "subagent ../../etc" "session"; do
  # shellcheck disable=SC2086
  out=$(sh "$root/hooks/inject.sh" $args); code=$?
  [ -z "$out" ] && [ "$code" -eq 0 ] && ok "ignored: inject.sh $args" || bad "inject.sh $args"
done

# 4. hooks.json is valid JSON and only calls known skills.
if command -v python3 > /dev/null 2>&1; then
  python3 - "$root/hooks/hooks.json" << 'PY' && ok "hooks.json: valid, known skills only" || bad "hooks.json"
import json, sys
known = {"adhd-combo", "i-have-adhd", "caveman", "ponytail"}
for groups in json.load(open(sys.argv[1]))["hooks"].values():
    for group in groups:
        for hook in group["hooks"]:
            assert hook["command"].split()[-1] in known, hook["command"]
PY
fi

[ "$fail" -eq 0 ] && printf 'all checks passed\n'
exit "$fail"
