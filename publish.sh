#!/usr/bin/env bash
# publish.sh -- submit plantuml_parser and hsm_runtime to the
# Alire community index.
#
# Usage:
#   ./publish.sh          submit both crates
#   ./publish.sh --check  run --skip-submit on both (no PR)

set -euo pipefail

cd "$(dirname "$0")"

MODE="${1:-submit}"

submit_crate () {
  local crate="$1"
  echo "================================================================"
  echo "==> $crate"
  echo "================================================================"

  if [ "$MODE" = "--check" ]; then
    # Non-interactive: accept the default answer (Yes) at every prompt.
    ( cd "$crate" && alr -n publish --skip-submit )
  else
    ( cd "$crate" && alr publish )
  fi
}

submit_crate plantuml_parser
echo
submit_crate hsm_runtime

echo
echo "Done."
if [ "$MODE" = "--check" ]; then
  echo "Check-only mode. No PR was opened."
else
  echo "PRs should now be open against alire-project/alire-index."
  echo "Follow progress with:"
  echo "  gh pr list --repo alire-project/alire-index --author Joebeazelman"
fi
