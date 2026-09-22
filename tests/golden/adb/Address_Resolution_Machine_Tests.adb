--  One test per top-level transition: assert the generated transition
--  table maps (From, Event) to the model's target state.

with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Address_Resolution_Machine;

package body Address_Resolution_Machine_Tests is

   use Address_Resolution_Machine;

   procedure Test_Check_Default_Address_Command_Sent (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Check_Default_Address, Command_Sent) = Await_Default_Response,
              "Check_Default_Address --Command_Sent--> Await_Default_Response");
   end Test_Check_Default_Address_Command_Sent;

   procedure Test_Await_Default_Response_Response_Detected (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Await_Default_Response, Response_Detected) = Relocate_Devices,
              "Await_Default_Response --Response_Detected--> Relocate_Devices");
   end Test_Await_Default_Response_Response_Detected;

   procedure Test_Relocate_Devices_Relocation_Command_Sent (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Relocate_Devices, Relocation_Command_Sent) = Resolve_Collisions,
              "Relocate_Devices --Relocation_Command_Sent--> Resolve_Collisions");
   end Test_Relocate_Devices_Relocation_Command_Sent;

   procedure Test_Resolve_Collisions_Winner_Data_Received (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Resolve_Collisions, Winner_Data_Received) = Validate_Winner,
              "Resolve_Collisions --Winner_Data_Received--> Validate_Winner");
   end Test_Resolve_Collisions_Winner_Data_Received;

   procedure Test_Validate_Winner_Repeat_For_Remaining_Devices (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Validate_Winner, Repeat_For_Remaining_Devices) = Check_Default_Address,
              "Validate_Winner --Repeat_For_Remaining_Devices--> Check_Default_Address");
   end Test_Validate_Winner_Repeat_For_Remaining_Devices;

   procedure Test_Await_Default_Response_Timeout_No_Devices (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Await_Default_Response, Timeout_No_Devices) = End_State,
              "Await_Default_Response --Timeout_No_Devices--> End_State");
   end Test_Await_Default_Response_Timeout_No_Devices;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
      pragma Unreferenced (T);
   begin
      Register_Routine (T, Test_Check_Default_Address_Command_Sent'Access,
                        "Check_Default_Address --Command_Sent--> Await_Default_Response");
      Register_Routine (T, Test_Await_Default_Response_Response_Detected'Access,
                        "Await_Default_Response --Response_Detected--> Relocate_Devices");
      Register_Routine (T, Test_Relocate_Devices_Relocation_Command_Sent'Access,
                        "Relocate_Devices --Relocation_Command_Sent--> Resolve_Collisions");
      Register_Routine (T, Test_Resolve_Collisions_Winner_Data_Received'Access,
                        "Resolve_Collisions --Winner_Data_Received--> Validate_Winner");
      Register_Routine (T, Test_Validate_Winner_Repeat_For_Remaining_Devices'Access,
                        "Validate_Winner --Repeat_For_Remaining_Devices--> Check_Default_Address");
      Register_Routine (T, Test_Await_Default_Response_Timeout_No_Devices'Access,
                        "Await_Default_Response --Timeout_No_Devices--> End_State");
      null;
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Address_Resolution_Machine");
   end Name;

end Address_Resolution_Machine_Tests;
