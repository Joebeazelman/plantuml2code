--  driver.adb -- starter driver for Nested.
--
--  Starts the machine and prints its initial state. Edit to send
--  real events, e.g.:
--
--     Step (M, Nested.<Event>);
--     Put_Line (Current_State (M)'Image);

with Ada.Text_IO; use Ada.Text_IO;
with State_Machine.Tracing;
with Nested;

procedure Driver is
   use Nested.Base;

   procedure Print_Trace (Msg : String) is
   begin
      Put_Line (Msg);
   end Print_Trace;

   M : Nested.Machine;
begin
   State_Machine.Tracing.Set_Tracer (Print_Trace'Unrestricted_Access);
   Start (M);
   Put_Line ("Initial state: " & Current_State (M)'Image);
end Driver;
