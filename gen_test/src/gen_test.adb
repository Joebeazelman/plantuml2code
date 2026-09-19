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

   procedure Show (Label : String) is
   begin
      Put_Line (Label & " child = "
                & Nested.Running_State (M)'Image);
   end Show;
begin
   Utilities.Tracing.Set_Tracer (Print_Trace'Unrestricted_Access);

   Put_Line ("At construction: " & Current_State (M)'Image);
   --  No explicit Start. The first Step auto-initializes.

   Step (M, Nested.Start);
   Show ("after Start:");

   Nested.Step_Running (M, Running_Machine.Yield);
   Show ("after Yield:");

   Step (M, Nested.Stop);
   Show ("after Stop:");

   Step (M, Nested.Continue);
   Show ("after Continue:");
end Gen_Test;
