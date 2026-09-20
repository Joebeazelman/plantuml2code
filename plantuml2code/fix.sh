#!/usr/bin/env bash
set -euo pipefail
cd ~/Projects/ai-generated

echo "=== nested project end-to-end ==="
rm -rf /tmp/genproj
mkdir -p /tmp/genproj
plantuml2code/bin/plantuml2code dump -f ada -o /tmp/genproj samples/nested.puml >/dev/null
cd /tmp/genproj && bash setup.sh 2>&1 | tail -4
cd ~/Projects/ai-generated

echo
echo "=== history project end-to-end ==="
rm -rf /tmp/genhist
mkdir -p /tmp/genhist
plantuml2code/bin/plantuml2code dump -f ada -o /tmp/genhist samples/history.puml >/dev/null
cd /tmp/genhist && bash setup.sh 2>&1 | tail -4
cd ~/Projects/ai-generated

echo
echo "=== commit ==="
rm -f fix.sh
git add -A
git status --short
git commit -m "Runtime and project scaffolding as templates; generator emits full Alire project"
git push
git log --oneline -2