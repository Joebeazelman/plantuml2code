---------------------------------------------------------------------
--  Running_Machine
---------------------------------------------------------------------

with State_Machine.Machines;

package Running_Machine is

   type State is
     (Start_State, Spinning, Waiting);

   type Event is
     (Yield, Resume, Pause);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Spinning);

   type Machine is new Base.Machine with private;


end Running_Machine;
