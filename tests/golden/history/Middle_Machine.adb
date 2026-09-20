--  ---------------------------------------------------------------------
--  Middle_Machine (body)
--
--  Generated from ../samples/history.puml on <DATE>.
--  ---------------------------------------------------------------------

package body Middle_Machine is

   use Base;


   Table : constant array (State, Event) of State :=
     [Start_State =>
        [Tick => Inner],
      Inner =>
        [Tick => Inner]];

   overriding
   function Next_State (Self : Machine; On : Event) return State
   is (Table (Current_State (Self), On));

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;
         when Inner =>
            case Via_History (Self) is
               when History_None =>
                  Inner_Machine.Base.Reset
                    (Self.Inner_Child);
               when History_Shallow =>
                  Inner_Machine.Base.Reset_To_Current
                    (Self.Inner_Child);
               when History_Deep =>
                  null;
            end case;
         when others => null;
      end case;
   end On_Enter;

   overriding
   procedure On_Exit (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;
         when Inner =>
            null;

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
     ("Middle_Machine");

   procedure Step_Inner (Self : in out Machine;
                            On : Inner_Machine.Event) is
   begin
      if Current_State (Self) = Inner then
         Inner_Machine.Base.Step (Self.Inner_Child, On);
      end if;
   end Step_Inner;

   function Inner_State (Self : Machine) return Inner_Machine.State is
   begin
      return Inner_Machine.Base.Current_State (Self.Inner_Child);
   end Inner_State;


end Middle_Machine;
