generic
   type State is (<>);
   type Event is (<>);
   Initial : State;
package HSM.Machines is
   pragma Preelaborate;

   type Machine is abstract new HSM.Root with private;

   function Current_State (Self : Machine'Class) return State
     with Inline => True;

   function Next_State (Self : Machine; On : Event) return State
     is abstract;

   procedure On_Enter (Self : in out Machine) is null;
   procedure On_Exit  (Self : in out Machine) is null;
   procedure On_Tick  (Self : in out Machine) is null;
   --  Called at the start of every Step. Generated machines override
   --  this to dispatch "do" activities for the current state.

   function On_Internal (Self : in out Machine; On : Event) return Boolean
     is (False);
   --  Return True if the event was handled as an internal transition
   --  (no state change). Step calls this before computing Next_State.

   procedure Start (Self : in out Machine'Class);
   --  Fire On_Enter for the current state. Intended for the
   --  top-level machine immediately after construction. Composite
   --  children are Started implicitly by their parent's On_Enter.

   procedure Step (Self : in out Machine'Class; On : Event);

   procedure Reset (Self : in out Machine'Class);
   --  Fire On_Exit for the current state, set to Initial, fire
   --  On_Enter for Initial. Intended for composite children when
   --  their parent enters the composite state.

private

   type Machine is abstract new HSM.Root with record
      Current : State := Initial;
   end record;

   function Get (Self : Machine) return State
     with Inline => True;

   procedure Set (Self : in out Machine; S : State)
     with Inline => True;

end HSM.Machines;
