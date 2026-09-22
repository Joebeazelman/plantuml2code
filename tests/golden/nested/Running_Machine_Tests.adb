--  One test per top-level transition: assert the generated transition
--  table maps (From, Event) to the model's target state.

with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Running_Machine;

package body Running_Machine_Tests is

   use Running_Machine;

   procedure Test_Spinning_Yield (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Spinning, Yield) = Waiting,
              "Spinning --Yield--> Waiting");
   end Test_Spinning_Yield;

   procedure Test_Waiting_Resume (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Waiting, Resume) = Spinning,
              "Waiting --Resume--> Spinning");
   end Test_Waiting_Resume;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
      pragma Warnings (Off, "no entities of");
      pragma Warnings (Off, "use clause for package");
      pragma Warnings (Off, "aspect Unreferenced");
   begin
      Register_Routine (T, Test_Spinning_Yield'Access,
                        "Spinning --Yield--> Waiting");
      Register_Routine (T, Test_Waiting_Resume'Access,
                        "Waiting --Resume--> Spinning");
      null;
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Running_Machine");
   end Name;

end Running_Machine_Tests;
