---------------------------------------------------------------------
--  ADB_Reset_Machine
---------------------------------------------------------------------


package body ADB_Reset_Machine is


   Table : constant array (State, Event) of State :=
     [
      Send_Reset_Cmd =>
        [Tick => Send_Reset_Cmd,
         others => Send_Reset_Cmd]
     ];

   overriding
   function Next_State (Self : Machine; On : Event) return State
   is (Table (Current_State (Self), On));

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      case Current_State (Self) is
         --  Drive bus low for ~3ms to reset all devices to default states
         when Send_Reset_Cmd =>
            null;

         when others =>
            null;
      end case;
   end On_Enter;

   overriding
   procedure On_Exit (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Send_Reset_Cmd =>
            null;

         when others =>
            null;
      end case;
   end On_Exit;

   overriding
   procedure On_Tick (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Send_Reset_Cmd =>

         when others =>
            null;
      end case;
   end On_Tick;

   overriding
   function On_Internal (Self : in out Machine; On : Event) return Boolean
   is
   begin
      case Current_State (Self) is
         when Send_Reset_Cmd =>

         when others =>
            return False;
      end case;
   end On_Internal;

   overriding
   function Is_History_Entry (Self : Machine; On : Event)
                              return History_Kind is
      pragma Unreferenced (Self, On);
   begin
      case Current_State (Self) is
         when others =>
            return History_None;

      end case;
   end Is_History_Entry;


end ADB_Reset_Machine;
