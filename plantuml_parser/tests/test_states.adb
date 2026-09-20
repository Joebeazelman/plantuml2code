with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Ada.Strings.Unbounded;
with Ada.Strings.Fixed;  use Ada.Strings.Unbounded;

with PlantUML;
with PlantUML.States;

use type PlantUML.Diagram_Kind;    use PlantUML.States;

package body Test_States is

   function Find (D : State_Diagram; Name : String) return State is
   begin
      for S of D.Pool loop
         if To_String (S.Id) = Name then
            return S;
         end if;
      end loop;
      raise Constraint_Error with "state not found: " & Name;
   end Find;

   procedure Test_Detect_Unknown (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (PlantUML.Detect_Kind ("") = PlantUML.Unknown,
              "empty is Unknown");
   end Test_Detect_Unknown;

   procedure Test_Detect_State (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (PlantUML.Detect_Kind
                ("@startuml" & ASCII.LF & "state A" & ASCII.LF & "@enduml")
              = PlantUML.State_Diagram,
              "state diagram detected");
   end Test_Detect_State;

   procedure Test_Empty_Diagram (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant State_Diagram :=
        Parse ("@startuml" & ASCII.LF & "@enduml");
   begin
      Assert (D.Pool.Is_Empty, "no states");
      Assert (D.Transitions.Is_Empty, "no transitions");
   end Test_Empty_Diagram;

   procedure Test_Two_States (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant State_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "state Idle" & ASCII.LF
               & "state Busy" & ASCII.LF
               & "@enduml");
   begin
      Assert (Natural (D.Pool.Length) = 2,
              "two states, got" & D.Pool.Length'Image);
   end Test_Two_States;

   procedure Test_Transition_Trigger (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant State_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "state A" & ASCII.LF
               & "state B" & ASCII.LF
               & "A --> B : Go" & ASCII.LF
               & "@enduml");
      Tr : constant Transition := D.Transitions (1);
   begin
      Assert (To_String (Tr.From) = "A", "from A");
      Assert (To_String (Tr.To) = "B", "to B");
      Assert (To_String (Tr.Trigger) = "Go", "trigger Go");
   end Test_Transition_Trigger;

   procedure Test_Guard (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant State_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "state A" & ASCII.LF
               & "state B" & ASCII.LF
               & "A --> B : Go [X > 0]" & ASCII.LF
               & "@enduml");
      Tr : constant Transition := D.Transitions (1);
   begin
      Assert (To_String (Tr.Trigger) = "Go", "trigger Go");
      Assert (Ada.Strings.Fixed.Index (To_String (Tr.Guard), "X > 0") > 0,
              "guard captured, got '" & To_String (Tr.Guard) & "'");
   end Test_Guard;

   procedure Test_Composite_Children (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant State_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "state Outer {" & ASCII.LF
               & "  state A" & ASCII.LF
               & "  state B" & ASCII.LF
               & "}" & ASCII.LF
               & "@enduml");
      Outer : constant State := Find (D, "Outer");
   begin
      Assert (Outer.Kind = Composite, "Outer is Composite");
      Assert (Natural (Outer.Children.Length) = 2,
              "two children, got" & Outer.Children.Length'Image);
   end Test_Composite_Children;

   procedure Test_Entry_Annotation (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant State_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "state Idle" & ASCII.LF
               & "Idle : entry / Log_It" & ASCII.LF
               & "@enduml");
      S : constant State := Find (D, "Idle");
      Found : Boolean := False;
   begin
      for A of S.Annotations loop
         if A.Kind = Entry_Action
           and then To_String (A.Action) = "Log_It"
         then
            Found := True;
         end if;
      end loop;
      Assert (Found, "entry annotation captured");
   end Test_Entry_Annotation;

   procedure Test_Region_Scoped_History (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant State_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "state Outer {" & ASCII.LF
               & "  [*] --> A" & ASCII.LF
               & "  state A" & ASCII.LF
               & "  A --> [H]" & ASCII.LF
               & "}" & ASCII.LF
               & "@enduml");
      Found : Boolean := False;
   begin
      for S of D.Pool loop
         if To_String (S.Id) = "Outer.[H]" then
            Assert (S.Kind = History_Shallow,
                    "Outer.[H] is History_Shallow");
            Found := True;
         end if;
      end loop;
      Assert (Found, "region-scoped history state present");
   end Test_Region_Scoped_History;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Detect_Unknown'Access, "detect unknown");
      Register_Routine (T, Test_Detect_State'Access, "detect state");
      Register_Routine (T, Test_Empty_Diagram'Access, "empty diagram");
      Register_Routine (T, Test_Two_States'Access, "two states");
      Register_Routine (T, Test_Transition_Trigger'Access, "trigger");
      Register_Routine (T, Test_Guard'Access, "guard");
      Register_Routine (T, Test_Composite_Children'Access, "composite");
      Register_Routine (T, Test_Entry_Annotation'Access, "entry");
      Register_Routine (T, Test_Region_Scoped_History'Access, "history");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("States");
   end Name;

end Test_States;
