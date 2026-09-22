---------------------------------------------------------------------
--  Outer_Machine
---------------------------------------------------------------------


package body Outer_Machine is
   use Base;


   Table : constant array (State, Event) of State :=
     [
      Start_State =>
        [Tick => Middle,
         others => Start_State]
,
      Middle =>
        [Tick => Middle,
         others => Middle]
     ];

   function Transition (From : State; On : Event) return State
   is (Table (From, On));

   overriding
   function Next_State (Self : Machine; On : Event) return State
   is (Table (Current_State (Self), On));

   overriding
   function Name (Self : Machine) return String is
      pragma Unreferenced (Self);
   begin
      return "Outer_Machine";
   end Name;

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;

         when Middle =>
            case Via_History (Self) is
               when History_None =>
                  Middle_Machine.Base.Reset
                    (Self.Middle_Child);
               when History_Shallow =>
                  Middle_Machine.Base.Reset_To_Current
                    (Self.Middle_Child);
               when History_Deep =>
                  null;
            end case;

         when others =>
            null;
      end case;
   end On_Enter;

   overriding
   procedure On_Exit (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when Start_State =>
            null;

         when Middle =>
            null;

         when others =>
            null;
      end case;
   end On_Exit;

   overriding
   procedure On_Tick (Self : in out Machine) is
   begin
      case Current_State (Self) is
         when others =>
            null;
      end case;
   end On_Tick;

   overriding
   function On_Internal (Self : in out Machine; On : Event) return Boolean
   is
   begin
      case Current_State (Self) is
         when others =>
            return False;
      end case;
   end On_Internal;

   overriding
   function Is_History_Entry
     (Self : Machine; From : State; On : Event)
      return Base.History_Mode is
      pragma Unreferenced (Self, From, On);
   begin
      case Current_State (Self) is
         when others =>
            return History_None;

      end case;
   end Is_History_Entry;

   procedure Step_Middle (Self : in out Machine;
                            On : Middle_Machine.Event) is
   begin
      if Current_State (Self) = Middle then
         Middle_Machine.Base.Step (Self.Middle_Child, On);
      end if;
   end Step_Middle;

   function Middle_State (Self : Machine) return Middle_Machine.State is
   begin
      return Middle_Machine.Base.Current_State (Self.Middle_Child);
   end Middle_State;

   procedure Step_Middle_Inner (Self : in out Machine;
                            On : Inner_Machine.Event) is
   begin
      if Current_State (Self) = Middle then
         Middle_Machine.Step_Inner (Self.Middle_Child, On);
      end if;
   end Step_Middle_Inner;

   function Middle_Inner_State (Self : Machine) return Inner_Machine.State is
   begin
      if Current_State (Self) = Middle then
         return Middle_Machine.Inner_State (Self.Middle_Child);
      end if;
      raise Program_Error with "not in Middle region";
   end Middle_Inner_State;


end Outer_Machine;
