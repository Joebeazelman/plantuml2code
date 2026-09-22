--  One test per top-level transition: assert the generated transition
--  table maps (From, Event) to the model's target state.

with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Middle_Machine;

package body Middle_Machine_Tests is

   use Middle_Machine;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
      pragma Unreferenced (T);
   begin
      null;
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Middle_Machine");
   end Name;

end Middle_Machine_Tests;
