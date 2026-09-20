#!/usr/bin/env bash
set -euo pipefail
cd ~/Projects/ai-generated

./tests/update_golden.sh >/dev/null
./tests/run_tests.sh 2>&1 | tail -6

cd plantuml2code
rm -rf /tmp/genproj
mkdir -p /tmp/genproj
./bin/plantuml2code dump -f ada -o /tmp/genproj ../samples/nested.puml >/dev/null
cd /tmp/genproj
bash setup.sh 2>&1 | tail -3
cd ~/Projects/ai-generated

git add -A
git status --short
git commit -m "Template-driven On_Exit (piece B of template rewrite)"
git push
git log --oneline -2