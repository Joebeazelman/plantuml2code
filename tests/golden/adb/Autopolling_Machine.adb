-----------------------------------------------------------------------
--  Autopolling_Machine (body)
--
--  Generated from ../samples/adb_protocol.puml on <DATE>.
-----------------------------------------------------------------------

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

   overriding
   function Next_State (Self : Machine; On : Event) return State
   is (Table (Current_State (Self), On));

   overriding
   procedure On_Enter (Self : in out Machine) is
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
            Mark_Terminated (Self);
         when others => null;
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
         when others => null;
      end case;
   end On_Exit;

   overriding
   procedure On_Tick (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when others => null;
      end case;
   end On_Tick;

   overriding
   function On_Internal (Self : in out Machine; On : Event) return Boolean is
   begin
      case Current_State (Self) is
         when others =>
            return False;
      end case;
   end On_Internal;

   overriding
   function Is_History_Entry
     (Self : Machine; From : State; On : Event) return Base.History_Mode is
   begin
      case From is
         when others =>
            return History_None;

      end case;
   end Is_History_Entry;

   overriding
   function Name (Self : Machine) return String is
     ("Autopolling_Machine");


end Autopolling_Machine;
