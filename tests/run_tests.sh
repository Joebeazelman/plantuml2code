#!/usr/bin/env bash
# run_tests.sh -- regenerate samples and diff against golden output.
#
# Run from the repo root:
#     ./tests/run_tests.sh
#
# Exits non-zero if any diff is found.

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
NORM="$ROOT/tests/normalize.sed"
GEN="$ROOT/plantuml2code/bin/plantuml2code"

if [ ! -x "$GEN" ]; then
  echo "error: $GEN not built. Run 'cd plantuml2code && alr build' first."
  exit 1
fi

FAIL=0
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

check_case () {
  local name="$1"
  local source="$2"
  local golden_dir="$ROOT/tests/golden/$name"

  echo "==> $name"

  local out="$TMP/$name"
  mkdir -p "$out"

  # Run the generator from plantuml2code/ so template lookup works
  ( cd "$ROOT/plantuml2code" \
      && ./bin/plantuml2code dump -f ada -o "$out" \
         "../$source" >/dev/null )

  # Normalize every generated file, then compare
  local diff_count=0
  for gen_file in "$out"/*.ads "$out"/*.adb; do
    [ -e "$gen_file" ] || continue
    local base
    base=$(basename "$gen_file")
    local golden_file="$golden_dir/$base"

    if [ ! -f "$golden_file" ]; then
      echo "  MISSING golden: $base"
      diff_count=$((diff_count + 1))
      continue
    fi

    local norm_gen="$TMP/$base.gen"
    local norm_gl="$TMP/$base.gl"
    sed -f "$NORM" "$gen_file" > "$norm_gen"
    sed -f "$NORM" "$golden_file" > "$norm_gl"

    if ! diff -q "$norm_gl" "$norm_gen" >/dev/null; then
      echo "  DIFF: $base"
      diff -u "$norm_gl" "$norm_gen" | head -30 || true
      diff_count=$((diff_count + 1))
    fi
  done

  # Check for golden files that no longer get generated
  for golden_file in "$golden_dir"/*.ads "$golden_dir"/*.adb; do
    [ -e "$golden_file" ] || continue
    local base
    base=$(basename "$golden_file")
    if [ ! -f "$out/$base" ]; then
      echo "  STALE golden (no longer generated): $base"
      diff_count=$((diff_count + 1))
    fi
  done

  if [ "$diff_count" -eq 0 ]; then
    echo "  PASS"
  else
    echo "  FAIL ($diff_count differences)"
    FAIL=1
  fi
}

check_case nested  samples/nested.puml
echo
check_case zoo     samples/zoo.puml
echo
check_case history samples/history.puml

echo
if [ "$FAIL" -eq 0 ]; then
  echo "All golden tests passed."
else
  echo "Some golden tests failed. To accept current output, run:"
  echo "    ./tests/update_golden.sh"
  exit 1
fi
