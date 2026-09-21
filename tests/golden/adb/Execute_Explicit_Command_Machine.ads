-----------------------------------------------------------------------
--  Execute_Explicit_Command_Machine
--  Apple Desktop Bus (ADB) Host Protocol Operations
--
--  State machine generated from ../samples/adb_protocol.puml
--
--  Generated from ../samples/adb_protocol.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
-----------------------------------------------------------------------

with State_Machine.Machines;

package Execute_Explicit_Command_Machine is

   type State is
     (Transmit_Explicit, Await_Explicit, Delegate_Explicit, Start_State, End_State);

   type Event is
     (Is_Talk_Command, Is_Listen_Or_Flush_Command, Data_Received, Timeout_Transaction_Failed);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Transmit_Explicit);

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

end Execute_Explicit_Command_Machine;
