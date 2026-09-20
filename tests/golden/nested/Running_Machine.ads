--  ---------------------------------------------------------------------
--  Running_Machine
--
--  State machine generated from ../samples/nested.puml
--
--  Generated from ../samples/nested.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
--  ---------------------------------------------------------------------

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


private

   type Machine is new Base.Machine with null record;

end Running_Machine;
