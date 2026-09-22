--  One test per top-level transition: assert the generated transition
--  table maps (From, Event) to the model's target state.

with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Inner_Machine;

package body Inner_Machine_Tests is

   use Inner_Machine;

   procedure Test_A_Advance (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (A, Advance) = B,
              "A --Advance--> B");
   end Test_A_Advance;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
      pragma Unreferenced (T);
   begin
      Register_Routine (T, Test_A_Advance'Access,
                        "A --Advance--> B");
      null;
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Inner_Machine");
   end Name;

end Inner_Machine_Tests;
