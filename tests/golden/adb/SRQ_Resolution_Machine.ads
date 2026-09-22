---------------------------------------------------------------------
--  SRQ_Resolution_Machine
---------------------------------------------------------------------

with State_Machine.Machines;

package SRQ_Resolution_Machine is

   type State is
     (Identify_Source, Route_SRQ, Start_State, End_State);

   type Event is
     (Data_Received, SRQ_Line_Cleared, Timeout_Try_Next_Address);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Identify_Source);

   type Machine is new Base.Machine with private;


end SRQ_Resolution_Machine;
