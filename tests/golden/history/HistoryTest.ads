---------------------------------------------------------------------
--  HistoryTest
---------------------------------------------------------------------

with State_Machine.Machines;
with Outer_Machine;
with Middle_Machine;
with Inner_Machine;

package HistoryTest is

   type State is
     (Start_State, Idle, Outer);

   type Event is
     (Enter_Fresh, Enter_Shallow, Enter_Deep, Back);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Idle);

   type Machine is new Base.Machine with private;

   procedure Step_Outer (Self : in out Machine;
                            On : Outer_Machine.Event);

   function Outer_State (Self : Machine) return Outer_Machine.State;

   procedure Step_Outer_Middle (Self : in out Machine;
                            On : Middle_Machine.Event);

   function Outer_Middle_State (Self : Machine) return Middle_Machine.State;

   procedure Step_Outer_Middle_Inner (Self : in out Machine;
                            On : Inner_Machine.Event);

   function Outer_Middle_Inner_State (Self : Machine) return Inner_Machine.State;


end HistoryTest;
