generic
   type State is (<>);
   type Event is (<>);
   Initial : State;
package HSM.Machines is
   pragma Preelaborate;
   pragma Unevaluated_Use_Of_Old (Allow);

   type Machine is abstract new HSM.Root with private;

   function Current_State (Self : Machine'Class) return State
     with Inline => True;

   function Next_State (Self : Machine; On : Event) return State
     is abstract;

   procedure On_Enter (Self : in out Machine) is null;
   procedure On_Exit  (Self : in out Machine) is null;
   procedure On_Tick  (Self : in out Machine) is null;

   function On_Internal (Self : in out Machine; On : Event) return Boolean
     is (False);

   procedure Mark_Terminated (Self : in out Machine'Class)
     with Post => Is_Terminated (Self);

   function Is_Terminated (Self : Machine'Class) return Boolean
     with Inline => True;

   procedure Start (Self : in out Machine'Class);

   procedure Step (Self : in out Machine'Class; On : Event)
     with Pre  => not Is_Terminated (Self),
          Post => (if Current_State (Self) = Current_State (Self)'Old
                   then Is_Terminated (Self) = Is_Terminated (Self)'Old);

   procedure Reset (Self : in out Machine'Class)
     with Post => Current_State (Self) = Initial
                  and then not Is_Terminated (Self);

private

   type Machine is abstract new HSM.Root with record
      Current    : State := Initial;
      Terminated : Boolean := False;
   end record;

   function Get (Self : Machine) return State
     with Inline => True;

   procedure Set (Self : in out Machine; S : State)
     with Inline => True;

end HSM.Machines;
