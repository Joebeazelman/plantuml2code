---------------------------------------------------------------------
--  Autopolling_Machine
---------------------------------------------------------------------


package body Autopolling_Machine is
   use Base;


   Table : constant array (State, Event) of State :=
     [
      Select_Next_Target =>
        [Target_Selected => Send_Poll_Command,
         Command_Sent => Select_Next_Target,
         Payload_Received => Select_Next_Target,
         Timeout_Normal_No_Data => Select_Next_Target,
         others => Select_Next_Target]
,
      Send_Poll_Command =>
        [Target_Selected => Send_Poll_Command,
         Command_Sent => Await_Poll_Response,
         Payload_Received => Send_Poll_Command,
         Timeout_Normal_No_Data => Send_Poll_Command,
         others => Send_Poll_Command]
,
      Await_Poll_Response =>
        [Target_Selected => Await_Poll_Response,
         Command_Sent => Await_Poll_Response,
         Payload_Received => Route_Poll_Data,
         Timeout_Normal_No_Data => End_State,
         others => Await_Poll_Response]
,
      Route_Poll_Data =>
        [Target_Selected => Route_Poll_Data,
         Command_Sent => Route_Poll_Data,
         Payload_Received => Route_Poll_Data,
         Timeout_Normal_No_Data => Route_Poll_Data,
         others => Route_Poll_Data]
,
      Start_State =>
        [Target_Selected => Start_State,
         Command_Sent => Start_State,
         Payload_Received => Start_State,
         Timeout_Normal_No_Data => Start_State,
         others => Start_State]
,
      End_State =>
        [Target_Selected => End_State,
         Command_Sent => End_State,
         Payload_Received => End_State,
         Timeout_Normal_No_Data => End_State,
         others => End_State]
     ];

   function Transition (From : State; On : Event) return State
   is (Table (From, On));

   overriding
   function Next_State (Self : Machine; On : Event) return State
   is (Table (Current_State (Self), On));

   overriding
   function Name (Self : Machine) return String is
      pragma Unreferenced (Self);
   begin
      return "Autopolling_Machine";
   end Name;

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      case Current_State (Self) is
         --  Retrieve the next active address from the internal Device Table
         when Select_Next_Target =>
            null;

         --  Send 'Talk Register 0' to the selected address
         when Send_Poll_Command =>
            null;

         --  Wait for the polled device to respond to Talk Register 0
         when Await_Poll_Response =>
            null;

         --  Pass payload to the installed ADB Device Handler for this address
         when Route_Poll_Data =>
            null;

         when Start_State =>
            null;

         when End_State =>
            Mark_Terminated (Self);

         when others =>
            null;
      end case;
   end On_Enter;

   overriding
   procedure On_Exit (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Select_Next_Target =>
            null;

         when Send_Poll_Command =>
            null;

         when Await_Poll_Response =>
            null;

         when Route_Poll_Data =>
            null;

         when Start_State =>
            null;

         when End_State =>
            null;

         when others =>
            null;
      end case;
   end On_Exit;

   overriding
   procedure On_Tick (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when others =>
            null;
      end case;
   end On_Tick;

   overriding
   function On_Internal (Self : in out Machine; On : Event) return Boolean
   is
   begin
      case Current_State (Self) is
         when others =>
            return False;
      end case;
   end On_Internal;

   overriding
   function Is_History_Entry
     (Self : Machine; From : State; On : Event)
      return Base.History_Mode is
      pragma Unreferenced (Self, From, On);
   begin
      case Current_State (Self) is
         when others =>
            return History_None;

      end case;
   end Is_History_Entry;


end Autopolling_Machine;
