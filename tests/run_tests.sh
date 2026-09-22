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
GEN="$ROOT/uml2code/bin/uml2code"

if [ ! -x "$GEN" ]; then
  echo "error: $GEN not built. Run 'cd uml2code && alr build' first."
  exit 1
fi

# Refuse to run if any source is newer than the binary. A failed build
# leaves the previous binary in place; without this check, goldens would
# silently test stale output.
newest_src=$(find "$ROOT/uml2code/src" "$ROOT/plantuml_parser/src" \
             -name '*.ad[bs]' -newer "$GEN" -print -quit)
if [ -n "$newest_src" ]; then
  echo "error: $GEN is older than $newest_src"
  echo "       rebuild before running goldens (the build may have failed)."
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

  # Run the generator from uml2code/ so template lookup works
  ( cd "$ROOT/uml2code" \
      && ./bin/uml2code dump -f ada -o "$out" \
         "../$source" >/dev/null )

  # Normalize every generated file, then compare
  local diff_count=0
  for gen_file in "$out/src"/*.ads "$out/src"/*.adb; do
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

  # Driver lives in tests/, not src/.
  if [ -f "$out/tests/driver.adb" ]; then
    if [ ! -f "$golden_dir/driver.adb" ]; then
      echo "  MISSING golden: driver.adb"
      diff_count=$((diff_count + 1))
    else
      local norm_gen="$TMP/driver.adb.gen"
      local norm_gl="$TMP/driver.adb.gl"
      sed -f "$NORM" "$out/tests/driver.adb" > "$norm_gen"
      sed -f "$NORM" "$golden_dir/driver.adb" > "$norm_gl"
      if ! diff -q "$norm_gl" "$norm_gen" >/dev/null; then
        echo "  DIFF: driver.adb"
        diff -u "$norm_gl" "$norm_gen" | head -30 || true
        diff_count=$((diff_count + 1))
      fi
    fi
  fi

  # Generated AUnit test files live in tests/test/.
  for gen_file in "$out/tests/test"/*.ads "$out/tests/test"/*.adb; do
    [ -e "$gen_file" ] || continue
    local base
    base=$(basename "$gen_file")
    local golden_file="$golden_dir/$base"
    if [ ! -f "$golden_file" ]; then
      echo "  MISSING golden: $base"
      diff_count=$((diff_count + 1))
      continue
    fi
    local ng="$TMP/$base.gen"
    local ngl="$TMP/$base.gl"
    sed -f "$NORM" "$gen_file" > "$ng"
    sed -f "$NORM" "$golden_file" > "$ngl"
    if ! diff -q "$ngl" "$ng" >/dev/null; then
      echo "  DIFF: $base"
      diff -u "$ngl" "$ng" | head -30 || true
      diff_count=$((diff_count + 1))
    fi
  done

  # Check for golden files that no longer get generated. Build a
  # set of every basename the generator produced — under src/ or
  # under tests/ or tests/test/ — and flag goldens not in it.
  local generated
  generated=$(mktemp)
  for d in "$out/src" "$out/tests" "$out/tests/test"; do
    [ -d "$d" ] || continue
    for f in "$d"/*.ads "$d"/*.adb; do
      [ -e "$f" ] || continue
      basename "$f" >> "$generated"
    done
  done
  for golden_file in "$golden_dir"/*.ads "$golden_dir"/*.adb; do
    [ -e "$golden_file" ] || continue
    local base
    base=$(basename "$golden_file")
    if ! grep -q -x -F "$base" "$generated"; then
      echo "  STALE golden (no longer generated): $base"
      diff_count=$((diff_count + 1))
    fi
  done
  rm -f "$generated"

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
check_case adb     samples/adb_protocol.puml

echo
if [ "$FAIL" -eq 0 ]; then
  echo "All golden tests passed."
else
  echo "Some golden tests failed. To accept current output, run:"
  echo "    ./tests/update_golden.sh"
  exit 1
fi
