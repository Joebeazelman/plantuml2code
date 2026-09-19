#!/usr/bin/env bash
# fix_runtime_errors.sh
set -euo pipefail
cd ~/Projects/ai-generated

# Fix 1: dispatch Next_State via Self (class-wide)
# Fix 2: add pragma Unevaluated_Use_Of_Old
python3 - hsm_runtime/src/hsm-machines.adb <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("Next_State (Machine (Self), On)", "Next_State (Self, On)", 1)
open(p,'w').write(s)
print("Next_State dispatch fixed")
PYEOF

python3 - hsm_runtime/src/hsm-machines.ads <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''package HSM.Machines is
   pragma Preelaborate;'''
new = '''package HSM.Machines is
   pragma Preelaborate;
   pragma Unevaluated_Use_Of_Old (Allow);'''
assert old in s, "package anchor"
open(p,'w').write(s.replace(old, new, 1))
print("Unevaluated_Use_Of_Old added")
PYEOF

cd hsm_runtime && alr build 2>&1 | tail -4
cd ../plantuml2code && alr build 2>&1 | tail -2
cd ..

./tests/update_golden.sh >/dev/null
./tests/run_tests.sh 2>&1 | tail -4

cd plantuml2code
rm -rf /tmp/gen && mkdir /tmp/gen
./bin/plantuml2code dump -f ada -o /tmp/gen ../samples/nested.puml
cd ../gen_test
rm -f src/Nested*.ad[bs] src/Running_Machine*.ad[bs]
cp /tmp/gen/*.ads /tmp/gen/*.adb src/
alr build 2>&1 | tail -3
./bin/gen_test
cd ..

git add hsm_runtime/ plantuml2code/ tests/golden/
git status --short
git commit -m "Runtime: terminated flag + contracts; generator: mark End_State terminal"
git push
git log --oneline -2