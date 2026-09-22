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

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Idle);

   type Machine is new Base.Machine with private;

   procedure Step_Running (Self : in out Machine;
                            On : Running_Machine.Event);

   function Running_State (Self : Machine) return Running_Machine.State;


end Nested;
