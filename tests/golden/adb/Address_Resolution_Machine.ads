---------------------------------------------------------------------
--  Address_Resolution_Machine
---------------------------------------------------------------------

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


end Address_Resolution_Machine;
