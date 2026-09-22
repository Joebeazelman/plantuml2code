with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;        use Ada.Strings.Fixed;
with Ada.Directories;
with Ada.Text_IO;              use Ada.Text_IO;

with PlantUML;
with UML.Model;
with Uml2Code_Ada;

package body Test_Generator_States is

   function Generate_And_Read
     (Diagram : String;
      File_Name : String) return String
   is
      Dir  : constant String := "/tmp/gen_test_states";
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

      Uml2Code_Ada.Generate
        (D              => D,
         Package_Name   => "Test",
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

   --  ---------------------------------------------------------------
   --  Simple machine
   --  ---------------------------------------------------------------

   procedure Test_Simple_State_Enum (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "state Idle" & ASCII.LF
        & "state Busy" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "Test.ads");
   begin
      Assert (Has (Ads, "type State is"), "state enum present");
      Assert (Has (Ads, "Idle"), "Idle in enum");
      Assert (Has (Ads, "Busy"), "Busy in enum");
   end Test_Simple_State_Enum;

   procedure Test_Initial_State (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "[*] --> Idle" & ASCII.LF
        & "state Idle" & ASCII.LF
        & "state Busy" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "Test.ads");
   begin
      Assert (Has (Ads, "Initial => Idle"),
              "initial state is Idle");
   end Test_Initial_State;

   procedure Test_Transition_Table (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "state A" & ASCII.LF
        & "state B" & ASCII.LF
        & "A --> B : Go" & ASCII.LF
        & "@enduml";
      Adb : constant String := Generate_And_Read (Src, "Test.adb");
   begin
      Assert (Has (Adb, "Table : constant"), "table declared");
      Assert (Has (Adb, "Go => B"), "transition Go -> B");
      Assert (Has (Adb, "others =>"), "others fallback present");
   end Test_Transition_Table;

   procedure Test_Entry_Action (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "state Idle" & ASCII.LF
        & "Idle : entry / Log_It" & ASCII.LF
        & "@enduml";
      Adb : constant String := Generate_And_Read (Src, "Test.adb");
   begin
      Assert (Has (Adb, "when Idle =>"), "idle arm present");
      Assert (Has (Adb, "Log_It;"), "entry action call");
   end Test_Entry_Action;

   procedure Test_Exit_Action (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "state Idle" & ASCII.LF
        & "Idle : exit / Cleanup" & ASCII.LF
        & "@enduml";
      Adb : constant String := Generate_And_Read (Src, "Test.adb");
   begin
      Assert (Has (Adb, "Cleanup;"), "exit action call");
   end Test_Exit_Action;

   procedure Test_Internal_Transition (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "state Idle" & ASCII.LF
        & "Idle : Tick / Bump" & ASCII.LF
        & "@enduml";
      Adb : constant String := Generate_And_Read (Src, "Test.adb");
   begin
      Assert (Has (Adb, "if On = Tick then"), "internal check");
      Assert (Has (Adb, "Bump;"), "internal action");
   end Test_Internal_Transition;

   --  ---------------------------------------------------------------
   --  Composite machine
   --  ---------------------------------------------------------------

   procedure Test_Composite_Child_Field (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "state Outer {" & ASCII.LF
        & "  state A" & ASCII.LF
        & "}" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "Test.ads");
   begin
      Assert (Has (Ads, "with Outer_Machine;"),
              "child package withed");
      Assert (Has (Ads, "Outer_Child : Outer_Machine.Machine"),
              "child field declared");
      Assert (Has (Ads, "function Outer_State"),
              "child accessor declared");
   end Test_Composite_Child_Field;

   procedure Test_Composite_Reset_On_Entry (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "state Outer {" & ASCII.LF
        & "  state A" & ASCII.LF
        & "}" & ASCII.LF
        & "@enduml";
      Adb : constant String := Generate_And_Read (Src, "Test.adb");
   begin
      Assert (Has (Adb, "case Via_History"), "history case");
      Assert (Has (Adb, "Outer_Machine.Base.Reset"),
              "reset on fresh entry");
      Assert (Has (Adb, "Reset_To_Current"),
              "reset-to-current on shallow");
   end Test_Composite_Reset_On_Entry;

   procedure Test_Child_Stepper (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "state Outer {" & ASCII.LF
        & "  state A" & ASCII.LF
        & "}" & ASCII.LF
        & "@enduml";
      Ads : constant String := Generate_And_Read (Src, "Test.ads");
   begin
      Assert (Has (Ads, "procedure Step_Outer"),
              "child stepper declared");
   end Test_Child_Stepper;

   --  ---------------------------------------------------------------
   --  Terminal state
   --  ---------------------------------------------------------------

   procedure Test_End_State_Terminates (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Src : constant String :=
        "@startuml" & ASCII.LF
        & "[*] --> A" & ASCII.LF
        & "state A" & ASCII.LF
        & "A --> [*] : Done" & ASCII.LF
        & "@enduml";
      Adb : constant String := Generate_And_Read (Src, "Test.adb");
   begin
      Assert (Has (Adb, "Mark_Terminated"), "terminal marking");
   end Test_End_State_Terminates;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Simple_State_Enum'Access,
                        "state enum");
      Register_Routine (T, Test_Initial_State'Access,
                        "initial state");
      Register_Routine (T, Test_Transition_Table'Access,
                        "transition table");
      Register_Routine (T, Test_Entry_Action'Access,
                        "entry action");
      Register_Routine (T, Test_Exit_Action'Access,
                        "exit action");
      Register_Routine (T, Test_Internal_Transition'Access,
                        "internal transition");
      Register_Routine (T, Test_Composite_Child_Field'Access,
                        "composite child field");
      Register_Routine (T, Test_Composite_Reset_On_Entry'Access,
                        "composite reset on entry");
      Register_Routine (T, Test_Child_Stepper'Access,
                        "child stepper");
      Register_Routine (T, Test_End_State_Terminates'Access,
                        "end state terminates");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Generator.States");
   end Name;

end Test_Generator_States;
