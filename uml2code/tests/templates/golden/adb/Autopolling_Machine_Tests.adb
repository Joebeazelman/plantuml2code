--  One test per top-level transition: assert the generated transition
--  table maps (From, Event) to the model's target state.

with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Autopolling_Machine;

package body Autopolling_Machine_Tests is

   use Autopolling_Machine;

   procedure Test_Select_Next_Target_Target_Selected (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Select_Next_Target, Target_Selected) = Send_Poll_Command,
              "Select_Next_Target --Target_Selected--> Send_Poll_Command");
   end Test_Select_Next_Target_Target_Selected;

   procedure Test_Send_Poll_Command_Command_Sent (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Send_Poll_Command, Command_Sent) = Await_Poll_Response,
              "Send_Poll_Command --Command_Sent--> Await_Poll_Response");
   end Test_Send_Poll_Command_Command_Sent;

   procedure Test_Await_Poll_Response_Payload_Received (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Await_Poll_Response, Payload_Received) = Route_Poll_Data,
              "Await_Poll_Response --Payload_Received--> Route_Poll_Data");
   end Test_Await_Poll_Response_Payload_Received;

   procedure Test_Await_Poll_Response_Timeout_Normal_No_Data (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Await_Poll_Response, Timeout_Normal_No_Data) = End_State,
              "Await_Poll_Response --Timeout_Normal_No_Data--> End_State");
   end Test_Await_Poll_Response_Timeout_Normal_No_Data;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
      pragma Warnings (Off, "no entities of");
      pragma Warnings (Off, "use clause for package");
      pragma Warnings (Off, "aspect Unreferenced");
   begin
      Register_Routine (T, Test_Select_Next_Target_Target_Selected'Access,
                        "Select_Next_Target --Target_Selected--> Send_Poll_Command");
      Register_Routine (T, Test_Send_Poll_Command_Command_Sent'Access,
                        "Send_Poll_Command --Command_Sent--> Await_Poll_Response");
      Register_Routine (T, Test_Await_Poll_Response_Payload_Received'Access,
                        "Await_Poll_Response --Payload_Received--> Route_Poll_Data");
      Register_Routine (T, Test_Await_Poll_Response_Timeout_Normal_No_Data'Access,
                        "Await_Poll_Response --Timeout_Normal_No_Data--> End_State");
      null;
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Autopolling_Machine");
   end Name;

end Autopolling_Machine_Tests;
