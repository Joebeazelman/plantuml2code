#!/usr/bin/env bash
set -euo pipefail
cd ~/Projects/ai-generated

python3 - plantuml2code/src/plantuml2code_ada.adb <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''      declare
         Has_Actions : constant Boolean :=
           Length (Action_Decls_Text) > 0;
      begin
         if Has_Actions then
            Insert
              (T, Assoc
                 ("ACTIONS_WITH",
                  To_Unbounded_String
                    ("with " & Package_Name
                     & "_Actions;" & ASCII.LF & ASCII.LF)));
            Insert
              (T, Assoc
                 ("ACTIONS_USE",
                  To_Unbounded_String
                    ("   use " & Package_Name
                     & "_Actions;" & ASCII.LF)));
         else
            Insert (T, Assoc ("ACTIONS_WITH", To_Unbounded_String ("")));
            Insert (T, Assoc ("ACTIONS_USE", To_Unbounded_String ("")));
         end if;
      end;'''
new = '''      declare
         Has_Actions : constant Boolean :=
           Length (Action_Decls_Text) > 0;
         With_Txt : constant String :=
           (if Has_Actions
            then "with " & Package_Name & "_Actions;" & ASCII.LF & ASCII.LF
            else "");
         Use_Txt  : constant String :=
           (if Has_Actions
            then "   use " & Package_Name & "_Actions;" & ASCII.LF
            else "");
      begin
         Insert (T, Assoc ("ACTIONS_WITH", With_Txt));
         Insert (T, Assoc ("ACTIONS_USE", Use_Txt));
      end;'''
assert old in s, "anchor"
open(p,'w').write(s.replace(old, new, 1))
print("patched")
PYEOF

cd plantuml2code && alr build 2>&1 | tail -3
cd ..