---------------------------------------------------------------------
--  Execute_Explicit_Command_Machine
---------------------------------------------------------------------

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


end Execute_Explicit_Command_Machine;
