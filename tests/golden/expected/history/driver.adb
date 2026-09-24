--  driver.adb -- starter driver for HistoryTest.
--
--  Starts the machine and prints its initial state. Edit to send
--  real events, e.g.:
--
--     Step (M, HistoryTest.<Event>);
--     Put_Line (Current_State (M)'Image);

with Ada.Text_IO; use Ada.Text_IO;
with State_Machine.Tracing;
with HistoryTest;

procedure Driver is
   use HistoryTest.Base;

   procedure Print_Trace (Msg : String) is
   begin
      Put_Line (Msg);
   end Print_Trace;

   M : HistoryTest.Machine;
begin
   State_Machine.Tracing.Set_Tracer (Print_Trace'Unrestricted_Access);
   Start (M);
   Put_Line ("Initial state: " & Current_State (M)'Image);
end Driver;
