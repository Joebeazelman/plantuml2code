#!/usr/bin/env bash
# run_tests.sh -- run every test for the uml2code crate:
#   1. the AUnit suites
#   2. the golden-file comparisons
#
# Run from the crate root:
#     ./run_tests.sh
#
# Exits non-zero if either phase fails.

set -euo pipefail

CRATE="$(cd "$(dirname "$0")" && pwd)"
cd "$CRATE"

# --- AUnit ---------------------------------------------------------
echo "==> AUnit suites"

GPRBUILD="$(command -v gprbuild || true)"
if [ -z "$GPRBUILD" ]; then
  GPRBUILD="$(find "$HOME/.local/share/alire/toolchains" -name gprbuild 2>/dev/null | head -1)"
fi
if [ -z "$GPRBUILD" ]; then
  echo "error: gprbuild not found. Install Alire." >&2
  exit 1
fi

alr exec -- "$GPRBUILD" -P uml2code_tests.gpr
./bin/test_main

# --- Goldens -------------------------------------------------------
echo
echo "==> Golden files"
./tests/templates/run_tests.sh
