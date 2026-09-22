---------------------------------------------------------------------
--  Machine
--  Apple Desktop Bus (ADB) Host Protocol Operations
---------------------------------------------------------------------

with State_Machine.Machines;
with ADB_Reset_Machine;
with Address_Resolution_Machine;
with Execute_Explicit_Command_Machine;
with Autopolling_Machine;
with SRQ_Resolution_Machine;

package Machine is

   type State is
     (Start_State, ADB_Reset, Address_Resolution, Bus_Idle, Execute_Explicit_Command, Autopolling, Evaluate_SRQ, SRQ_Resolution);

   type Event is
     (Reset_Complete, Bus_Enumerated, Command_Queued, Poll_Interval_Reached_And_Queue_Empty, Transaction_Complete, SRQ_Asserted, SRQ_Not_Asserted, SRQ_Cleared);

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => ADB_Reset);

   type Machine is new Base.Machine with private;

   procedure Step_ADB_Reset (Self : in out Machine;
                            On : ADB_Reset_Machine.Event);

   function ADB_Reset_State (Self : Machine) return ADB_Reset_Machine.State;

   procedure Step_Address_Resolution (Self : in out Machine;
                            On : Address_Resolution_Machine.Event);

   function Address_Resolution_State (Self : Machine) return Address_Resolution_Machine.State;

   procedure Step_Execute_Explicit_Command (Self : in out Machine;
                            On : Execute_Explicit_Command_Machine.Event);

   function Execute_Explicit_Command_State (Self : Machine) return Execute_Explicit_Command_Machine.State;

   procedure Step_Autopolling (Self : in out Machine;
                            On : Autopolling_Machine.Event);

   function Autopolling_State (Self : Machine) return Autopolling_Machine.State;

   procedure Step_SRQ_Resolution (Self : in out Machine;
                            On : SRQ_Resolution_Machine.Event);

   function SRQ_Resolution_State (Self : Machine) return SRQ_Resolution_Machine.State;


end Machine;
