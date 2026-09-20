#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

alr exec -- gprbuild -P plantuml2code_tests.gpr -p 2>&1 | tail -5
echo
./bin/test_main
