--  One test per top-level transition: assert the generated transition
--  table maps (From, Event) to the model's target state.

with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with SRQ_Resolution_Machine;

package body SRQ_Resolution_Machine_Tests is

   use SRQ_Resolution_Machine;

   procedure Test_Identify_Source_Data_Received (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Identify_Source, Data_Received) = Route_SRQ,
              "Identify_Source --Data_Received--> Route_SRQ");
   end Test_Identify_Source_Data_Received;

   procedure Test_Route_SRQ_SRQ_Line_Cleared (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Route_SRQ, SRQ_Line_Cleared) = End_State,
              "Route_SRQ --SRQ_Line_Cleared--> End_State");
   end Test_Route_SRQ_SRQ_Line_Cleared;

   procedure Test_Identify_Source_Timeout_Try_Next_Address (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Transition (Identify_Source, Timeout_Try_Next_Address) = Identify_Source,
              "Identify_Source --Timeout_Try_Next_Address--> Identify_Source");
   end Test_Identify_Source_Timeout_Try_Next_Address;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
      pragma Unreferenced (T);
   begin
      Register_Routine (T, Test_Identify_Source_Data_Received'Access,
                        "Identify_Source --Data_Received--> Route_SRQ");
      Register_Routine (T, Test_Route_SRQ_SRQ_Line_Cleared'Access,
                        "Route_SRQ --SRQ_Line_Cleared--> End_State");
      Register_Routine (T, Test_Identify_Source_Timeout_Try_Next_Address'Access,
                        "Identify_Source --Timeout_Try_Next_Address--> Identify_Source");
      null;
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("SRQ_Resolution_Machine");
   end Name;

end SRQ_Resolution_Machine_Tests;
