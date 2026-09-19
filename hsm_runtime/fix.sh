#!/usr/bin/env bash
# fix_step_contract.sh
set -euo pipefail
cd ~/Projects/ai-generated

python3 - hsm_runtime/src/hsm-machines.ads <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''   procedure Step (Self : in out Machine'Class; On : Event)
     with Pre  => not Is_Terminated (Self),
          Post => (if Current_State (Self) /= Current_State (Self)'Old
                   then not Is_Terminated (Self)
                   else Is_Terminated (Self) = Is_Terminated (Self)'Old);'''
new = '''   procedure Step (Self : in out Machine'Class; On : Event)
     with Pre  => not Is_Terminated (Self),
          Post => ((Current_State (Self) = Current_State (Self)'Old)
                   = (Is_Terminated (Self) = Is_Terminated (Self)'Old));'''
assert old in s, "Step contract anchor"
open(p,'w').write(s.replace(old, new, 1))
print("Step postcondition rewritten")
PYEOF

cd hsm_runtime && alr build 2>&1 | tail -2
cd ..

cd gen_test
alr clean >/dev/null
alr build 2>&1 | tail -2
./bin/gen_test
cd ..

git add hsm_runtime/src/hsm-machines.ads
git commit -m "Runtime: correct Step postcondition — termination changes only on state change"
git push
git log --oneline -2