---------------------------------------------------------------------
--  Outer_Machine
---------------------------------------------------------------------

with State_Machine.Machines;
with Middle_Machine;
with Inner_Machine;

package Outer_Machine is

   type State is
     (Start_State, Middle);

   type Event is
     (Tick);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Middle);

   type Machine is new Base.Machine with private;

   procedure Step_Middle (Self : in out Machine;
                            On : Middle_Machine.Event);

   function Middle_State (Self : Machine) return Middle_Machine.State;

   procedure Step_Middle_Inner (Self : in out Machine;
                            On : Inner_Machine.Event);

   function Middle_Inner_State (Self : Machine) return Inner_Machine.State;


end Outer_Machine;
