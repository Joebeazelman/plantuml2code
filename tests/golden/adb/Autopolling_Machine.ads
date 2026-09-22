---------------------------------------------------------------------
--  Autopolling_Machine
---------------------------------------------------------------------

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


end Autopolling_Machine;
