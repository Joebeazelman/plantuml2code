---------------------------------------------------------------------
--  Nested
---------------------------------------------------------------------

with State_Machine.Machines;
with Running_Machine;

package Nested is

   type State is
     (Start_State, Idle, Running, End_State);

   type Event is
     (Start, Continue, Stop, Finish, Tick);

   --  Transition lookup independent of any machine instance. The
   --  generated test suite asserts against this.
   function Transition (From : State; On : Event) return State;

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Idle);

   type Machine is new Base.Machine with private;

   overriding
   function Next_State (Self : Machine; On : Event) return State;

   overriding
   function Name (Self : Machine) return String;

   overriding
   procedure On_Enter (Self : in out Machine);

   overriding
   procedure On_Exit (Self : in out Machine);

   overriding
   procedure On_Tick (Self : in out Machine);

   overriding
   function On_Internal (Self : in out Machine; On : Event)
                          return Boolean;

   overriding
   function Is_History_Entry
     (Self : Machine; From : State; On : Event)
      return Base.History_Mode;

   procedure Step_Running (Self : in out Machine;
                            On : Running_Machine.Event);

   function Running_State (Self : Machine) return Running_Machine.State;


private
   type Machine is new Base.Machine with record
      Running_Child : Running_Machine.Machine;
   end record;
end Nested;
