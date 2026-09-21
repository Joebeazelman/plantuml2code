-----------------------------------------------------------------------
--  Address_Resolution_Machine
--  Apple Desktop Bus (ADB) Host Protocol Operations
--
--  State machine generated from ../samples/adb_protocol.puml
--
--  Generated from ../samples/adb_protocol.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
-----------------------------------------------------------------------

with State_Machine.Machines;

package Address_Resolution_Machine is

   type State is
     (Check_Default_Address, Await_Default_Response, Relocate_Devices, Resolve_Collisions, Validate_Winner, Start_State, End_State);

   type Event is
     (Command_Sent, Response_Detected, Relocation_Command_Sent, Winner_Data_Received, Repeat_For_Remaining_Devices, Timeout_No_Devices);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Check_Default_Address);

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

end Address_Resolution_Machine;
