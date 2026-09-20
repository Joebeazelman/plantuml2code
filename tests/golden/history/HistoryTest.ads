--  ---------------------------------------------------------------------
--  HistoryTest
--
--  State machine generated from ../samples/history.puml
--
--  Generated from ../samples/history.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
--  ---------------------------------------------------------------------

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

   overriding
   function Next_State (Self : Machine; On : Event) return State;

   overriding
   procedure On_Enter (Self : in out Machine);

   overriding
   procedure On_Exit (Self : in out Machine);

   overriding
   procedure On_Tick (Self : in out Machine);

   overriding
   function On_Internal (Self : in out Machine; On : Event) return Boolean;

   overriding
   function Is_History_Entry
     (Self : Machine; From : State; On : Event) return Base.History_Mode;

   overriding
   function Name (Self : Machine) return String;

   procedure Step_Outer (Self : in out Machine;
                            On : Outer_Machine.Event);

   function Outer_State (Self : Machine) return Outer_Machine.State;

   procedure Step_Outer_Middle (Self : in out Machine;
                            On : Middle_Machine.Event);

   function Outer_Middle_State (Self : Machine) return Middle_Machine.State;

   procedure Step_Outer_Middle_Inner (Self : in out Machine;
                            On : Inner_Machine.Event);

   function Outer_Middle_Inner_State (Self : Machine) return Inner_Machine.State;


private

   type Machine is new Base.Machine with record
      Outer_Child : Outer_Machine.Machine;
   end record;

end HistoryTest;
