with Utilities.Tracing;

package body HSM.Machines is

   function Get (Self : Machine) return State is (Self.Current);

   procedure Set (Self : in out Machine; S : State) is
   begin
      Self.Current := S;
   end Set;

   function Current_State (Self : Machine'Class) return State is
     (Get (Machine (Self)));

   function Is_Terminated (Self : Machine'Class) return Boolean is
     (Machine (Self).Terminated);

   function Via_History (Self : Machine'Class) return Boolean is
     (Machine (Self).History);

   procedure Mark_Terminated (Self : in out Machine'Class) is
   begin
      Machine (Self).Terminated := True;
   end Mark_Terminated;

   procedure Start (Self : in out Machine'Class) is
   begin
      if Machine (Self).Initialized then
         return;
      end if;
      Machine (Self).Initialized := True;
      On_Enter (Self);
   end Start;

   procedure Reset (Self : in out Machine'Class) is
   begin
      On_Exit (Self);
      Set (Machine (Self), Initial);
      Machine (Self).Terminated := False;
      Machine (Self).Initialized := True;
      On_Enter (Self);
   end Reset;

   procedure Step (Self : in out Machine'Class; On : Event) is
      Previous : constant State := Current_State (Self);
   begin
      if not Machine (Self).Initialized then
         Start (Self);
      end if;

      On_Tick (Self);

      if On_Internal (Machine (Self), On) then
         return;
      end if;

      declare
         Next : constant State := Next_State (Self, On);
      begin
         if Next /= Previous then
            if Utilities.Tracing.Tracing then
               Utilities.Tracing.Trace
                 (Name (Self) & ": " & Previous'Image
                  & " --" & On'Image & "--> " & Next'Image);
            end if;

            On_Exit (Self);
            Machine (Self).History :=
              Is_History_Entry (Self, Previous, On);
            Set (Machine (Self), Next);
            On_Enter (Self);
            Machine (Self).History := False;
         end if;
      end;
   end Step;

end HSM.Machines;
