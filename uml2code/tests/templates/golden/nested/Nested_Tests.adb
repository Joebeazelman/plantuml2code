--  One test per top-level transition: assert the generated transition
--  table maps (From, Event) to the model's target state.

with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Nested;

package body Nested_Tests is

   use Nested;

   procedure Test_Idle_Start (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Idle, Start) = Running,
              "Idle --Start--> Running");
   end Test_Idle_Start;

   procedure Test_Idle_Continue (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Idle, Continue) = Running,
              "Idle --Continue--> Running");
   end Test_Idle_Continue;

   procedure Test_Running_Stop (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Running, Stop) = Idle,
              "Running --Stop--> Idle");
   end Test_Running_Stop;

   procedure Test_Running_Finish (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Running, Finish) = End_State,
              "Running --Finish--> End_State");
   end Test_Running_Finish;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
      pragma Warnings (Off, "no entities of");
      pragma Warnings (Off, "use clause for package");
      pragma Warnings (Off, "aspect Unreferenced");
   begin
      Register_Routine (T, Test_Idle_Start'Access,
                        "Idle --Start--> Running");
      Register_Routine (T, Test_Idle_Continue'Access,
                        "Idle --Continue--> Running");
      Register_Routine (T, Test_Running_Stop'Access,
                        "Running --Stop--> Idle");
      Register_Routine (T, Test_Running_Finish'Access,
                        "Running --Finish--> End_State");
      null;
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Nested");
   end Name;

end Nested_Tests;
