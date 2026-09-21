with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;        use Ada.Strings.Fixed;
with Ada.Directories;
with Ada.Text_IO;              use Ada.Text_IO;

with PlantUML;
with UML.Model;
with PlantUML2Code_Ada_Classes;

package body Test_Generator_Class is

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

      PlantUML2Code_Ada_Classes.Generate
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

   procedure Test_Concrete_Class_Derives_From_Object
     (T : in out Test_Case'Class)
   is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "class Dog" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "Dog.ads");
   begin
      Assert (Has (Ads, "with Class_Runtime;"),
              "spec withs Class_Runtime");
      Assert (Has (Ads, "type T is new Class_Runtime.Object"),
              "type derives from Class_Runtime.Object");
      Assert (Has (Ads, "function Class_Name"),
              "spec declares Class_Name");
   end Test_Concrete_Class_Derives_From_Object;

   procedure Test_Class_Name_Body_Emitted
     (T : in out Test_Case'Class)
   is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "class Dog" & ASCII.LF
        & "@enduml";
      Adb : constant String := Generate_And_Read (Src, "Dog.adb");
   begin
      Assert (Has (Adb, "function Class_Name"),
              "body defines Class_Name");
      Assert (Has (Adb, "return ""Dog"";"),
              "returns the class name");
   end Test_Class_Name_Body_Emitted;

   procedure Test_Interface_Is_Limited
     (T : in out Test_Case'Class)
   is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "interface Speaker" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "Speaker.ads");
   begin
      Assert (Has (Ads, "limited interface"),
              "interface is limited");
      Assert (Has (Ads, "and Class_Runtime.Object"),
              "interface derives from Object");
   end Test_Interface_Is_Limited;

   procedure Test_Enumeration_Body_Emitted
     (T : in out Test_Case'Class)
   is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "enum Color {" & ASCII.LF
        & "  Red" & ASCII.LF
        & "  Green" & ASCII.LF
        & "}" & ASCII.LF
        & "@enduml";
      Adb : constant String := Generate_And_Read (Src, "Color.adb");
   begin
      Assert (Has (Adb, "function Class_Name"),
              "enum has Class_Name body");
      Assert (Has (Adb, "return ""Color"";"),
              "returns the enum name");
   end Test_Enumeration_Body_Emitted;

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
      Ads : constant String := Generate_And_Read (Src, "Dog.ads");
   begin
      Assert (Has (Ads, "with Animal;"),
              "subclass withs its parent");
      Assert (Has (Ads, "type T is new Animal.T"),
              "subclass derives from parent");
   end Test_Subclass_Derives_From_Parent;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Concrete_Class_Derives_From_Object'Access,
         "concrete class derives from Object");
      Register_Routine
        (T, Test_Class_Name_Body_Emitted'Access,
         "Class_Name body emitted");
      Register_Routine
        (T, Test_Interface_Is_Limited'Access,
         "interface is limited");
      Register_Routine
        (T, Test_Enumeration_Body_Emitted'Access,
         "enumeration body emitted");
      Register_Routine
        (T, Test_Subclass_Derives_From_Parent'Access,
         "subclass derives from parent");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Generator.Class");
   end Name;

end Test_Generator_Class;
