--  class_runtime-tracing.adb -- emitted once. Edit freely.

package body Class_Runtime.Tracing is

   procedure Null_Tracer (Msg : String) is
      pragma Unreferenced (Msg);
   begin
      null;
   end Null_Tracer;

   function Tracing return Boolean is
   begin
      return Active_Tracer /= Null_Tracer'Access;
   end Tracing;

   procedure Trace (Msg : String) is
   begin
      Active_Tracer (Msg);
   end Trace;

   procedure Set_Tracer (T : Tracer) is
   begin
      Active_Tracer := T;
   end Set_Tracer;

end Class_Runtime.Tracing;
