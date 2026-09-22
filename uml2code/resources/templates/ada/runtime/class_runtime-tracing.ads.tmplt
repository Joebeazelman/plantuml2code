--  class_runtime-tracing.ads -- emitted once. Edit freely.

package Class_Runtime.Tracing is
   pragma Preelaborate;

   type Tracer is access procedure (Msg : String);

   procedure Null_Tracer (Msg : String);

   function Tracing return Boolean with Inline => True;
   procedure Trace (Msg : String) with Inline => True;
   procedure Set_Tracer (T : Tracer);

private
   Active_Tracer : Tracer := Null_Tracer'Access;
end Class_Runtime.Tracing;
