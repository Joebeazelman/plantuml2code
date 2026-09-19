--  ---------------------------------------------------------------------
--  Running_Machine (body)
--
--  Generated from ../samples/nested.puml on <DATE>.
--  ---------------------------------------------------------------------

with Running_Machine_Actions;

package body Running_Machine is

   use Base;
   use Running_Machine_Actions;


   Table : constant array (State, Event) of State :=
     [Start_State =>
        [Yield => Start_State,
         Resume => Start_State,
         Pause => Start_State],
      Spinning =>
        [Yield => Waiting,
         Resume => Spinning,
         Pause => Spinning],
      Waiting =>
        [Yield => Waiting,
         Resume => Spinning,
         Pause => Waiting]];

   overriding
   function Next_State (Self : Machine; On : Event) return State
   is (Table (Current_State (Self), On));

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;
         when Spinning =>
            null;
         when Waiting =>
            null;

      end case;
   end On_Enter;

   overriding
   procedure On_Exit (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;
         when Spinning =>
            null;
         when Waiting =>
            null;

      end case;
   end On_Exit;

   overriding
   procedure On_Tick (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Spinning =>
            Poll;

         when others => null;
      end case;
   end On_Tick;

   overriding
   function On_Internal (Self : in out Machine; On : Event) return Boolean is
   begin
      case Current_State (Self) is
         when Spinning =>
            if On = Pause then
               Halt;
               return True;
            end if;
            return False;

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
     ("Running_Machine");


end Running_Machine;
