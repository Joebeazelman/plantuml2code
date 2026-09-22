---------------------------------------------------------------------
--  Inner_Machine
---------------------------------------------------------------------
with Inner_Machine_Actions;



package body Inner_Machine is
   use Base;
   use Inner_Machine_Actions;


   Table : constant array (State, Event) of State :=
     [
      Start_State =>
        [Advance => Start_State,
         others => Start_State]
,
      A =>
        [Advance => B,
         others => A]
,
      B =>
        [Advance => B,
         others => B]
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
      return "Inner_Machine";
   end Name;

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;

         when A =>
            Entered_A;

         when B =>
            Entered_B;

         when others =>
            null;
      end case;
   end On_Enter;

   overriding
   procedure On_Exit (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;

         when A =>
            null;

         when B =>
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


end Inner_Machine;
