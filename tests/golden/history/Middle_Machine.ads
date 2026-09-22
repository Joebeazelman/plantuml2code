---------------------------------------------------------------------
--  Middle_Machine
---------------------------------------------------------------------

with State_Machine.Machines;
with Inner_Machine;

package Middle_Machine is

   type State is
     (Start_State, Inner);

   type Event is
     (Tick);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Inner);

   type Machine is new Base.Machine with private;

   procedure Step_Inner (Self : in out Machine;
                            On : Inner_Machine.Event);

   function Inner_State (Self : Machine) return Inner_Machine.State;


end Middle_Machine;
