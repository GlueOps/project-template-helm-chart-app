#!/usr/bin/env bash
# Lists command/args entries in Helm values files that app chart 0.18.0 renders
# differently from 0.17.x for a container that may be running today (see README,
# "Upgrading from 0.17.x"). Walks every *.yaml / *.yml under DIR (default: .),
# so overlays are covered. Exit 1 if any entry is flagged, 0 if none.
# Needs yq (mikefarah, v4) and jq.
set -euo pipefail
dir="${1:-.}"

# One JSON object per map that has a command or args key, with file and line.
yq_query='.. | select(tag == "!!map" and (has("command") or has("args")))
  | {"file": filename, "line": line, "command": .command, "args": .args}'

# Flag: a map where a list is expected; a non-string item; an item wrapped in a
# second pair of quotes, containing " #", starting with "#", or padded with spaces.
read -r -d '' jq_filter <<'EOF' || true
def bad_item:
  (type != "string")
  or test("^\".*\"$") or test("^'.*'$")
  or test(" #") or test("^#")
  or test("^[[:space:]]|[[:space:]]$");
def bad_list:
  . != null and ((type == "object") or (type == "array" and any(.[]; bad_item)));
select((.command | bad_list) or (.args | bad_list))
| "\(.file):\(.line)"
  + (if (.command | bad_list) then " command=\(.command | tojson)" else "" end)
  + (if (.args | bad_list) then " args=\(.args | tojson)" else "" end)
EOF

found=0
while IFS= read -r -d '' f; do
  out=$(yq -o=json -I0 "$yq_query" "$f" 2>/dev/null | jq -r "$jq_filter" || true)
  if [[ -n "$out" ]]; then
    printf '%s\n' "$out"
    found=1
  fi
done < <(find "$dir" -type f \( -name '*.yaml' -o -name '*.yml' \) -print0)

if (( found )); then
  echo "Found command/args entries that change on 0.18.0; see README, Upgrading from 0.17.x." >&2
  exit 1
fi
echo "No command/args entries change on 0.18.0."
