#!/usr/bin/env bash
# update_golden.sh -- regenerate golden files from current generator
# output. Use this after intentional template changes.

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
NORM="$ROOT/tests/normalize.sed"
GEN="$ROOT/plantuml2code/bin/plantuml2code"

if [ ! -x "$GEN" ]; then
  echo "error: $GEN not built. Run 'cd plantuml2code && alr build' first."
  exit 1
fi

update_case () {
  local name="$1"
  local source="$2"
  local golden_dir="$ROOT/tests/golden/$name"

  echo "==> $name"

  local out
  out=$(mktemp -d)
  ( cd "$ROOT/plantuml2code" \
      && ./bin/plantuml2code dump -f ada -o "$out" \
         "../$source" >/dev/null )

  rm -f "$golden_dir"/*.ads "$golden_dir"/*.adb

  for f in "$out"/*.ads "$out"/*.adb; do
    [ -e "$f" ] || continue
    local base
    base=$(basename "$f")
    sed -f "$NORM" "$f" > "$golden_dir/$base"
  done

  rm -rf "$out"
  ls "$golden_dir" | wc -l | xargs echo "  files:"
}

update_case nested samples/nested.puml
echo
update_case zoo    samples/zoo.puml

echo
echo "Golden files updated. Review with:"
echo "    git diff tests/golden/"
