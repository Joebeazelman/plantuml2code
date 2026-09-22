--  One test per top-level transition: assert the generated transition
--  table maps (From, Event) to the model's target state.

with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Machine;

package body Machine_Tests is

   use Machine;

   procedure Test_ADB_Reset_Reset_Complete (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (ADB_Reset, Reset_Complete) = Address_Resolution,
              "ADB_Reset --Reset_Complete--> Address_Resolution");
   end Test_ADB_Reset_Reset_Complete;

   procedure Test_Address_Resolution_Bus_Enumerated (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Address_Resolution, Bus_Enumerated) = Bus_Idle,
              "Address_Resolution --Bus_Enumerated--> Bus_Idle");
   end Test_Address_Resolution_Bus_Enumerated;

   procedure Test_Bus_Idle_Command_Queued (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Bus_Idle, Command_Queued) = Execute_Explicit_Command,
              "Bus_Idle --Command_Queued--> Execute_Explicit_Command");
   end Test_Bus_Idle_Command_Queued;

   procedure Test_Bus_Idle_Poll_Interval_Reached_And_Queue_Empty (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Bus_Idle, Poll_Interval_Reached_And_Queue_Empty) = Autopolling,
              "Bus_Idle --Poll_Interval_Reached_And_Queue_Empty--> Autopolling");
   end Test_Bus_Idle_Poll_Interval_Reached_And_Queue_Empty;

   procedure Test_Execute_Explicit_Command_Transaction_Complete (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Execute_Explicit_Command, Transaction_Complete) = Evaluate_SRQ,
              "Execute_Explicit_Command --Transaction_Complete--> Evaluate_SRQ");
   end Test_Execute_Explicit_Command_Transaction_Complete;

   procedure Test_Autopolling_Transaction_Complete (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Autopolling, Transaction_Complete) = Evaluate_SRQ,
              "Autopolling --Transaction_Complete--> Evaluate_SRQ");
   end Test_Autopolling_Transaction_Complete;

   procedure Test_Evaluate_SRQ_SRQ_Asserted (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Evaluate_SRQ, SRQ_Asserted) = SRQ_Resolution,
              "Evaluate_SRQ --SRQ_Asserted--> SRQ_Resolution");
   end Test_Evaluate_SRQ_SRQ_Asserted;

   procedure Test_Evaluate_SRQ_SRQ_Not_Asserted (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Evaluate_SRQ, SRQ_Not_Asserted) = Bus_Idle,
              "Evaluate_SRQ --SRQ_Not_Asserted--> Bus_Idle");
   end Test_Evaluate_SRQ_SRQ_Not_Asserted;

   procedure Test_SRQ_Resolution_SRQ_Cleared (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (SRQ_Resolution, SRQ_Cleared) = Bus_Idle,
              "SRQ_Resolution --SRQ_Cleared--> Bus_Idle");
   end Test_SRQ_Resolution_SRQ_Cleared;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
      pragma Unreferenced (T);
   begin
      Register_Routine (T, Test_ADB_Reset_Reset_Complete'Access,
                        "ADB_Reset --Reset_Complete--> Address_Resolution");
      Register_Routine (T, Test_Address_Resolution_Bus_Enumerated'Access,
                        "Address_Resolution --Bus_Enumerated--> Bus_Idle");
      Register_Routine (T, Test_Bus_Idle_Command_Queued'Access,
                        "Bus_Idle --Command_Queued--> Execute_Explicit_Command");
      Register_Routine (T, Test_Bus_Idle_Poll_Interval_Reached_And_Queue_Empty'Access,
                        "Bus_Idle --Poll_Interval_Reached_And_Queue_Empty--> Autopolling");
      Register_Routine (T, Test_Execute_Explicit_Command_Transaction_Complete'Access,
                        "Execute_Explicit_Command --Transaction_Complete--> Evaluate_SRQ");
      Register_Routine (T, Test_Autopolling_Transaction_Complete'Access,
                        "Autopolling --Transaction_Complete--> Evaluate_SRQ");
      Register_Routine (T, Test_Evaluate_SRQ_SRQ_Asserted'Access,
                        "Evaluate_SRQ --SRQ_Asserted--> SRQ_Resolution");
      Register_Routine (T, Test_Evaluate_SRQ_SRQ_Not_Asserted'Access,
                        "Evaluate_SRQ --SRQ_Not_Asserted--> Bus_Idle");
      Register_Routine (T, Test_SRQ_Resolution_SRQ_Cleared'Access,
                        "SRQ_Resolution --SRQ_Cleared--> Bus_Idle");
      null;
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Machine");
   end Name;

end Machine_Tests;
