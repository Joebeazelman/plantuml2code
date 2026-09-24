---------------------------------------------------------------------
--  Outer_Machine
---------------------------------------------------------------------

with State_Machine.Machines;
with Middle_Machine;
with Inner_Machine;

package Outer_Machine is

   type State is (Start_State, Middle);

   type Event is (Tick);

   --  Transition lookup independent of any machine instance. The
   --  generated test suite asserts against this.
   function Transition (From : State; On : Event) return State;

   package Base is new
     State_Machine.Machines
       (State   => State,
        Event   => Event,
        Initial => Middle);

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
   function On_Internal (Self : in out Machine; On : Event) return Boolean;

   overriding
   function Is_History_Entry
     (Self : Machine; From : State; On : Event) return Base.History_Mode;

   procedure Step_Middle (Self : in out Machine; On : Middle_Machine.Event);

   function Middle_State (Self : Machine) return Middle_Machine.State;

   procedure Step_Middle_Inner
     (Self : in out Machine; On : Inner_Machine.Event);

   function Middle_Inner_State (Self : Machine) return Inner_Machine.State;

private
   type Machine is new Base.Machine with record
      Middle_Child : Middle_Machine.Machine;
   end record;
end Outer_Machine;
