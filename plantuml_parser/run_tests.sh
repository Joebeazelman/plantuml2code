#!/usr/bin/env bash
# Build and run the AUnit test suite for plantuml_parser.
set -euo pipefail
cd "$(dirname "$0")"

alr exec -- gprbuild -P plantuml_parser_tests.gpr -p 2>&1 | tail -5
echo
./bin/test_main
