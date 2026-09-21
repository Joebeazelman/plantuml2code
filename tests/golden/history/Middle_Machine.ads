-----------------------------------------------------------------------
--  Middle_Machine
--
--  State machine generated from ../samples/history.puml
--
--  Generated from ../samples/history.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
-----------------------------------------------------------------------

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

   procedure Step_Inner (Self : in out Machine;
                            On : Inner_Machine.Event);

   function Inner_State (Self : Machine) return Inner_Machine.State;


private

   type Machine is new Base.Machine with record
      Inner_Child : Inner_Machine.Machine;
   end record;

end Middle_Machine;
