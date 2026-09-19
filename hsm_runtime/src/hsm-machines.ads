generic
   type State is (<>);
   type Event is (<>);
   Initial : State;
package HSM.Machines is
   pragma Preelaborate;
   pragma Unevaluated_Use_Of_Old (Allow);

   type History_Mode is (History_None, History_Shallow, History_Deep);

   type Machine is abstract new HSM.Root with private;

   function Current_State (Self : Machine'Class) return State
     with Inline => True;

   function Next_State (Self : Machine; On : Event) return State
     is abstract;

   function Is_History_Entry
     (Self : Machine; From : State; On : Event) return History_Mode
     is (History_None);

   function Via_History (Self : Machine'Class) return History_Mode
     with Inline => True;

   procedure On_Enter (Self : in out Machine) is null;
   procedure On_Exit  (Self : in out Machine) is null;
   procedure On_Tick  (Self : in out Machine) is null;

   function On_Internal (Self : in out Machine; On : Event) return Boolean
     is (False);

   procedure Mark_Terminated (Self : in out Machine'Class)
     with Post => Is_Terminated (Self);

   function Is_Terminated (Self : Machine'Class) return Boolean
     with Inline => True;

   procedure Start (Self : in out Machine'Class)
     with Pre => not Is_Terminated (Self);

   procedure Step (Self : in out Machine'Class; On : Event)
     with Pre  => not Is_Terminated (Self),
          Post => (if Current_State (Self) = Current_State (Self)'Old
                   then Is_Terminated (Self) = Is_Terminated (Self)'Old);

   procedure Reset (Self : in out Machine'Class)
     with Post => Current_State (Self) = Initial
                  and then not Is_Terminated (Self);

   procedure Reset_To_Current (Self : in out Machine'Class);
   --  Re-fire On_Enter without changing state. Used by shallow history
   --  to make a child reset its own descendants.

private

   type Machine is abstract new HSM.Root with record
      Current     : State := Initial;
      Terminated  : Boolean := False;
      History     : History_Mode := History_None;
      Initialized : Boolean := False;
   end record;

   function Get (Self : Machine) return State
     with Inline => True;

   procedure Set (Self : in out Machine; S : State)
     with Inline => True;

end HSM.Machines;
