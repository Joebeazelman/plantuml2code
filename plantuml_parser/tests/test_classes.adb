with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

with PlantUML;
with PlantUML.Classes;

use type PlantUML.Diagram_Kind;   use PlantUML.Classes;

package body Test_Classes is

   procedure Test_Detect_Class (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (PlantUML.Detect_Kind
                ("@startuml" & ASCII.LF & "class A" & ASCII.LF & "@enduml")
              = PlantUML.Class_Diagram, "class detected");
   end Test_Detect_Class;

   procedure Test_Detect_Enum (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (PlantUML.Detect_Kind
                ("@startuml" & ASCII.LF
                 & "enum Color {" & ASCII.LF
                 & "  Red" & ASCII.LF
                 & "}" & ASCII.LF
                 & "@enduml")
              = PlantUML.Class_Diagram,
              "enum-only source detects as class diagram");
   end Test_Detect_Enum;

   procedure Test_Simple_Class (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant Class_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "class A" & ASCII.LF
               & "@enduml");
      K : constant Classifier := D.Pool (1);
   begin
      Assert (To_String (K.Id) = "A", "name A");
      Assert (K.Kind = Class, "kind Class");
   end Test_Simple_Class;

   procedure Test_Member_Parsing (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant Class_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "class A {" & ASCII.LF
               & "  +name : String" & ASCII.LF
               & "}" & ASCII.LF
               & "@enduml");
      M : constant Member := D.Pool (1).Members (1);
   begin
      Assert (To_String (M.Id) = "name", "member name");
      Assert (M.Vis = Public_Vis, "public visibility");
      Assert (To_String (M.Type_Name) = "String", "type");
   end Test_Member_Parsing;

   procedure Test_Inheritance (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant Class_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "class A" & ASCII.LF
               & "class B" & ASCII.LF
               & "A <|-- B" & ASCII.LF
               & "@enduml");
      R : constant Relation := D.Relations (1);
   begin
      Assert (To_String (R.From) = "A", "from A");
      Assert (To_String (R.To) = "B", "to B");
      Assert (R.Kind = Inheritance, "inheritance");
   end Test_Inheritance;

   procedure Test_Interface_Kind (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant Class_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "interface I" & ASCII.LF
               & "@enduml");
   begin
      Assert (D.Pool (1).Kind = Interface_Kind, "interface");
   end Test_Interface_Kind;

   procedure Test_Enumeration (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant Class_Diagram :=
        Parse ("@startuml" & ASCII.LF
               & "enum Color {" & ASCII.LF
               & "  Red" & ASCII.LF
               & "  Green" & ASCII.LF
               & "}" & ASCII.LF
               & "@enduml");
      K : constant Classifier := D.Pool (1);
   begin
      Assert (K.Kind = Enumeration, "enumeration kind");
      Assert (Natural (K.Members.Length) = 2,
              "two literals, got" & K.Members.Length'Image);
      Assert (K.Members (1).Kind = Enum_Literal, "literal kind");
   end Test_Enumeration;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Detect_Class'Access, "detect class");
      Register_Routine (T, Test_Detect_Enum'Access, "detect enum");
      Register_Routine (T, Test_Simple_Class'Access, "simple class");
      Register_Routine (T, Test_Member_Parsing'Access, "member");
      Register_Routine (T, Test_Inheritance'Access, "inheritance");
      Register_Routine (T, Test_Interface_Kind'Access, "interface");
      Register_Routine (T, Test_Enumeration'Access, "enumeration");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Classes");
   end Name;

end Test_Classes;
