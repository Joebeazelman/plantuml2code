with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;        use Ada.Strings.Fixed;
with Ada.Directories;
with Ada.Text_IO;              use Ada.Text_IO;

with PlantUML;
with UML.Model;
with Uml2Code_Ada_Classes;

package body Test_Generator_Class is

   --  The generator emits one Ada package per PlantUML package. An
   --  unnamed @startuml yields a root package called Model, so the
   --  generated spec is model.ads.
   function Generate_And_Read
     (Diagram : String;
      File_Name : String) return String
   is
      Dir  : constant String := "/tmp/gen_test_class";
      D    : constant UML.Model.Diagram := PlantUML.Parse (Diagram);
      Path : constant String :=
        Ada.Directories.Compose
          (Ada.Directories.Compose (Dir, "src"), File_Name);
      F    : File_Type;
      Result : Unbounded_String;
   begin
      if Ada.Directories.Exists (Dir) then
         Ada.Directories.Delete_Tree (Dir);
      end if;
      Ada.Directories.Create_Path (Ada.Directories.Compose (Dir, "src"));
      Ada.Directories.Create_Path (Ada.Directories.Compose (Dir, "tests"));

      Uml2Code_Ada_Classes.Generate
        (D              => D,
         Source_Diagram => "test.puml",
         Out_Dir        => Dir);

      Open (F, In_File, Path);
      while not End_Of_File (F) loop
         Result := Result & Get_Line (F) & ASCII.LF;
      end loop;
      Close (F);
      return To_String (Result);
   end Generate_And_Read;

   function Has (Text, Sub : String) return Boolean is
     (Index (Text, Sub) > 0);

   procedure Test_Concrete_Class (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "class Dog" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "model.ads");
   begin
      Assert (Has (Ads, "type Dog is tagged null record;"),
              "concrete class declared as tagged null record");
      Assert (Has (Ads, "package Model is"),
              "root package named Model");
   end Test_Concrete_Class;

   procedure Test_Interface_Is_Limited (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "interface Speaker" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "model.ads");
   begin
      Assert (Has (Ads, "type Speaker is limited interface;"),
              "interface declared as limited interface");
   end Test_Interface_Is_Limited;

   procedure Test_Enumeration (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "enum Color {" & ASCII.LF
        & "  Red" & ASCII.LF
        & "  Green" & ASCII.LF
        & "}" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "model.ads");
   begin
      Assert (Has (Ads, "type Color is (Red, Green);"),
              "enum declared with literals");
   end Test_Enumeration;

   procedure Test_Subclass_Derives_From_Parent
     (T : in out Test_Case'Class)
   is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "class Animal" & ASCII.LF
        & "class Dog" & ASCII.LF
        & "Animal <|-- Dog" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "model.ads");
   begin
      Assert (Has (Ads, "type Dog is new Animal with null record;"),
              "subclass derives from parent");
   end Test_Subclass_Derives_From_Parent;

   procedure Test_Package_Membership (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "package Animals {" & ASCII.LF
        & "  class Dog" & ASCII.LF
        & "}" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "animals.ads");
   begin
      Assert (Has (Ads, "package Animals is"),
              "PlantUML package becomes Ada package");
      Assert (Has (Ads, "type Dog is tagged null record;"),
              "class inside package");
   end Test_Package_Membership;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Concrete_Class'Access,
                        "concrete class");
      Register_Routine (T, Test_Interface_Is_Limited'Access,
                        "interface is limited");
      Register_Routine (T, Test_Enumeration'Access,
                        "enumeration");
      Register_Routine (T, Test_Subclass_Derives_From_Parent'Access,
                        "subclass derives from parent");
      Register_Routine (T, Test_Package_Membership'Access,
                        "package membership");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Generator.Class");
   end Name;

end Test_Generator_Class;
