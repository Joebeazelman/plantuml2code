--  state_machine-tracing.ads -- emitted once. Edit freely.

package State_Machine.Tracing is
   pragma Preelaborate;

   type Tracer is access procedure (Msg : String);

   procedure Null_Tracer (Msg : String);

   function Tracing return Boolean
     with Inline => True;

   procedure Trace (Msg : String)
     with Inline => True;

   procedure Set_Tracer (T : Tracer);

private
   Active_Tracer : Tracer := Null_Tracer'Access;
end State_Machine.Tracing;
