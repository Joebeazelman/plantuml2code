with Ada.Text_IO;              use Ada.Text_IO;
with Utilities.Tracing;
with Nested;
with Running_Machine;

procedure Gen_Test is
   use Nested.Base;

   procedure Print_Trace (Msg : String) is
   begin
      Put_Line (Msg);
   end Print_Trace;

   M : Nested.Machine;
begin
   Utilities.Tracing.Set_Tracer (Print_Trace'Unrestricted_Access);

   Start (M);
   Put_Line ("Initial state:" & Current_State (M)'Image);

   Step (M, Nested.Start);
   Nested.Step_Running (M, Running_Machine.Yield);
   Nested.Step_Running (M, Running_Machine.Resume);
   Nested.Step_Running (M, Running_Machine.Suspend);
   Step (M, Nested.Stop);
   Step (M, Nested.Finish);

   Put_Line ("Final state:" & Current_State (M)'Image);
end Gen_Test;
