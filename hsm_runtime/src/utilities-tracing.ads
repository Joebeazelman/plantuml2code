--  Trace sink for the state machine runtime.
--
--  The runtime calls Trace on every state transition. The default
--  tracer is a no-op; the sample driver installs one that writes to
--  standard output.

package Utilities.Tracing is
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

end Utilities.Tracing;
