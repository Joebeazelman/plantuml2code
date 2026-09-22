---------------------------------------------------------------------
--  ADB_Reset_Machine
---------------------------------------------------------------------

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


end ADB_Reset_Machine;
