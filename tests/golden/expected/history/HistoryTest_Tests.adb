--  One test per top-level transition: assert the generated transition
--  table maps (From, Event) to the model's target state.

with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases; use AUnit.Test_Cases;

with HistoryTest;

package body HistoryTest_Tests is

   use HistoryTest;

   procedure Test_Idle_Enter_Fresh (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Transition (Idle, Enter_Fresh) = Outer,
         "Idle --Enter_Fresh--> Outer");
   end Test_Idle_Enter_Fresh;

   procedure Test_Idle_Enter_Shallow (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Transition (Idle, Enter_Shallow) = Outer,
         "Idle --Enter_Shallow--> Outer");
   end Test_Idle_Enter_Shallow;

   procedure Test_Idle_Enter_Deep (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Transition (Idle, Enter_Deep) = Outer, "Idle --Enter_Deep--> Outer");
   end Test_Idle_Enter_Deep;

   procedure Test_Outer_Back (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Outer, Back) = Idle, "Outer --Back--> Idle");
   end Test_Outer_Back;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
      pragma Warnings (Off, "no entities of");
      pragma Warnings (Off, "use clause for package");
      pragma Warnings (Off, "aspect Unreferenced");
   begin
      Register_Routine
        (T, Test_Idle_Enter_Fresh'Access, "Idle --Enter_Fresh--> Outer");
      Register_Routine
        (T, Test_Idle_Enter_Shallow'Access, "Idle --Enter_Shallow--> Outer");
      Register_Routine
        (T, Test_Idle_Enter_Deep'Access, "Idle --Enter_Deep--> Outer");
      Register_Routine (T, Test_Outer_Back'Access, "Outer --Back--> Idle");
      null;
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("HistoryTest");
   end Name;

end HistoryTest_Tests;
