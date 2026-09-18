--  ---------------------------------------------------------------------
--  Nested (body)
--
--  Generated from ../samples/nested.puml on <DATE>.
--  ---------------------------------------------------------------------

with Nested_Actions;

package body Nested is

   use Base;
   use Nested_Actions;

   Table : constant array (State, Event) of State :=
     [Start_State =>
        [Start => Start_State,
         Stop => Start_State,
         Finish => Start_State,
         Tick => Idle],
      Idle =>
        [Start => Running,
         Stop => Idle,
         Finish => Idle,
         Tick => Idle],
      Running =>
        [Start => Running,
         Stop => Idle,
         Finish => End_State,
         Tick => Running],
      End_State =>
        [Start => End_State,
         Stop => End_State,
         Finish => End_State,
         Tick => End_State]];

   overriding
   function Next_State (Self : Machine; On : Event) return State
   is (Table (Current_State (Self), On));

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Running =>
            Running_Machine.Base.Reset (Self.Running_Child);
         when Start_State =>
            null;
         when Idle =>
            Log_Idle;
         when End_State =>
            null;

      end case;
   end On_Enter;

   overriding
   procedure On_Exit (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;
         when Idle =>
            Cleanup_Idle;
         when Running =>
            null;
         when End_State =>
            null;

      end case;
   end On_Exit;

   overriding
   function On_Internal (Self : in out Machine; On : Event) return Boolean is
   begin
      case Current_State (Self) is
         when Idle =>
            if On = Tick then
               Bump;
               return True;
            end if;
            return False;

         when others =>
            return False;
      end case;
   end On_Internal;

   overriding
   function Name (Self : Machine) return String is
     ("Nested");

   procedure Step_Running (Self : in out Machine;
                            On : Running_Machine.Event) is
   begin
      if Current_State (Self) = Running then
         Running_Machine.Base.Step (Self.Running_Child, On);
      end if;
   end Step_Running;


end Nested;
