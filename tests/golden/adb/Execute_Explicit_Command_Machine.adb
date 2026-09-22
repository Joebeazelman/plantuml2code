---------------------------------------------------------------------
--  Execute_Explicit_Command_Machine
---------------------------------------------------------------------


package body Execute_Explicit_Command_Machine is
   use Base;


   Table : constant array (State, Event) of State :=
     [
      Transmit_Explicit =>
        [Is_Talk_Command => Await_Explicit,
         Is_Listen_Or_Flush_Command => End_State,
         Data_Received => Transmit_Explicit,
         Timeout_Transaction_Failed => Transmit_Explicit,
         others => Transmit_Explicit]
,
      Await_Explicit =>
        [Is_Talk_Command => Await_Explicit,
         Is_Listen_Or_Flush_Command => Await_Explicit,
         Data_Received => Delegate_Explicit,
         Timeout_Transaction_Failed => End_State,
         others => Await_Explicit]
,
      Delegate_Explicit =>
        [Is_Talk_Command => Delegate_Explicit,
         Is_Listen_Or_Flush_Command => Delegate_Explicit,
         Data_Received => Delegate_Explicit,
         Timeout_Transaction_Failed => Delegate_Explicit,
         others => Delegate_Explicit]
,
      Start_State =>
        [Is_Talk_Command => Start_State,
         Is_Listen_Or_Flush_Command => Start_State,
         Data_Received => Start_State,
         Timeout_Transaction_Failed => Start_State,
         others => Start_State]
,
      End_State =>
        [Is_Talk_Command => End_State,
         Is_Listen_Or_Flush_Command => End_State,
         Data_Received => End_State,
         Timeout_Transaction_Failed => End_State,
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
      return "Execute_Explicit_Command_Machine";
   end Name;

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      case Current_State (Self) is
         --  Send Listen, Talk, or Flush command to specific target
         when Transmit_Explicit =>
            null;

         --  Wait for the target device to respond to the command
         when Await_Explicit =>
            null;

         --  Route response data to the caller's completion routine
         when Delegate_Explicit =>
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
         when Transmit_Explicit =>
            null;

         when Await_Explicit =>
            null;

         when Delegate_Explicit =>
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


end Execute_Explicit_Command_Machine;
