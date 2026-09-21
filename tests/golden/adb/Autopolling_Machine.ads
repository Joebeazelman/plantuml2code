-----------------------------------------------------------------------
--  Autopolling_Machine
--  Apple Desktop Bus (ADB) Host Protocol Operations
--
--  State machine generated from ../samples/adb_protocol.puml
--
--  Generated from ../samples/adb_protocol.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
-----------------------------------------------------------------------

with State_Machine.Machines;

package Autopolling_Machine is

   type State is
     (Select_Next_Target, Send_Poll_Command, Await_Poll_Response, Route_Poll_Data, Start_State, End_State);

   type Event is
     (Target_Selected, Command_Sent, Payload_Received, Timeout_Normal_No_Data);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Select_Next_Target);

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

end Autopolling_Machine;
