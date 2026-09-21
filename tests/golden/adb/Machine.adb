-----------------------------------------------------------------------
--  Machine (body)
--
--  Generated from ../samples/adb_protocol.puml on <DATE>.
-----------------------------------------------------------------------

package body Machine is

   use Base;


   Table : constant array (State, Event) of State :=
     [
      Start_State =>
        [Reset_Complete => Start_State,
         Bus_Enumerated => Start_State,
         Command_Queued => Start_State,
         Poll_Interval_Reached_And_Queue_Empty => Start_State,
         Transaction_Complete => Start_State,
         SRQ_Asserted => Start_State,
         SRQ_Not_Asserted => Start_State,
         SRQ_Cleared => Start_State,
         others => Start_State]
,
      ADB_Reset =>
        [Reset_Complete => Address_Resolution,
         Bus_Enumerated => ADB_Reset,
         Command_Queued => ADB_Reset,
         Poll_Interval_Reached_And_Queue_Empty => ADB_Reset,
         Transaction_Complete => ADB_Reset,
         SRQ_Asserted => ADB_Reset,
         SRQ_Not_Asserted => ADB_Reset,
         SRQ_Cleared => ADB_Reset,
         others => ADB_Reset]
,
      Address_Resolution =>
        [Reset_Complete => Address_Resolution,
         Bus_Enumerated => Bus_Idle,
         Command_Queued => Address_Resolution,
         Poll_Interval_Reached_And_Queue_Empty => Address_Resolution,
         Transaction_Complete => Address_Resolution,
         SRQ_Asserted => Address_Resolution,
         SRQ_Not_Asserted => Address_Resolution,
         SRQ_Cleared => Address_Resolution,
         others => Address_Resolution]
,
      Bus_Idle =>
        [Reset_Complete => Bus_Idle,
         Bus_Enumerated => Bus_Idle,
         Command_Queued => Execute_Explicit_Command,
         Poll_Interval_Reached_And_Queue_Empty => Autopolling,
         Transaction_Complete => Bus_Idle,
         SRQ_Asserted => Bus_Idle,
         SRQ_Not_Asserted => Bus_Idle,
         SRQ_Cleared => Bus_Idle,
         others => Bus_Idle]
,
      Execute_Explicit_Command =>
        [Reset_Complete => Execute_Explicit_Command,
         Bus_Enumerated => Execute_Explicit_Command,
         Command_Queued => Execute_Explicit_Command,
         Poll_Interval_Reached_And_Queue_Empty => Execute_Explicit_Command,
         Transaction_Complete => Evaluate_SRQ,
         SRQ_Asserted => Execute_Explicit_Command,
         SRQ_Not_Asserted => Execute_Explicit_Command,
         SRQ_Cleared => Execute_Explicit_Command,
         others => Execute_Explicit_Command]
,
      Autopolling =>
        [Reset_Complete => Autopolling,
         Bus_Enumerated => Autopolling,
         Command_Queued => Autopolling,
         Poll_Interval_Reached_And_Queue_Empty => Autopolling,
         Transaction_Complete => Evaluate_SRQ,
         SRQ_Asserted => Autopolling,
         SRQ_Not_Asserted => Autopolling,
         SRQ_Cleared => Autopolling,
         others => Autopolling]
,
      Evaluate_SRQ =>
        [Reset_Complete => Evaluate_SRQ,
         Bus_Enumerated => Evaluate_SRQ,
         Command_Queued => Evaluate_SRQ,
         Poll_Interval_Reached_And_Queue_Empty => Evaluate_SRQ,
         Transaction_Complete => Evaluate_SRQ,
         SRQ_Asserted => SRQ_Resolution,
         SRQ_Not_Asserted => Bus_Idle,
         SRQ_Cleared => Evaluate_SRQ,
         others => Evaluate_SRQ]
,
      SRQ_Resolution =>
        [Reset_Complete => SRQ_Resolution,
         Bus_Enumerated => SRQ_Resolution,
         Command_Queued => SRQ_Resolution,
         Poll_Interval_Reached_And_Queue_Empty => SRQ_Resolution,
         Transaction_Complete => SRQ_Resolution,
         SRQ_Asserted => SRQ_Resolution,
         SRQ_Not_Asserted => SRQ_Resolution,
         SRQ_Cleared => Bus_Idle,
         others => SRQ_Resolution]
     ];

   overriding
   function Next_State (Self : Machine; On : Event) return State
   is (Table (Current_State (Self), On));

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;
         when ADB_Reset =>
            case Via_History (Self) is
               when History_None =>
                  ADB_Reset_Machine.Base.Reset
                    (Self.ADB_Reset_Child);
               when History_Shallow =>
                  ADB_Reset_Machine.Base.Reset_To_Current
                    (Self.ADB_Reset_Child);
               when History_Deep =>
                  null;
            end case;
         when Address_Resolution =>
            case Via_History (Self) is
               when History_None =>
                  Address_Resolution_Machine.Base.Reset
                    (Self.Address_Resolution_Child);
               when History_Shallow =>
                  Address_Resolution_Machine.Base.Reset_To_Current
                    (Self.Address_Resolution_Child);
               when History_Deep =>
                  null;
            end case;
         when Bus_Idle =>
            null;
         when Execute_Explicit_Command =>
            case Via_History (Self) is
               when History_None =>
                  Execute_Explicit_Command_Machine.Base.Reset
                    (Self.Execute_Explicit_Command_Child);
               when History_Shallow =>
                  Execute_Explicit_Command_Machine.Base.Reset_To_Current
                    (Self.Execute_Explicit_Command_Child);
               when History_Deep =>
                  null;
            end case;
         when Autopolling =>
            case Via_History (Self) is
               when History_None =>
                  Autopolling_Machine.Base.Reset
                    (Self.Autopolling_Child);
               when History_Shallow =>
                  Autopolling_Machine.Base.Reset_To_Current
                    (Self.Autopolling_Child);
               when History_Deep =>
                  null;
            end case;
         when Evaluate_SRQ =>
            null;
         when SRQ_Resolution =>
            case Via_History (Self) is
               when History_None =>
                  SRQ_Resolution_Machine.Base.Reset
                    (Self.SRQ_Resolution_Child);
               when History_Shallow =>
                  SRQ_Resolution_Machine.Base.Reset_To_Current
                    (Self.SRQ_Resolution_Child);
               when History_Deep =>
                  null;
            end case;
         when others => null;
      end case;
   end On_Enter;

   overriding
   procedure On_Exit (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;
         when ADB_Reset =>
            null;
         when Address_Resolution =>
            null;
         when Bus_Idle =>
            null;
         when Execute_Explicit_Command =>
            null;
         when Autopolling =>
            null;
         when Evaluate_SRQ =>
            null;
         when SRQ_Resolution =>
            null;
         when others => null;
      end case;
   end On_Exit;

   overriding
   procedure On_Tick (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when others => null;
      end case;
   end On_Tick;

   overriding
   function On_Internal (Self : in out Machine; On : Event) return Boolean is
   begin
      case Current_State (Self) is
         when others =>
            return False;
      end case;
   end On_Internal;

   overriding
   function Is_History_Entry
     (Self : Machine; From : State; On : Event) return Base.History_Mode is
   begin
      case From is
         when others =>
            return History_None;

      end case;
   end Is_History_Entry;

   overriding
   function Name (Self : Machine) return String is
     ("Machine");

   procedure Step_ADB_Reset (Self : in out Machine;
                            On : ADB_Reset_Machine.Event) is
   begin
      if Current_State (Self) = ADB_Reset then
         ADB_Reset_Machine.Base.Step (Self.ADB_Reset_Child, On);
      end if;
   end Step_ADB_Reset;

   function ADB_Reset_State (Self : Machine) return ADB_Reset_Machine.State is
   begin
      return ADB_Reset_Machine.Base.Current_State (Self.ADB_Reset_Child);
   end ADB_Reset_State;

   procedure Step_Address_Resolution (Self : in out Machine;
                            On : Address_Resolution_Machine.Event) is
   begin
      if Current_State (Self) = Address_Resolution then
         Address_Resolution_Machine.Base.Step (Self.Address_Resolution_Child, On);
      end if;
   end Step_Address_Resolution;

   function Address_Resolution_State (Self : Machine) return Address_Resolution_Machine.State is
   begin
      return Address_Resolution_Machine.Base.Current_State (Self.Address_Resolution_Child);
   end Address_Resolution_State;

   procedure Step_Execute_Explicit_Command (Self : in out Machine;
                            On : Execute_Explicit_Command_Machine.Event) is
   begin
      if Current_State (Self) = Execute_Explicit_Command then
         Execute_Explicit_Command_Machine.Base.Step (Self.Execute_Explicit_Command_Child, On);
      end if;
   end Step_Execute_Explicit_Command;

   function Execute_Explicit_Command_State (Self : Machine) return Execute_Explicit_Command_Machine.State is
   begin
      return Execute_Explicit_Command_Machine.Base.Current_State (Self.Execute_Explicit_Command_Child);
   end Execute_Explicit_Command_State;

   procedure Step_Autopolling (Self : in out Machine;
                            On : Autopolling_Machine.Event) is
   begin
      if Current_State (Self) = Autopolling then
         Autopolling_Machine.Base.Step (Self.Autopolling_Child, On);
      end if;
   end Step_Autopolling;

   function Autopolling_State (Self : Machine) return Autopolling_Machine.State is
   begin
      return Autopolling_Machine.Base.Current_State (Self.Autopolling_Child);
   end Autopolling_State;

   procedure Step_SRQ_Resolution (Self : in out Machine;
                            On : SRQ_Resolution_Machine.Event) is
   begin
      if Current_State (Self) = SRQ_Resolution then
         SRQ_Resolution_Machine.Base.Step (Self.SRQ_Resolution_Child, On);
      end if;
   end Step_SRQ_Resolution;

   function SRQ_Resolution_State (Self : Machine) return SRQ_Resolution_Machine.State is
   begin
      return SRQ_Resolution_Machine.Base.Current_State (Self.SRQ_Resolution_Child);
   end SRQ_Resolution_State;


end Machine;
