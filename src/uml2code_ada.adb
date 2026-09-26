with Uml2Code_Identifiers;
with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Directories;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Characters.Handling;

with UML.Model;                use UML.Model;
with UML.Model.Queries;        use UML.Model.Queries;
with Uml2Code_Utils;
with Uml2Code_Filters;
with Uml2Code_Ada_Comments;
with Uml2Code_Template_Path;
with Uml2Code_Generator_Support;
use  Uml2Code_Generator_Support;
with Jintp;                    use Jintp;
with GNAT.OS_Lib;

package body Uml2Code_Ada is

   --  Global JinTP environment for custom filters
   Global_Env : Jintp.Environment;

   Top_Level : constant Natural := 0;

   function Id_Of
     (D : UML.Model.Diagram; Idx : Element_Index) return String
   is
   begin
      if Idx = 0 or else Positive (Idx) > Natural (D.Elements.Length) then
         return "";
      end if;
      return To_String (D.Elements (Positive (Idx)).Id);
   end Id_Of;

   function Collect_Events
     (D      : UML.Model.Diagram;
      Ts     : UML.Model.Relation_Vectors.Vector;
      States : UML.Model.Element_Index_Vectors.Vector)
      return String_Sets.Set
   is
      Seen : String_Sets.Set;
   begin
      for T of Ts loop
         if Length (T.Trigger) > 0 then
            Seen.Include (To_String (T.Trigger));
         end if;
      end loop;
      for I of States loop
         if I /= 0 and then Positive (I) <= Natural (D.Elements.Length) then
            for A of D.Elements (Positive (I)).Annotations loop
               if A.Kind = Internal_Transition
                 and then Length (A.Trigger) > 0
               then
                  Seen.Include (To_String (A.Trigger));
               end if;
            end loop;
         end if;
      end loop;
      if Seen.Is_Empty then
         Seen.Include ("Tick");
      end if;
      return Seen;
   end Collect_Events;

   function Initial_State_Of
     (D      : UML.Model.Diagram;
      Region : Natural;
      States : UML.Model.Element_Index_Vectors.Vector) return String
   is
      Start_Name : constant String :=
        (if Region = Top_Level then "[*]_start"
         elsif Region > 0 and then Positive (Region) <= Natural (D.Elements.Length)
         then To_String (D.Elements (Positive (Region)).Id) & ".[*]_start"
         else "[*]_start");
   begin
      for T of D.Relations loop
         if T.Kind = Transition and then Id_Of (D, T.From) = Start_Name then
            declare
               Target : constant String := Id_Of (D, T.To);
            begin
               if Target /= "" then
                  return Target;
               end if;
            end;
         end if;
      end loop;
      for I of States loop
         if I /= 0 and then Positive (I) <= Natural (D.Elements.Length) then
            declare
               Raw : constant String :=
                 To_String (D.Elements (Positive (I)).Id);
            begin
               if Raw not in "[*]_start" | "[*]_end" | "[H]" | "[H*]" then
                  return Raw;
               end if;
            end;
         end if;
      end loop;
      --  Fallback: return first non-pseudostate or empty
      return "Idle";
   end Initial_State_Of;

   procedure Emit_Runtime (Out_Dir : String) is
      D : Dictionary;
   begin
      Render_If_Missing_Dict
        ("ada/runtime", "state_machine.ads.tmplt",
         Ada.Directories.Compose (Out_Dir, "state_machine.ads"),
         D, Global_Env);
      Render_If_Missing_Dict
        ("ada/runtime", "state_machine.adb.tmplt",
         Ada.Directories.Compose (Out_Dir, "state_machine.adb"),
         D, Global_Env);
   end Emit_Runtime;

   procedure Emit_Test_Driver (Out_Dir, Machine_Name : String) is
      Output : constant String :=
        Ada.Directories.Compose (Out_Dir, "driver.adb");
      D : Dictionary;
   begin
      if Ada.Directories.Exists (Output) then
         Put_Line ("kept  " & Output);
         return;
      end if;
      Insert (D, "MACHINE_NAME", Machine_Name);
      declare
         Content : constant String :=
           Render_Dict ("ada/project", "driver.adb.tmplt", D, Global_Env);
         F : Ada.Text_IO.File_Type;
      begin
         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Output);
         Ada.Text_IO.Put (F, Content);
         Ada.Text_IO.Close (F);
      end;
      Put_Line ("wrote " & Output);
   end Emit_Test_Driver;

   procedure Emit_Setup (Out_Dir, Machine_Name : String) is
      Output : constant String :=
        Ada.Directories.Compose (Out_Dir, "setup.sh");
      D : Dictionary;
      F : Ada.Text_IO.File_Type;
   begin
      if Ada.Directories.Exists (Output) then
         Put_Line ("kept  " & Output);
         return;
      end if;
      Insert (D, "MACHINE_NAME", Machine_Name);
      Insert (D, "PROJECT_NAME",
        Ada.Characters.Handling.To_Lower (Machine_Name));
      Insert (D, "GENERATION_DATE", Uml2Code_Utils.Today);
      declare
         Content : constant String :=
           Render_Dict ("ada/project", "setup.sh.tmplt", D, Global_Env);
      begin
         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Output);
         Ada.Text_IO.Put (F, Content);
         Ada.Text_IO.Close (F);
      end;
      declare
         use GNAT.OS_Lib;
      begin
         Set_Executable (Output);
      end;
      Put_Line ("wrote " & Output & "  (run: bash " & Output & ")");
   end Emit_Setup;

   procedure Generate_Region
     (D              : UML.Model.Diagram;
      Cache          : UML.Model.Queries.Region_Cache;
      Region         : Natural;
      Package_Name   : String;
      Source_Diagram : String;
      Date_Str       : String;
      Out_Dir        : String)
   is
      States : constant UML.Model.Element_Index_Vectors.Vector :=
        States_In (D, Region);
      Ts : constant UML.Model.Relation_Vectors.Vector :=
        Transitions_In (Cache, D, Region);
      Child_States : constant UML.Model.Element_Index_Vectors.Vector :=
        Composite_Children_Of (D, States);

      Dict : Dictionary;
      State_List : List;
      Trans_List : List;
      Composite_States : List;

      Events     : constant String_Sets.Set :=
        Collect_Events (D, Ts, States);
      Event_List : List;
      Initial    : constant String :=
        Initial_State_Of (D, Region, States);

      Ads_File : constant String :=
        Ada.Directories.Compose (Out_Dir, Package_Name & ".ads");
      Adb_File : constant String :=
        Ada.Directories.Compose (Out_Dir, Package_Name & ".adb");
   begin
      --  Build state list for JinTP {% for %} iteration.
      --  Skip pseudostates ([*]_start, [*]_end, [H], [H*]) - they are
      --  internal implementation details, not user-visible states.
      for I of States loop
         if I /= 0 and then Positive (I) <= Natural (D.Elements.Length) then
            declare
               Elem   : UML.Model.Element renames
                 D.Elements (Positive (I));
               Raw_Id : constant String := To_String (Elem.Id);
            begin
               --  Skip pseudostates
               if Raw_Id not in "[*]_start" | "[*]_end" | "[H]" | "[H*]" then
                  declare
                     State_Dict : Dictionary;
                  begin
                     Insert (State_Dict, "id", Raw_Id);
                     Insert (State_Dict, "kind", Elem.Kind'Image);
                     
                     --  Detect terminal states (states that transition to [*])
                     declare
                        Transitions_To_End : Boolean := False;
                     begin
                        for R of Ts loop
                           if Id_Of (D, R.From) = Raw_Id then
                              declare
                                 Target : constant String := Id_Of (D, R.To);
                              begin
                                 --  Check if this transition goes to the end pseudostate
                                 if Target = "[*]_end" or else Target = "[*]" then
                                    Transitions_To_End := True;
                                    exit;
                                 end if;
                              end;
                           end if;
                        end loop;
                        Insert (State_Dict, "is_terminal", Transitions_To_End);
                     end;

                     --  Collect actions and internal transitions
                     declare
                        Entry_List : List;
                        Exit_List  : List;
                        Do_List    : List;
                        Annotations_List : List;
                     begin
                        for A of Elem.Annotations loop
                           if A.Kind = Entry_Action
                             and then Length (A.Text) > 0
                           then
                              Append (Entry_List, To_String (A.Text));
                           elsif A.Kind = Exit_Action
                             and then Length (A.Text) > 0
                           then
                              Append (Exit_List, To_String (A.Text));
                           elsif A.Kind = Do_Activity
                             and then Length (A.Text) > 0
                           then
                              Append (Do_List, To_String (A.Text));
                           elsif A.Kind = Internal_Transition then
                              declare
                                 Ann_Dict : Dictionary;
                              begin
                                 Insert (Ann_Dict, "kind", "Internal_Transition");
                                 Insert (Ann_Dict, "trigger", To_String (A.Trigger));
                                 Insert (Ann_Dict, "action", To_String (A.Text));
                                 Append (Annotations_List, Ann_Dict);
                              end;
                           end if;
                        end loop;
                        Insert (State_Dict, "entry_actions", Entry_List);
                        Insert (State_Dict, "exit_actions", Exit_List);
                        Insert (State_Dict, "do_actions", Do_List);
                        Insert (State_Dict, "annotations", Annotations_List);
                     end;

                     --  Collect transitions FROM this state
                     declare
                        State_Trans : List;
                     begin
                        for R of Ts loop
                           if Id_Of (D, R.From) = Raw_Id
                             and then Length (R.Trigger) > 0
                           then
                              declare
                                 Trans_Dict : Dictionary;
                                 Target_Id  : constant String :=
                                   Id_Of (D, R.To);
                              begin
                                 --  Skip transitions to pseudostates or
                                 --  non-existent states
                                 if Target_Id not in "[*]_end"
                                   and then Target_Id /= ""
                                 then
                                    Insert (Trans_Dict, "trigger",
                                      To_String (R.Trigger));
                                    Insert (Trans_Dict, "target",
                                      Target_Id);
                                    Append (State_Trans, Trans_Dict);
                                 end if;
                              end;
                           end if;
                        end loop;
                        Insert (State_Dict, "transitions", State_Trans);
                     end;

                     --  Build transition table for this state
                     --  One entry per event, with No_State for missing transitions
                     declare
                        Trans_Table : List;
                     begin
                        for E of Events loop
                           declare
                              Trans_Entry : Dictionary;
                              Target : constant String := "No_State";
                              Found : Boolean := False;
                           begin
                              --  Find transition for this state and event
                              for R of Ts loop
                                 if Id_Of (D, R.From) = Raw_Id
                                   and then To_String (R.Trigger) = E
                                   and then Id_Of (D, R.To) /= ""
                                   and then Id_Of (D, R.To) not in "[*]_end"
                                 then
                                    Insert (Trans_Entry, "event", E);
                                    Insert (Trans_Entry, "target", Id_Of (D, R.To));
                                    Found := True;
                                    exit;
                                 end if;
                              end loop;
                              
                              if not Found then
                                 Insert (Trans_Entry, "event", E);
                                 Insert (Trans_Entry, "target", "No_State");
                              end if;
                              
                              Append (Trans_Table, Trans_Entry);
                           end;
                        end loop;
                        
                        Insert (State_Dict, "trans_table", Trans_Table);
                     end;

                     --  Detect composite states (states with children)
                     if not Elem.Children.Is_Empty then
                        declare
                           Composite_Dict : Dictionary;
                           Child_Name : constant String := Raw_Id & "_Machine";
                        begin
                           Insert (Composite_Dict, "name", Raw_Id);
                           Insert (Composite_Dict, "child_package", Child_Name);
                           Insert (Composite_Dict, "child_field", Raw_Id & "_Child");
                           Append (Composite_States, Composite_Dict);
                           Insert (State_Dict, "is_composite", True);
                        end;
                     else
                        Insert (State_Dict, "is_composite", False);
                     end if;

                     Append (State_List, State_Dict);
                  end;
               end if;
            end;
         end if;
      end loop;

      --  Build transition list (for the .adb template)
      for R of Ts loop
         declare
            Trans_Dict : Dictionary;
         begin
            Insert (Trans_Dict, "from", Id_Of (D, R.From));
            Insert (Trans_Dict, "to", Id_Of (D, R.To));
            Insert (Trans_Dict, "trigger", To_String (R.Trigger));
            Append (Trans_List, Trans_Dict);
         end;
      end loop;


      --  Insert all data into main dictionary
      Insert (Dict, "PACKAGE_NAME", Package_Name);
      --  Pass raw title/notes to template; template adds comment delimiters
      declare
         Raw_Title : constant String :=
           (if Region = Top_Level
            then UML.Model.Queries.Title_Of (D) else "");
         Raw_Notes : constant String :=
           (if Region = Top_Level
            then UML.Model.Queries.Notes_Of (D) else "");
      begin
         Insert (Dict, "HAS_TITLE", Raw_Title'Length > 0);
         Insert (Dict, "TITLE", Raw_Title);
         Insert (Dict, "HAS_NOTES", Raw_Notes'Length > 0);

         Insert (Dict, "comment_lines",
                 Uml2Code_Ada_Comments.Comment_Lines
                   (Raw_Notes, Uml2Code_Template_Path.Comment_Wrap));
      end;
      Insert (Dict, "DESCRIPTION",
        "State machine generated from " & Source_Diagram);
      Insert (Dict, "SOURCE_DIAGRAM", Source_Diagram);
      Insert (Dict, "GENERATION_DATE", Date_Str);
      --  Build event list for JinTP iteration
      for E of Events loop
         declare
            Event_Dict : Dictionary;
         begin
            Insert (Event_Dict, "name", E);
            Append (Event_List, Event_Dict);
         end;
      end loop;
      Insert (Dict, "events", Event_List);
      Insert (Dict, "INITIAL_STATE", Initial);
      Insert (Dict, "states", State_List);
      Insert (Dict, "composite_states", Composite_States);
      Insert (Dict, "transitions", Trans_List);

      Render_To_Dict ("ada/state", "state.ads.tmplt",
        Ads_File, Dict, Global_Env);
      Render_To_Dict ("ada/state", "state.adb.tmplt",
        Adb_File, Dict, Global_Env);

      for C of Child_States loop
         Generate_Region
           (D              => D,
            Cache          => Cache,
            Region         => Natural (C),
            Package_Name   => Uml2Code_Identifiers.Ident (Id_Of (D, C)) & "_Machine",
            Source_Diagram => Source_Diagram,
            Date_Str       => Date_Str,
            Out_Dir        => Out_Dir);
      end loop;
   end Generate_Region;

   procedure Emit_Tests
     (D            : UML.Model.Diagram;
      Cache        : UML.Model.Queries.Region_Cache;
      Package_Name : String;
      Tests_Dir    : String)
   is
      pragma Unreferenced (D, Cache);
      Test_Dir : constant String :=
        Ada.Directories.Compose (Tests_Dir, "test");
      Empty_Dict : Dictionary;

      procedure Render
        (Subdir, Template, Output : String;
         Dict : Dictionary)
      is
         Content : constant String :=
           Render_Dict (Subdir, Template, Dict, Global_Env);
         F : Ada.Text_IO.File_Type;
      begin
         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Output);
         Ada.Text_IO.Put (F, Content);
         Ada.Text_IO.Close (F);
      end Render;
   begin
      Ada.Directories.Create_Path (Test_Dir);
      Render ("ada/project/tests", "test_main.adb.tmplt",
        Ada.Directories.Compose (Test_Dir, "test_main.adb"), Empty_Dict);
      Render ("ada/project/tests", "all_tests.ads.tmplt",
        Ada.Directories.Compose (Test_Dir, "all_tests.ads"), Empty_Dict);
      Put_Line ("wrote test suite skeleton for " & Package_Name);
   end Emit_Tests;

   procedure Generate
     (D              : UML.Model.Diagram;
      Package_Name   : String;
      Source_Diagram : String;
      Out_Dir        : String)
   is
      Date_Str : constant String := Uml2Code_Utils.Today;
      Cache    : constant UML.Model.Queries.Region_Cache :=
        UML.Model.Queries.Build_Cache (D);
   begin
      Uml2Code_Filters.Register_Filters (Global_Env);
      Refuse_Crate_Internal_Output (Out_Dir);
      declare
         Src_Dir   : constant String :=
           Ada.Directories.Compose (Out_Dir, "src");
         Tests_Dir : constant String :=
           Ada.Directories.Compose (Out_Dir, "tests");
      begin
         Ada.Directories.Create_Path (Src_Dir);
         Ada.Directories.Create_Path (Tests_Dir);
         Emit_Runtime (Src_Dir);
         Emit_Test_Driver (Src_Dir, Package_Name);
         Emit_Tests (D, Cache, Package_Name, Tests_Dir);
         Emit_Setup (Out_Dir, Package_Name);
         Generate_Region
           (D              => D,
            Cache          => Cache,
            Region         => Top_Level,
            Package_Name   => Package_Name,
            Source_Diagram => Source_Diagram,
            Date_Str       => Date_Str,
            Out_Dir        => Src_Dir);
      end;
   end Generate;

   procedure Emit_Runtime_And_Project
     (Src_Dir, Tests_Dir, Out_Dir : String;
      Machine_Name : String;
      Include_State_Runtime : Boolean := True)
   is
      pragma Unreferenced (Src_Dir, Tests_Dir, Out_Dir,
        Machine_Name, Include_State_Runtime);
   begin
      null;
   end Emit_Runtime_And_Project;

   procedure Emit_Setup_Only (Out_Dir, Machine_Name : String) is
      pragma Unreferenced (Out_Dir, Machine_Name);
   begin
      null;
   end Emit_Setup_Only;

end Uml2Code_Ada;
