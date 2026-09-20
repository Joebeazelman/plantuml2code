#!/usr/bin/env bash
set -euo pipefail
cd ~/Projects/ai-generated

rm -f fix.sh plantuml2code/fix.sh

git add plantuml_parser/
git status --short
git commit -m "plantuml_parser: AUnit test suite (Tokens, States, Classes)"
git push
git log --oneline -2