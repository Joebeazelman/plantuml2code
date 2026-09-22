---------------------------------------------------------------------
--  Inner_Machine
---------------------------------------------------------------------

with State_Machine.Machines;

package Inner_Machine is

   type State is
     (Start_State, A, B);

   type Event is
     (Advance);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => A);

   type Machine is new Base.Machine with private;


end Inner_Machine;
