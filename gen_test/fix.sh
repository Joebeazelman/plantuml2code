#!/usr/bin/env bash
# fix_do_call.sh
set -euo pipefail
cd ~/Projects/ai-generated

python3 - plantuml2code/src/plantuml2code_ada.adb <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''                     Append (Do_Body,
                             "            "
                             & Sanitize (To_String (A.Action))
                             & " (Self);" & ASCII.LF);'''
new = '''                     Append (Do_Body,
                             "            "
                             & Sanitize (To_String (A.Action))
                             & ";" & ASCII.LF);'''
assert old in s, "do-body anchor"
open(p,'w').write(s.replace(old, new, 1))
print("patched")
PYEOF

cd plantuml2code && alr build 2>&1 | tail -2
cd ..
rm -rf /tmp/gen && mkdir /tmp/gen
cd plantuml2code && ./bin/plantuml2code dump -f ada -o /tmp/gen ../samples/nested.puml
cd ../gen_test
rm -f src/Nested*.ad[bs] src/Running_Machine*.ad[bs]
cp /tmp/gen/*.ads /tmp/gen/*.adb src/
alr build 2>&1 | tail -3
./bin/gen_test
cd ..
./tests/update_golden.sh >/dev/null
./tests/run_tests.sh 2>&1 | tail -4
git add hsm_runtime/ plantuml2code/ tests/golden/ gen_test/ 2>/dev/null || true
git add hsm_runtime/ plantuml2code/ tests/golden/
git commit -m "Runtime: add On_Tick; generator: emit do-activity dispatch"
git push
git log --oneline -2