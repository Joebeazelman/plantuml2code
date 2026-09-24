--  One test per top-level transition: assert the generated transition
--  table maps (From, Event) to the model's target state.

with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases; use AUnit.Test_Cases;

with Execute_Explicit_Command_Machine;

package body Execute_Explicit_Command_Machine_Tests is

   use Execute_Explicit_Command_Machine;

   procedure Test_Transmit_Explicit_Is_Talk_Command
     (T : in out Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Transition (Transmit_Explicit, Is_Talk_Command) = Await_Explicit,
         "Transmit_Explicit --Is_Talk_Command--> Await_Explicit");
   end Test_Transmit_Explicit_Is_Talk_Command;

   procedure Test_Transmit_Explicit_Is_Listen_Or_Flush_Command
     (T : in out Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Transition (Transmit_Explicit, Is_Listen_Or_Flush_Command)
         = End_State,
         "Transmit_Explicit --Is_Listen_Or_Flush_Command--> End_State");
   end Test_Transmit_Explicit_Is_Listen_Or_Flush_Command;

   procedure Test_Await_Explicit_Data_Received (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Transition (Await_Explicit, Data_Received) = Delegate_Explicit,
         "Await_Explicit --Data_Received--> Delegate_Explicit");
   end Test_Await_Explicit_Data_Received;

   procedure Test_Await_Explicit_Timeout_Transaction_Failed
     (T : in out Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Transition (Await_Explicit, Timeout_Transaction_Failed) = End_State,
         "Await_Explicit --Timeout_Transaction_Failed--> End_State");
   end Test_Await_Explicit_Timeout_Transaction_Failed;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
      pragma Warnings (Off, "no entities of");
      pragma Warnings (Off, "use clause for package");
      pragma Warnings (Off, "aspect Unreferenced");
   begin
      Register_Routine
        (T,
         Test_Transmit_Explicit_Is_Talk_Command'Access,
         "Transmit_Explicit --Is_Talk_Command--> Await_Explicit");
      Register_Routine
        (T,
         Test_Transmit_Explicit_Is_Listen_Or_Flush_Command'Access,
         "Transmit_Explicit --Is_Listen_Or_Flush_Command--> End_State");
      Register_Routine
        (T,
         Test_Await_Explicit_Data_Received'Access,
         "Await_Explicit --Data_Received--> Delegate_Explicit");
      Register_Routine
        (T,
         Test_Await_Explicit_Timeout_Transaction_Failed'Access,
         "Await_Explicit --Timeout_Transaction_Failed--> End_State");
      null;
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Execute_Explicit_Command_Machine");
   end Name;

end Execute_Explicit_Command_Machine_Tests;
