#!/usr/bin/env bash
set -euo pipefail
cd ~/Projects/ai-generated

git add hsm_runtime/ plantuml_parser/ plantuml2code/ gen_test/ tests/golden/ samples/
git status --short
git commit -m "History pseudostate: child state survives composite re-entry via [H]"
git push
git log --oneline -3
git status