--  ---------------------------------------------------------------------
--  HistoryTest (body)
--
--  Generated from ../samples/history.puml on <DATE>.
--  ---------------------------------------------------------------------

package body HistoryTest is

   use Base;


   Table : constant array (State, Event) of State :=
     [
      Start_State =>
        [Enter_Fresh => Start_State,
         Enter_Shallow => Start_State,
         Enter_Deep => Start_State,
         Back => Start_State,
         others => Start_State]
,
      Idle =>
        [Enter_Fresh => Outer,
         Enter_Shallow => Outer,
         Enter_Deep => Outer,
         Back => Idle,
         others => Idle]
,
      Outer =>
        [Enter_Fresh => Outer,
         Enter_Shallow => Outer,
         Enter_Deep => Outer,
         Back => Idle,
         others => Outer]
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
         when Idle =>
            null;
         when Outer =>
            case Via_History (Self) is
               when History_None =>
                  Outer_Machine.Base.Reset
                    (Self.Outer_Child);
               when History_Shallow =>
                  Outer_Machine.Base.Reset_To_Current
                    (Self.Outer_Child);
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
         when Idle =>
            null;
         when Outer =>
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
         when Idle =>
            if On = Enter_Shallow then
               return History_Shallow;
            end if;
            if On = Enter_Deep then
               return History_Deep;
            end if;
            return History_None;
         when others =>
            return History_None;

      end case;
   end Is_History_Entry;

   overriding
   function Name (Self : Machine) return String is
     ("HistoryTest");

   procedure Step_Outer (Self : in out Machine;
                            On : Outer_Machine.Event) is
   begin
      if Current_State (Self) = Outer then
         Outer_Machine.Base.Step (Self.Outer_Child, On);
      end if;
   end Step_Outer;

   function Outer_State (Self : Machine) return Outer_Machine.State is
   begin
      return Outer_Machine.Base.Current_State (Self.Outer_Child);
   end Outer_State;

   procedure Step_Outer_Middle (Self : in out Machine;
                            On : Middle_Machine.Event) is
   begin
      if Current_State (Self) = Outer then
         Outer_Machine.Step_Middle (Self.Outer_Child, On);
      end if;
   end Step_Outer_Middle;

   function Outer_Middle_State (Self : Machine) return Middle_Machine.State is
   begin
      if Current_State (Self) = Outer then
         return Outer_Machine.Middle_State (Self.Outer_Child);
      end if;
      raise Program_Error with "not in Outer region";
   end Outer_Middle_State;

   procedure Step_Outer_Middle_Inner (Self : in out Machine;
                            On : Inner_Machine.Event) is
   begin
      if Current_State (Self) = Outer then
         Outer_Machine.Step_Middle_Inner (Self.Outer_Child, On);
      end if;
   end Step_Outer_Middle_Inner;

   function Outer_Middle_Inner_State (Self : Machine) return Inner_Machine.State is
   begin
      if Current_State (Self) = Outer then
         return Outer_Machine.Middle_Inner_State (Self.Outer_Child);
      end if;
      raise Program_Error with "not in Outer region";
   end Outer_Middle_Inner_State;


end HistoryTest;
