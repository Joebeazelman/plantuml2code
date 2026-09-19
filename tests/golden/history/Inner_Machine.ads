--  ---------------------------------------------------------------------
--  Inner_Machine
--
--  State machine generated from ../samples/history.puml
--
--  Generated from ../samples/history.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
--  ---------------------------------------------------------------------

with HSM.Machines;

package Inner_Machine is

   type State is
     (Start_State, A, B);

   type Event is
     (Advance);

   package Base is new HSM.Machines
     (State   => State,
      Event   => Event,
      Initial => A);

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

end Inner_Machine;
