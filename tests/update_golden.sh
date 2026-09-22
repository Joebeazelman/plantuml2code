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
  mkdir -p "$golden_dir"

  local out
  out=$(mktemp -d)
  ( cd "$ROOT/plantuml2code" \
      && ./bin/plantuml2code dump -f ada -o "$out" \
         "../$source" >/dev/null )

  rm -f "$golden_dir"/*.ads "$golden_dir"/*.adb "$golden_dir"/driver.adb

  for f in "$out/src"/*.ads "$out/src"/*.adb; do
    [ -e "$f" ] || continue
    local base
    base=$(basename "$f")
    sed -f "$NORM" "$f" > "$golden_dir/$base"
  done

  # Driver lives in tests/, not src/.
  if [ -e "$out/tests/driver.adb" ]; then
    sed -f "$NORM" "$out/tests/driver.adb" > "$golden_dir/driver.adb"
  fi

  # Generated AUnit test files live in tests/test/.
  if [ -d "$out/tests/test" ]; then
    for f in "$out/tests/test"/*.ads "$out/tests/test"/*.adb; do
      [ -e "$f" ] || continue
      local base
      base=$(basename "$f")
      sed -f "$NORM" "$f" > "$golden_dir/$base"
    done
  fi

  rm -rf "$out"
  ls "$golden_dir" | wc -l | xargs echo "  files:"
}

update_case nested  samples/nested.puml
echo
update_case zoo     samples/zoo.puml
echo
update_case history samples/history.puml
echo
update_case adb     samples/adb_protocol.puml

echo
echo "Golden files updated. Review with:"
echo "    git diff tests/golden/"
