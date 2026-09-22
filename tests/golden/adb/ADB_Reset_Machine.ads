---------------------------------------------------------------------
--  ADB_Reset_Machine
---------------------------------------------------------------------

with State_Machine.Machines;

package ADB_Reset_Machine is

   type State is
     (Send_Reset_Cmd);

   type Event is
     (Tick);

   --  Transition lookup independent of any machine instance. The
   --  generated test suite asserts against this.
   function Transition (From : State; On : Event) return State;

   package Base is new State_Machine.Machines
     (State   => State,
      Event   => Event,
      Initial => Send_Reset_Cmd);

   type Machine is new Base.Machine with private;

   overriding
   function Next_State (Self : Machine; On : Event) return State;

   overriding
   function Name (Self : Machine) return String;

   overriding
   procedure On_Enter (Self : in out Machine);

   overriding
   procedure On_Exit (Self : in out Machine);

   overriding
   procedure On_Tick (Self : in out Machine);

   overriding
   function On_Internal (Self : in out Machine; On : Event)
                          return Boolean;

   overriding
   function Is_History_Entry
     (Self : Machine; From : State; On : Event)
      return Base.History_Mode;


private
   type Machine is new Base.Machine with null record;
end ADB_Reset_Machine;
