---------------------------------------------------------------------
--  SRQ_Resolution_Machine
---------------------------------------------------------------------


package body SRQ_Resolution_Machine is
   use Base;


   Table : constant array (State, Event) of State :=
     [
      Identify_Source =>
        [Data_Received => Route_SRQ,
         SRQ_Line_Cleared => Identify_Source,
         Timeout_Try_Next_Address => Identify_Source,
         others => Identify_Source]
,
      Route_SRQ =>
        [Data_Received => Route_SRQ,
         SRQ_Line_Cleared => End_State,
         Timeout_Try_Next_Address => Route_SRQ,
         others => Route_SRQ]
,
      Start_State =>
        [Data_Received => Start_State,
         SRQ_Line_Cleared => Start_State,
         Timeout_Try_Next_Address => Start_State,
         others => Start_State]
,
      End_State =>
        [Data_Received => End_State,
         SRQ_Line_Cleared => End_State,
         Timeout_Try_Next_Address => End_State,
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
      return "SRQ_Resolution_Machine";
   end Name;

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      case Current_State (Self) is
         --  Issue 'Talk Register 0' sequentially
         --  to known active devices to find the assertor
         when Identify_Source =>
            null;

         --  Pass the interrupted payload to the matching ADB Device Handler
         when Route_SRQ =>
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
         when Identify_Source =>
            null;

         when Route_SRQ =>
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


end SRQ_Resolution_Machine;
