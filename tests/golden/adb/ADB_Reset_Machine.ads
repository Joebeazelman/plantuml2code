-----------------------------------------------------------------------
--  ADB_Reset_Machine
--  Apple Desktop Bus (ADB) Host Protocol Operations
--
--  State machine generated from ../samples/adb_protocol.puml
--
--  Generated from ../samples/adb_protocol.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
-----------------------------------------------------------------------

with State_Machine.Machines;

package ADB_Reset_Machine is

   type State is
     (Send_Reset_Cmd);

   type Event is
     (Tick);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Send_Reset_Cmd);

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

end ADB_Reset_Machine;
