--  ---------------------------------------------------------------------
--  Inner_Machine (body)
--
--  Generated from ../samples/history.puml on <DATE>.
--  ---------------------------------------------------------------------

with Inner_Machine_Actions;

package body Inner_Machine is

   use Base;
   use Inner_Machine_Actions;


   Table : constant array (State, Event) of State :=
     [Start_State =>
        [Advance => Start_State],
      A =>
        [Advance => B],
      B =>
        [Advance => B]];

   overriding
   function Next_State (Self : Machine; On : Event) return State
   is (Table (Current_State (Self), On));

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
         when others => null;
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
     ("Inner_Machine");


end Inner_Machine;
