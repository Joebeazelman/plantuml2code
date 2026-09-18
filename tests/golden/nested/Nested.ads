--  ---------------------------------------------------------------------
--  Nested
--
--  State machine generated from ../samples/nested.puml
--
--  Generated from ../samples/nested.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
--  ---------------------------------------------------------------------

with HSM.Machines;
with Running_Machine;

package Nested is

   type State is
     (Start_State, Idle, Running, End_State);

   type Event is
     (Start, Stop, Finish, Tick);

   package Base is new HSM.Machines
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
   function On_Internal (Self : in out Machine; On : Event) return Boolean;

   overriding
   function Name (Self : Machine) return String;

   procedure Step_Running (Self : in out Machine;
                            On : Running_Machine.Event);


private

   type Machine is new Base.Machine with record
      Running_Child : Running_Machine.Machine;
   end record;

end Nested;
