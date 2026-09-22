with Ada.Text_IO;
with GNAT.OS_Lib;              use Ada.Text_IO;
with Ada.Directories;
with Ada.Calendar;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;  use Ada.Characters.Handling;

with UML.Model;               use UML.Model;
with UML.Model.Queries;       use UML.Model.Queries;
with Uml2Code_Utils;
with Uml2Code_Template_Path;      use Uml2Code_Utils;
with Templates_Parser;         use Templates_Parser;

package body Uml2Code_Ada is

   --  Local alias: Templates_Parser.Tag. UML.Model.Annotation_Kind
   --  has a literal named Tag; without this, `use UML.Model` hides
   --  the type. Nothing in this body references the literal.
   subtype Tag is Templates_Parser.Tag;

   package UV is new Ada.Containers.Vectors
     (Positive, Unbounded_String);


   Top_Level : constant Natural := 0;

   --  =========================================================
   --  Identifier sanitization
   --  =========================================================
   function Sanitize (S : String) return String is
      R : Unbounded_String;
      Last_Underscore : Boolean := False;
   begin
      for C of S loop
         if (C in 'a' .. 'z') or else (C in 'A' .. 'Z')
           or else (C in '0' .. '9')
         then
            Append (R, C);
            Last_Underscore := False;
         else
            if not Last_Underscore and then Length (R) > 0 then
               Append (R, '_');
               Last_Underscore := True;
            end if;
         end if;
      end loop;

      declare
         Tmp : Unbounded_String := R;
      begin
         while Length (Tmp) > 0
           and then Ada.Strings.Unbounded.Element (Tmp, Length (Tmp)) = '_'
         loop
            Delete (Tmp, Length (Tmp), Length (Tmp));
         end loop;

         if Length (Tmp) > 0
           and then Ada.Strings.Unbounded.Element (Tmp, 1) in '0' .. '9'
         then
            return "S_" & To_String (Tmp);
         end if;

         if Length (Tmp) = 0 then
            return "Unnamed";
         end if;

         return To_String (Tmp);
      end;
   end Sanitize;

   function Id_Of (D : UML.Model.Diagram; Idx : Element_Index)
                   return String is
     (To_String (D.Elements (Positive (Idx)).Id));

   function Title_Line_Of (D : UML.Model.Diagram) return String is
   begin
      for M of D.Metadata loop
         if M.Kind = UML.Model.Title and then Length (M.Text) > 0 then
            return "--  " & To_String (M.Text);
         end if;
      end loop;
      return "";
   end Title_Line_Of;

   --  Pack diagram-level notes into a comment block. Each line of each
   --  note is prefixed with "--    ". Empty string when no notes.
   function Notes_Header_Of (D : UML.Model.Diagram) return String is
      R : Unbounded_String;

      procedure Emit_Lines (Txt : String) is
         Start : Natural := Txt'First;
      begin
         if Txt'Length = 0 then
            return;
         end if;
         for I in Txt'Range loop
            if Txt (I) = ASCII.LF then
               Append (R, "--    " & Txt (Start .. I - 1) & ASCII.LF);
               Start := I + 1;
            end if;
         end loop;
         if Start <= Txt'Last then
            Append (R, "--    " & Txt (Start .. Txt'Last) & ASCII.LF);
         end if;
      end Emit_Lines;
   begin
      for N of D.Notes loop
         Emit_Lines (To_String (N.Text));
      end loop;

      --  Trim the trailing newline; the template supplies the final
      --  line break before the closing rule.
      declare
         S : constant String := To_String (R);
      begin
         if S'Length > 0 and then S (S'Last) = ASCII.LF then
            return S (S'First .. S'Last - 1);
         end if;
         return S;
      end;
   end Notes_Header_Of;

   function State_Literal (Name : String) return String is
      Dot : Natural := 0;
   begin
      for I in Name'Range loop
         if Name (I) = '.' then
            Dot := I;
         end if;
      end loop;

      declare
         Base : constant String :=
           (if Dot = 0 then Name else Name (Dot + 1 .. Name'Last));
      begin
         if Base = "[*]_start" then
            return "Start_State";
         elsif Base = "[*]_end" then
            return "End_State";
         elsif Base = "[H]" then
            return "History";
         elsif Base = "[H*]" then
            return "Deep_History";
         else
            return Sanitize (Base);
         end if;
      end;
   end State_Literal;

   function Event_Literal (Name : String) return String is
     (if Name'Length = 0 then "Tick" else Sanitize (Name));

   function Parent_Name (S : String) return String is
      Dot : Natural := 0;
   begin
      for I in S'Range loop
         if S (I) = '.' then
            Dot := I;
         end if;
      end loop;
      if Dot = 0 then
         return S;
      else
         return S (S'First .. Dot - 1);
      end if;
   end Parent_Name;

   function Is_History_Target (S : String) return Boolean is
     (Ada.Strings.Fixed.Index (S, ".[H]") > 0
      or else Ada.Strings.Fixed.Index (S, ".[H*]") > 0);

   function Effective_Target (To_Name : String) return String is
     (if Is_History_Target (To_Name)
      then State_Literal (Parent_Name (To_Name))
      else State_Literal (To_Name));

   procedure Add_Event
     (Seen    : in out UV.Vector;
      Trigger : String)
   is
      Lit : constant String := Event_Literal (Trigger);
   begin
      if Trigger'Length = 0 then
         return;
      end if;
      for S of Seen loop
         if To_String (S) = Lit then
            return;
         end if;
      end loop;
      Seen.Append (To_Unbounded_String (Lit));
   end Add_Event;

   function Collect_Events
     (D      : UML.Model.Diagram;
      Ts     : Relation_Vectors.Vector;
      States : Element_Index_Vectors.Vector) return String
   is
      Seen : UV.Vector;
      R    : Unbounded_String;
   begin
      for T of Ts loop
         Add_Event (Seen, To_String (T.Trigger));
      end loop;

      for I of States loop
         for A of D.Elements (Positive (I)).Annotations loop
            if A.Kind = UML.Model.Internal_Transition then
               Add_Event (Seen, To_String (A.Trigger));
            end if;
         end loop;
      end loop;

      if Seen.Is_Empty then
         return "Tick";
      end if;

      for S of Seen loop
         if Length (R) > 0 then
            Append (R, ", ");
         end if;
         Append (R, S);
      end loop;

      return To_String (R);
   end Collect_Events;

   function State_Literals_Of
     (D : UML.Model.Diagram; States : Element_Index_Vectors.Vector) return String
   is
      R : Unbounded_String;
      First : Boolean := True;
   begin
      for I of States loop
         if not First then
            Append (R, ", ");
         end if;
         Append (R, State_Literal (To_String (D.Elements (Positive (I)).Id)));
         First := False;
      end loop;
      return To_String (R);
   end State_Literals_Of;

   function Initial_State_Of
     (D : UML.Model.Diagram; Region : Natural; States : Element_Index_Vectors.Vector)
      return String
   is
      Start_Name : constant String :=
        (if Region = Top_Level then "[*]_start"
         else To_String (D.Elements (Positive (Region)).Id) & ".[*]_start");
   begin
      for T of D.Relations loop
         if T.Kind = UML.Model.Transition
           and then Id_Of (D, T.From) = Start_Name
         then
            return State_Literal (Id_Of (D, T.To));
         end if;
      end loop;
      --  No explicit start transition; take the first non-pseudostate
      --  in the region. If there is none, the region is empty and
      --  cannot be generated.
      for I of States loop
         declare
            Lit : constant String :=
              State_Literal (To_String (D.Elements (Positive (I)).Id));
         begin
            if Lit /= "Start_State" and Lit /= "End_State"
              and Lit /= "History" and Lit /= "Deep_History"
            then
               return Lit;
            end if;
         end;
      end loop;
      raise Constraint_Error with
        "region has no initial state and no non-pseudostate element";
   end Initial_State_Of;

   procedure Build_Transition_Row_Tags
     (D       : UML.Model.Diagram;
      Region  : Natural;
      States  : Element_Index_Vectors.Vector;
      Row_State   : in out Tag;
      Row_Events  : in out Tag;
      Row_NotLast : in out Tag)
   is
      Ts : constant Relation_Vectors.Vector :=
        Transitions_In (D, Region);
      Events : constant String := Collect_Events (D, Ts, States);
      Ev_List : Unbounded_String;

      procedure Split_Events is
         I : Natural := Events'First;
         St : Natural;
      begin
         while I <= Events'Last loop
            while I <= Events'Last and then Events (I) = ' ' loop
               I := I + 1;
            end loop;
            exit when I > Events'Last;
            St := I;
            while I <= Events'Last and then Events (I) /= ',' loop
               I := I + 1;
            end loop;
            declare
               Ev : constant String := Events (St .. I - 1);
               Trimmed : constant String :=
                 Ada.Strings.Fixed.Trim (Ev, Ada.Strings.Both);
            begin
               if Length (Ev_List) > 0 then
                  Append (Ev_List, ",");
               end if;
               Append (Ev_List, Trimmed);
            end;
            if I <= Events'Last then
               I := I + 1;
            end if;
         end loop;
      end Split_Events;

      function Target_For (From_Lit, Ev_Lit : String) return String is
      begin
         for T of Ts loop
            if State_Literal (Id_Of (D, T.From)) = From_Lit
              and then Event_Literal (To_String (T.Trigger)) = Ev_Lit
            then
               return Effective_Target (Id_Of (D, T.To));
            end if;
         end loop;
         return From_Lit;
      end Target_For;

      Row_Index  : Natural := 0;
      Total_Rows : constant Natural := Natural (States.Length);
   begin
      Split_Events;

      for I of States loop
         Row_Index := Row_Index + 1;
         declare
            From_Lit : constant String :=
              State_Literal (To_String (D.Elements (Positive (I)).Id));
            Events_Text : Unbounded_String := Null_Unbounded_String;
            First_Ev : Boolean := True;
         begin
            declare
               Evs : constant String := To_String (Ev_List);
               J   : Natural := Evs'First;
               St  : Natural;
            begin
               while J <= Evs'Last loop
                  St := J;
                  while J <= Evs'Last and then Evs (J) /= ',' loop
                     J := J + 1;
                  end loop;
                  declare
                     Ev_Lit : constant String := Evs (St .. J - 1);
                     Tgt : constant String :=
                       Target_For (From_Lit, Ev_Lit);
                  begin
                     if not First_Ev then
                        Append (Events_Text, "," & ASCII.LF & "         ");
                     end if;
                     First_Ev := False;
                     Append (Events_Text, Ev_Lit & " => " & Tgt);
                  end;
                  if J <= Evs'Last then
                     J := J + 1;
                  end if;
               end loop;
            end;

            Row_State   := Row_State & From_Lit;
            Row_Events  := Row_Events & To_String (Events_Text);
            Row_NotLast := Row_NotLast & (Row_Index < Total_Rows);
         end;
      end loop;
   end Build_Transition_Row_Tags;

   function History_Cases
     (D : UML.Model.Diagram; States : Element_Index_Vectors.Vector;
      Ts : Relation_Vectors.Vector) return String
   is
      R : Unbounded_String;
   begin
      for I of States loop
         declare
            From_Lit : constant String :=
              State_Literal (To_String (D.Elements (Positive (I)).Id));
            Arms : Unbounded_String;
            First_Ev : Boolean := True;
         begin
            for T of Ts loop
               if State_Literal (Id_Of (D, T.From)) = From_Lit
                 and then Is_History_Target (Id_Of (D, T.To))
               then
                  declare
                     Kind : constant String :=
                       (if Ada.Strings.Fixed.Index
                             (Id_Of (D, T.To), "[H*]") > 0
                        then "History_Deep"
                        else "History_Shallow");
                  begin
                     if not First_Ev then
                        Append (Arms, ASCII.LF);
                     end if;
                     First_Ev := False;
                     Append (Arms,
                             "            if On = "
                             & Event_Literal (To_String (T.Trigger))
                             & " then" & ASCII.LF
                             & "               return " & Kind & ";"
                             & ASCII.LF
                             & "            end if;");
                  end;
               end if;
            end loop;
            if Length (Arms) > 0 then
               Append (R, "         when " & From_Lit & " =>" & ASCII.LF);
               Append (R, Arms & ASCII.LF);
               Append (R, "            return History_None;" & ASCII.LF);
            end if;
         end;
      end loop;
      Append (R, "         when others =>" & ASCII.LF
              & "            return History_None;" & ASCII.LF);
      return To_String (R);
   end History_Cases;

   function Child_Package_Name
     (D : UML.Model.Diagram; Child : Element_Index) return String is
     (State_Literal (To_String (D.Elements (Positive (Child)).Id)) & "_Machine");

   function Child_Field_Name
     (D : UML.Model.Diagram; Child : Element_Index) return String is
     (State_Literal (To_String (D.Elements (Positive (Child)).Id)) & "_Child");

   function Action_Decls
     (D : UML.Model.Diagram; States : Element_Index_Vectors.Vector) return String
   is
      R : Unbounded_String;
   begin
      for S of States loop
         for A of D.Elements (Positive (S)).Annotations loop
            case A.Kind is
               when Entry_Action | Exit_Action | Do_Activity
                  | Internal_Transition =>
                  declare
                     Action_Name : constant String :=
                       Sanitize (To_String (A.Text));
                  begin
                     if Length (A.Text) > 0 then
                        Append (R, "   procedure " & Action_Name
                               & ";  --  "
                               & A.Kind'Image & ": "
                               & To_String (A.Text) & ASCII.LF);
                     end if;
                  end;
               when others => null;
            end case;
         end loop;
      end loop;
      return To_String (R);
   end Action_Decls;

   function Action_Bodies
     (D : UML.Model.Diagram; States : Element_Index_Vectors.Vector) return String
   is
      R : Unbounded_String;
   begin
      for S of States loop
         for A of D.Elements (Positive (S)).Annotations loop
            case A.Kind is
               when Entry_Action | Exit_Action | Do_Activity
                  | Internal_Transition =>
                  declare
                     Action_Name : constant String :=
                       Sanitize (To_String (A.Text));
                  begin
                     if Length (A.Text) > 0 then
                        Append (R, "   procedure " & Action_Name
                               & " is" & ASCII.LF
                               & "   begin" & ASCII.LF
                               & "      null;  --  TODO: "
                               & A.Kind'Image & ": "
                               & To_String (A.Text) & ASCII.LF
                               & "   end " & Action_Name & ";"
                               & ASCII.LF & ASCII.LF);
                     end if;
                  end;
               when others => null;
            end case;
         end loop;
      end loop;
      return To_String (R);
   end Action_Bodies;

   procedure Render_To
     (Template : String;
      Output   : String;
      T        : Translate_Set)
   is
      Content : constant String := Render_Template ("ada/state", Template, T);
      F       : File_Type;
   begin
      Create (F, Out_File, Output);
      Put (F, Content);
      Close (F);
      Put_Line ("wrote " & Output);
   end Render_To;

   procedure Render_If_Missing
     (Template : String;
      Output   : String;
      T        : Translate_Set)
   is
   begin
      if Ada.Directories.Exists (Output) then
         Put_Line ("kept  " & Output);
      else
         Render_To (Template, Output, T);
      end if;
   end Render_If_Missing;



   procedure Emit_Runtime (Src_Dir : String);
   procedure Emit_Test_Driver
     (Tests_Dir, Machine_Name : String);
   procedure Emit_Setup (Out_Dir, Machine_Name : String);

   procedure Emit_Runtime_And_Project
     (Src_Dir, Tests_Dir, Out_Dir : String;
      Machine_Name : String;
      Include_State_Runtime : Boolean := True)
   is
   begin
      if Include_State_Runtime then
         Emit_Runtime (Src_Dir);
      end if;
      Emit_Test_Driver (Tests_Dir, Machine_Name);
      Emit_Setup (Out_Dir, Machine_Name);
   end Emit_Runtime_And_Project;

   procedure Emit_Setup_Only (Out_Dir, Machine_Name : String) is
   begin
      Emit_Setup (Out_Dir, Machine_Name);
   end Emit_Setup_Only;

   procedure Emit_Runtime (Src_Dir : String) is
      Empty_Set : Translate_Set;

      procedure One (Tmpl, File_Name : String) is
         Output : constant String :=
           Ada.Directories.Compose (Src_Dir, File_Name);
         Path   : constant String :=
           Uml2Code_Template_Path.Locate ("ada/runtime", Tmpl);
         Content   : constant String :=
           Templates_Parser.Parse (Path, Empty_Set);
         F      : File_Type;
      begin
         if Ada.Directories.Exists (Output) then
            Put_Line ("kept  " & Output);
         else
            Create (F, Out_File, Output);
            Put (F, Content);
            Close (F);
            Put_Line ("wrote " & Output);
         end if;
      end One;
   begin
      One ("state_machine.ads.tmplt", "state_machine.ads");
      One ("state_machine-machines.ads.tmplt",
           "state_machine-machines.ads");
      One ("state_machine-machines.adb.tmplt",
           "state_machine-machines.adb");
      One ("state_machine-tracing.ads.tmplt",
           "state_machine-tracing.ads");
      One ("state_machine-tracing.adb.tmplt",
           "state_machine-tracing.adb");
   end Emit_Runtime;

   procedure Emit_Test_Driver
     (Tests_Dir, Machine_Name : String)
   is
      Output : constant String :=
        Ada.Directories.Compose (Tests_Dir, "driver.adb");
      Path   : constant String :=
        Uml2Code_Template_Path.Locate ("ada/project",
                                            "driver.adb.tmplt");
      T      : Translate_Set;
      F      : File_Type;
   begin
      if Ada.Directories.Exists (Output) then
         Put_Line ("kept  " & Output);
         return;
      end if;
      Insert (T, Assoc ("MACHINE_NAME", Machine_Name));
      declare
         Content : constant String := Templates_Parser.Parse (Path, T);
      begin
         Create (F, Out_File, Output);
         Put (F, Content);
         Close (F);
      end;
      Put_Line ("wrote " & Output);
   end Emit_Test_Driver;

   procedure Emit_Setup
     (Out_Dir, Machine_Name : String)
   is
      Output : constant String :=
        Ada.Directories.Compose (Out_Dir, "setup.sh");
      Path   : constant String :=
        Uml2Code_Template_Path.Locate ("ada/project",
                                            "setup.sh.tmplt");
      T      : Translate_Set;
      F      : File_Type;
   begin
      if Ada.Directories.Exists (Output) then
         Put_Line ("kept  " & Output);
         return;
      end if;
      Insert (T, Assoc ("MACHINE_NAME", Machine_Name));
      Insert (T, Assoc ("PROJECT_NAME", To_Lower (Machine_Name)));
      declare
         Content : constant String := Templates_Parser.Parse (Path, T);
      begin
         Create (F, Out_File, Output);
         Put (F, Content);
         Close (F);
      end;
      declare
         use GNAT.OS_Lib;
      begin
         Set_Executable (Output);
      end;
      Put_Line ("wrote " & Output & "  (run: bash " & Output & ")");
   end Emit_Setup;

   procedure Emit_Deeper_Steppers
     (D : UML.Model.Diagram;
      Region : Natural;
      Prefix : String;
      With_Clauses, Decls, Bodies : in out Unbounded_String)
   is
      States     : constant Element_Index_Vectors.Vector := States_In (D, Region);
      Composites : constant Element_Index_Vectors.Vector :=
        Composite_Children_Of (D, States);
   begin
      for C of Composites loop
         declare
            Child_Pkg   : constant String := Child_Package_Name (D, C);
            State_Lit   : constant String :=
              State_Literal (To_String (D.Elements (Positive (C)).Id));
            Proc_Name   : constant String := "Step_" & Prefix & State_Lit;

            --  The first segment of Prefix identifies the ancestor
            --  we delegate through. Split "Anc_rest" into "Anc" and
            --  "rest".
            Underscore : constant Natural :=
              Ada.Strings.Fixed.Index (Prefix, "_");
            Anc_Lit    : constant String :=
              (if Underscore = 0 then Prefix (Prefix'First .. Prefix'Last - 1)
               else Prefix (Prefix'First .. Underscore - 1));
            Anc_Pkg    : constant String := Anc_Lit & "_Machine";
            Anc_Field  : constant String := Anc_Lit & "_Child";
            Remain_Pre : constant String :=
              (if Underscore = 0 then ""
               elsif Underscore = Prefix'Last then ""
               else Prefix (Underscore + 1 .. Prefix'Last));
            Call_Proc  : constant String :=
              "Step_" & Remain_Pre & State_Lit;
         begin
            Append (With_Clauses,
                    "with " & Child_Pkg & ";" & ASCII.LF);

            Append (Decls,
                    "   procedure " & Proc_Name
                    & " (Self : in out Machine;" & ASCII.LF
                    & "                            On : "
                    & Child_Pkg & ".Event);" & ASCII.LF & ASCII.LF);

            Append (Decls,
                    "   function " & Prefix & State_Lit
                    & "_State (Self : Machine) return "
                    & Child_Pkg & ".State;" & ASCII.LF & ASCII.LF);

            Append (Bodies,
                    "   procedure " & Proc_Name
                    & " (Self : in out Machine;" & ASCII.LF
                    & "                            On : "
                    & Child_Pkg & ".Event) is" & ASCII.LF
                    & "   begin" & ASCII.LF
                    & "      if Current_State (Self) = " & Anc_Lit
                    & " then" & ASCII.LF
                    & "         " & Anc_Pkg & "." & Call_Proc
                    & " (Self." & Anc_Field & ", On);" & ASCII.LF
                    & "      end if;" & ASCII.LF
                    & "   end " & Proc_Name & ";" & ASCII.LF
                    & ASCII.LF);

            Append (Bodies,
                    "   function " & Prefix & State_Lit
                    & "_State (Self : Machine) return "
                    & Child_Pkg & ".State is" & ASCII.LF
                    & "   begin" & ASCII.LF
                    & "      if Current_State (Self) = " & Anc_Lit
                    & " then" & ASCII.LF
                    & "         return " & Anc_Pkg & "."
                    & Remain_Pre & State_Lit & "_State"
                    & " (Self." & Anc_Field & ");" & ASCII.LF
                    & "      end if;" & ASCII.LF
                    & "      raise Program_Error with"
                    & " ""not in " & Anc_Lit & " region"";" & ASCII.LF
                    & "   end " & Prefix & State_Lit & "_State;"
                    & ASCII.LF & ASCII.LF);

            Emit_Deeper_Steppers
              (D, Natural (C), Prefix & State_Lit & "_",
               With_Clauses, Decls, Bodies);
         end;
      end loop;
   end Emit_Deeper_Steppers;

   procedure Generate_Region
     (D              : UML.Model.Diagram;
      Region         : Natural;
      Package_Name   : String;
      Source_Diagram : String;
      Date_Str       : String;
      Out_Dir        : String)
   is
      States       : constant Element_Index_Vectors.Vector := States_In (D, Region);
      Ts           : constant Relation_Vectors.Vector :=
        Transitions_In (D, Region);
      Child_States : constant Element_Index_Vectors.Vector :=
        Composite_Children_Of (D, States);

      T : Translate_Set;

      State_Lits : constant String := State_Literals_Of (D, States);
      Events     : constant String := Collect_Events (D, Ts, States);
      Initial    : constant String := Initial_State_Of (D, Region, States);

      Action_Decls_Text  : constant String := Action_Decls (D, States);
      Action_Bodies_Text : constant String := Action_Bodies (D, States);

      With_Clauses  : Unbounded_String;
      Record_Fields : Unbounded_String;
      Step_Decls    : Unbounded_String;
      Step_Bodies   : Unbounded_String;
      On_Enter_Arms : Unbounded_String;

      Enter_State_Lit    : Tag;
      Enter_Is_Composite : Tag;
      Enter_Is_Leaf_With : Tag;
      Enter_Is_Leaf_No   : Tag;
      Enter_Is_End       : Tag;
      Enter_Child_Pkg    : Tag;
      Enter_Child_Field  : Tag;
      Enter_Action_Call  : Tag;
      Enter_Note         : Tag;

      Exit_State_Lit   : Tag;
      Exit_Has_Action  : Tag;
      Exit_No_Action   : Tag;
      Exit_Action_Call : Tag;

      Tick_State_Lit   : Tag;
      Tick_Has_Action  : Tag;
      Tick_Action_Call : Tag;

      Internal_State_Lit   : Tag;
      Internal_Has_Any     : Tag;
      Internal_Has_Event   : Tag;
      Internal_Event_Lit   : Tag;
      Internal_Action_Call : Tag;

      Table_Row_State    : Tag;
      Table_Row_Events   : Tag;
      Table_Row_NotLast  : Tag;
      On_Exit_Arms  : Unbounded_String;
      On_Internal_Arms : Unbounded_String;
      On_Tick_Arms  : Unbounded_String;

      Ads_File : constant String :=
        Ada.Directories.Compose (Out_Dir, Package_Name & ".ads");
      Adb_File : constant String :=
        Ada.Directories.Compose (Out_Dir, Package_Name & ".adb");
      Act_Ads : constant String :=
        Ada.Directories.Compose (Out_Dir,
                                 Package_Name & "-operations.ads");
      Act_Adb : constant String :=
        Ada.Directories.Compose (Out_Dir,
                                 Package_Name & "-operations.adb");
   begin
      for C of Child_States loop
         declare
            Child_Pkg   : constant String := Child_Package_Name (D, C);
            Child_Field : constant String := Child_Field_Name (D, C);
            State_Lit   : constant String :=
              State_Literal (To_String (D.Elements (Positive (C)).Id));
            Procedure_Name : constant String := "Step_" & State_Lit;
         begin
            Append (With_Clauses,
                    "with " & Child_Pkg & ";" & ASCII.LF);
            Append (Record_Fields,
                    "      " & Child_Field & " : "
                    & Child_Pkg & ".Machine;" & ASCII.LF);

            Append (Step_Decls,
                    "   procedure " & Procedure_Name
                    & " (Self : in out Machine;" & ASCII.LF
                    & "                            On : "
                    & Child_Pkg & ".Event);" & ASCII.LF & ASCII.LF);

            Append (Step_Decls,
                    "   function " & State_Lit
                    & "_State (Self : Machine) return "
                    & Child_Pkg & ".State;" & ASCII.LF & ASCII.LF);

            Append (Step_Bodies,
                    "   procedure " & Procedure_Name
                    & " (Self : in out Machine;" & ASCII.LF
                    & "                            On : "
                    & Child_Pkg & ".Event) is" & ASCII.LF
                    & "   begin" & ASCII.LF
                    & "      if Current_State (Self) = " & State_Lit
                    & " then" & ASCII.LF
                    & "         " & Child_Pkg & ".Base.Step"
                    & " (Self." & Child_Field & ", On);" & ASCII.LF
                    & "      end if;" & ASCII.LF
                    & "   end " & Procedure_Name & ";" & ASCII.LF
                    & ASCII.LF);

            Append (Step_Bodies,
                    "   function " & State_Lit
                    & "_State (Self : Machine) return "
                    & Child_Pkg & ".State is" & ASCII.LF
                    & "   begin" & ASCII.LF
                    & "      return " & Child_Pkg
                    & ".Base.Current_State (Self." & Child_Field & ");"
                    & ASCII.LF
                    & "   end " & State_Lit & "_State;" & ASCII.LF
                    & ASCII.LF);

            Append (On_Enter_Arms,
                    "         when " & State_Lit & " =>" & ASCII.LF
                    & "            case Via_History (Self) is" & ASCII.LF
                    & "               when History_None =>" & ASCII.LF
                    & "                  " & Child_Pkg & ".Base.Reset"
                    & " (Self." & Child_Field & ");" & ASCII.LF
                    & "               when History_Shallow =>" & ASCII.LF
                    & "                  " & Child_Pkg
                    & ".Base.Reset_To_Current"
                    & " (Self." & Child_Field & ");" & ASCII.LF
                    & "               when History_Deep =>" & ASCII.LF
                    & "                  null;" & ASCII.LF
                    & "            end case;" & ASCII.LF);

            --  Recursively emit Step_<Path>_<Descendant> for this
            --  region's grandchildren and deeper.
            Emit_Deeper_Steppers
              (D, Natural (C), Prefix => State_Lit & "_",
               With_Clauses => With_Clauses,
               Decls  => Step_Decls,
               Bodies => Step_Bodies);
         end;
      end loop;

      for I of States loop
         declare
            Lit          : constant String :=
              State_Literal (To_String (D.Elements (Positive (I)).Id));
            Is_Composite : Boolean := False;
            Has_Entry    : Boolean := False;
            Has_Exit     : Boolean := False;
         begin
            for C of Child_States loop
               if State_Literal (To_String (D.Elements (Positive (C)).Id)) = Lit then
                  Is_Composite := True;
                  exit;
               end if;
            end loop;
            for A of D.Elements (Positive (I)).Annotations loop
               if A.Kind = UML.Model.Entry_Action then Has_Entry := True; end if;
               if A.Kind = UML.Model.Exit_Action  then Has_Exit  := True; end if;
            end loop;

            if not Is_Composite then
               Append (On_Enter_Arms,
                       "         when " & Lit & " =>" & ASCII.LF);

               if Lit = "End_State" then
                  Append (On_Enter_Arms,
                          "            Mark_Terminated (Self);"
                          & ASCII.LF);
               else
                  for A of D.Elements (Positive (I)).Annotations loop
                     if A.Kind = UML.Model.Entry_Action
                       and then Length (A.Text) > 0
                     then
                        Append (On_Enter_Arms,
                                "            "
                                & Sanitize (To_String (A.Text))
                                & ";" & ASCII.LF);
                     end if;
                  end loop;
                  if not Has_Entry then
                     Append (On_Enter_Arms,
                             "            null;" & ASCII.LF);
                  end if;
               end if;
            end if;

            declare
               Child_Pkg_L : Unbounded_String := Null_Unbounded_String;
               Child_Fld_L : Unbounded_String := Null_Unbounded_String;
               Entry_Call  : Unbounded_String := Null_Unbounded_String;
            begin
               if Is_Composite then
                  for C of Child_States loop
                     if State_Literal
                          (To_String (D.Elements (Positive (C)).Id)) = Lit
                     then
                        Child_Pkg_L :=
                          To_Unbounded_String (Child_Package_Name (D, C));
                        Child_Fld_L :=
                          To_Unbounded_String (Child_Field_Name (D, C));
                        exit;
                     end if;
                  end loop;
               end if;
               for A of D.Elements (Positive (I)).Annotations loop
                  if A.Kind = UML.Model.Entry_Action
                    and then Length (A.Text) > 0
                  then
                     Entry_Call :=
                       To_Unbounded_String
                         (Sanitize (To_String (A.Text)));
                  end if;
               end loop;

               --  Notes rendered as comments above the case arm.
               declare
                  Note_Text : Unbounded_String := Null_Unbounded_String;
               begin
                  for N of D.Elements (Positive (I)).Notes loop
                     declare
                        Txt : constant String := To_String (N.Text);
                        Start : Natural := Txt'First;
                     begin
                        if Txt'Length > 0 then
                           for J in Txt'Range loop
                              if Txt (J) = ASCII.LF then
                                 Append (Note_Text,
                                         "         --  "
                                         & Txt (Start .. J - 1)
                                         & ASCII.LF);
                                 Start := J + 1;
                              end if;
                           end loop;
                           if Start <= Txt'Last then
                              Append (Note_Text,
                                      "         --  "
                                      & Txt (Start .. Txt'Last)
                                      & ASCII.LF);
                           end if;
                        end if;
                     end;
                  end loop;
                  Enter_Note := Enter_Note & To_String (Note_Text);
               end;

               Enter_State_Lit    := Enter_State_Lit & Lit;
               Enter_Is_Composite := Enter_Is_Composite & Is_Composite;
               Enter_Is_End       := Enter_Is_End & (Lit = "End_State");
               Enter_Is_Leaf_With :=
                 Enter_Is_Leaf_With
                 & (not Is_Composite and Lit /= "End_State" and Has_Entry);
               Enter_Is_Leaf_No   :=
                 Enter_Is_Leaf_No
                 & (not Is_Composite and Lit /= "End_State"
                    and not Has_Entry);
               Enter_Child_Pkg    := Enter_Child_Pkg
                                     & To_String (Child_Pkg_L);
               Enter_Child_Field  := Enter_Child_Field
                                     & To_String (Child_Fld_L);
               Enter_Action_Call  := Enter_Action_Call
                                     & To_String (Entry_Call);

               declare
                  Exit_Call : Unbounded_String := Null_Unbounded_String;
               begin
                  for A of D.Elements (Positive (I)).Annotations loop
                     if A.Kind = UML.Model.Exit_Action
                       and then Length (A.Text) > 0
                     then
                        Exit_Call :=
                          To_Unbounded_String
                            (Sanitize (To_String (A.Text)));
                     end if;
                  end loop;

                  Exit_State_Lit   := Exit_State_Lit & Lit;
                  Exit_Has_Action  := Exit_Has_Action
                                      & (Length (Exit_Call) > 0);
                  Exit_No_Action   := Exit_No_Action
                                      & (Length (Exit_Call) = 0);
                  Exit_Action_Call := Exit_Action_Call
                                      & To_String (Exit_Call);
               end;

               declare
                  Do_Call : Unbounded_String := Null_Unbounded_String;
               begin
                  for A of D.Elements (Positive (I)).Annotations loop
                     if A.Kind = UML.Model.Do_Activity
                       and then Length (A.Text) > 0
                     then
                        Do_Call :=
                          To_Unbounded_String
                            (Sanitize (To_String (A.Text)));
                     end if;
                  end loop;

                  Tick_State_Lit   := Tick_State_Lit & Lit;
                  Tick_Has_Action  := Tick_Has_Action
                                       & (Length (Do_Call) > 0);
                  Tick_Action_Call := Tick_Action_Call
                                       & To_String (Do_Call);
               end;

               declare
                  Has_Int   : Boolean := False;
                  Int_Event : Unbounded_String := Null_Unbounded_String;
                  Int_Act   : Unbounded_String := Null_Unbounded_String;
               begin
                  for A of D.Elements (Positive (I)).Annotations loop
                     if A.Kind = UML.Model.Internal_Transition
                       and then Length (A.Trigger) > 0
                       and then Length (A.Text) > 0
                     then
                        Has_Int := True;
                        Int_Event :=
                          To_Unbounded_String
                            (Sanitize (To_String (A.Trigger)));
                        Int_Act :=
                          To_Unbounded_String
                            (Sanitize (To_String (A.Text)));
                        exit;
                     end if;
                  end loop;

                  Internal_State_Lit   := Internal_State_Lit & Lit;
                  Internal_Has_Any     := Internal_Has_Any & Has_Int;
                  Internal_Has_Event   := Internal_Has_Event & Has_Int;
                  Internal_Event_Lit   := Internal_Event_Lit
                                          & To_String (Int_Event);
                  Internal_Action_Call := Internal_Action_Call
                                          & To_String (Int_Act);
               end;
            end;

            Append (On_Exit_Arms,
                    "         when " & Lit & " =>" & ASCII.LF);
            for A of D.Elements (Positive (I)).Annotations loop
               if A.Kind = UML.Model.Exit_Action and then Length (A.Text) > 0 then
                  Append (On_Exit_Arms,
                          "            "
                          & Sanitize (To_String (A.Text))
                          & ";" & ASCII.LF);
               end if;
            end loop;
            if not Has_Exit then
               Append (On_Exit_Arms,
                       "            null;" & ASCII.LF);
            end if;

            declare
               Has_Internal : Boolean := False;
               Body_Text    : Unbounded_String;
            begin
               for A of D.Elements (Positive (I)).Annotations loop
                  if A.Kind = UML.Model.Internal_Transition
                    and then Length (A.Trigger) > 0
                    and then Length (A.Text) > 0
                  then
                     Has_Internal := True;
                     Append (Body_Text,
                             "            if On = "
                             & Sanitize (To_String (A.Trigger))
                             & " then" & ASCII.LF
                             & "               "
                             & Sanitize (To_String (A.Text))
                             & ";" & ASCII.LF
                             & "               return True;" & ASCII.LF
                             & "            end if;" & ASCII.LF);
                  end if;
               end loop;

               if Has_Internal then
                  Append (On_Internal_Arms,
                          "         when " & Lit & " =>" & ASCII.LF);
                  Append (On_Internal_Arms, Body_Text);
                  Append (On_Internal_Arms,
                          "            return False;" & ASCII.LF);
               end if;
            end;

            declare
               Has_Do : Boolean := False;
               Do_Body : Unbounded_String;
            begin
               for A of D.Elements (Positive (I)).Annotations loop
                  if A.Kind = UML.Model.Do_Activity and then Length (A.Text) > 0 then
                     Has_Do := True;
                     Append (Do_Body,
                             "            "
                             & Sanitize (To_String (A.Text))
                             & ";" & ASCII.LF);
                  end if;
               end loop;
               if Has_Do then
                  Append (On_Tick_Arms,
                          "         when " & Lit & " =>" & ASCII.LF);
                  Append (On_Tick_Arms, Do_Body);
               end if;
            end;
         end;
      end loop;

      declare
         Private_Record : Unbounded_String;
      begin
         if Child_States.Is_Empty then
            Append (Private_Record,
                    "   type Machine is new Base.Machine with null record;");
         else
            Append (Private_Record,
                    "   type Machine is new Base.Machine with record"
                    & ASCII.LF);
            Append (Private_Record, Record_Fields);
            Append (Private_Record, "   end record;");
         end if;
         Insert (T, Assoc ("PRIVATE_RECORD", To_String (Private_Record)));
      end;

      Insert (T, Assoc ("PACKAGE_NAME", Package_Name));
      Insert (T, Assoc ("HAS_TITLE",
                        Region = Top_Level
                        and then Title_Line_Of (D)'Length > 0));
      Insert (T, Assoc ("TITLE_LINE",
                        (if Region = Top_Level
                         then Title_Line_Of (D) else "")));
      Insert (T, Assoc ("HAS_NOTES",
                        Region = Top_Level
                        and then Notes_Header_Of (D)'Length > 0));
      Insert (T, Assoc ("NOTES_HEADER",
                        (if Region = Top_Level
                         then Notes_Header_Of (D) else "")));
      Insert (T, Assoc ("DESCRIPTION",
                        "State machine generated from " & Source_Diagram));
      Insert (T, Assoc ("SOURCE_DIAGRAM", Source_Diagram));
      Insert (T, Assoc ("GENERATION_DATE", Date_Str));
      Insert (T, Assoc ("CHILD_WITH_CLAUSES", To_String (With_Clauses)));
      Insert (T, Assoc ("STATE_LITERALS", State_Lits));
      Insert (T, Assoc ("EVENT_LITERALS", Events));
      Insert (T, Assoc ("INITIAL_STATE", Initial));
      Insert (T, Assoc ("STEP_CHILD_DECLS", To_String (Step_Decls)));
      Build_Transition_Row_Tags
        (D, Region, States,
         Table_Row_State, Table_Row_Events, Table_Row_NotLast);
      Insert (T, Assoc ("TABLE_ROW_STATE",   Table_Row_State));
      Insert (T, Assoc ("TABLE_ROW_EVENTS",  Table_Row_Events));
      Insert (T, Assoc ("TABLE_ROW_NOTLAST", Table_Row_NotLast));
      Insert (T, Assoc ("ENTER_STATE_LIT",     Enter_State_Lit));
      Insert (T, Assoc ("ENTER_NOTE",          Enter_Note));
      Insert (T, Assoc ("ENTER_IS_COMPOSITE",  Enter_Is_Composite));
      Insert (T, Assoc ("ENTER_IS_END",        Enter_Is_End));
      Insert (T, Assoc ("ENTER_IS_LEAF_WITH_ACTION", Enter_Is_Leaf_With));
      Insert (T, Assoc ("ENTER_IS_LEAF_NO_ACTION",   Enter_Is_Leaf_No));
      Insert (T, Assoc ("ENTER_CHILD_PKG",     Enter_Child_Pkg));
      Insert (T, Assoc ("ENTER_CHILD_FIELD",   Enter_Child_Field));
      Insert (T, Assoc ("ENTER_ACTION_CALL",   Enter_Action_Call));
      Insert (T, Assoc ("EXIT_STATE_LIT",   Exit_State_Lit));
      Insert (T, Assoc ("EXIT_HAS_ACTION",  Exit_Has_Action));
      Insert (T, Assoc ("EXIT_NO_ACTION",   Exit_No_Action));
      Insert (T, Assoc ("EXIT_ACTION_CALL", Exit_Action_Call));
      Insert (T, Assoc ("INTERNAL_STATE_LIT",   Internal_State_Lit));
      Insert (T, Assoc ("INTERNAL_HAS_ANY",     Internal_Has_Any));
      Insert (T, Assoc ("INTERNAL_HAS_EVENT",   Internal_Has_Event));
      Insert (T, Assoc ("INTERNAL_EVENT_LIT",   Internal_Event_Lit));
      Insert (T, Assoc ("INTERNAL_ACTION_CALL", Internal_Action_Call));
      Insert (T, Assoc ("TICK_STATE_LIT",   Tick_State_Lit));
      Insert (T, Assoc ("TICK_HAS_ACTION",  Tick_Has_Action));
      Insert (T, Assoc ("TICK_ACTION_CALL", Tick_Action_Call));
      Insert (T, Assoc ("HISTORY_CASES",
                        History_Cases (D, States, Ts)));
      Insert (T, Assoc ("STEP_CHILD_BODIES", To_String (Step_Bodies)));
      Insert (T, Assoc ("ACTION_DECLS", Action_Decls_Text));
      Insert (T, Assoc ("ACTION_BODIES", Action_Bodies_Text));

      declare
         Has_Actions : constant Boolean :=
           Action_Decls_Text'Length > 0;
         With_Txt : Unbounded_String := Null_Unbounded_String;
         Use_Txt  : Unbounded_String := Null_Unbounded_String;
      begin
         if Has_Actions then
            With_Txt := To_Unbounded_String
              ("with " & Package_Name & ".Operations;"
               & ASCII.LF & ASCII.LF);
            Use_Txt := To_Unbounded_String
              ("   use " & Package_Name & ".Operations;" & ASCII.LF);
         end if;
         Insert (T, Assoc ("ACTIONS_WITH", With_Txt));
         Insert (T, Assoc ("ACTIONS_USE", Use_Txt));
      end;

      Render_To ("state.ads.tmplt", Ads_File, T);
      Render_To ("state.adb.tmplt", Adb_File, T);

      if Action_Decls_Text'Length > 0 then
         Render_If_Missing ("operations.ads.tmplt", Act_Ads, T);
         Render_If_Missing ("operations.adb.tmplt", Act_Adb, T);
      end if;

      for C of Child_States loop
         Generate_Region
           (D              => D,
            Region         => Natural (C),
            Package_Name   => Child_Package_Name (D, C),
            Source_Diagram => Source_Diagram,
            Date_Str       => Date_Str,
            Out_Dir        => Out_Dir);
      end loop;
   end Generate_Region;

   --  =========================================================
   --  Generated AUnit test suite
   --  =========================================================
   --  =========================================================
   --  Generated AUnit test suite
   --  =========================================================
   --
   --  One test case package per region, plus a suite that composes
   --  them. A region's tests reference only that region's Transition
   --  function and its Event literals.

   procedure Emit_Tests_For_Region
     (D              : UML.Model.Diagram;
      Region         : Natural;
      Package_Name   : String;
      Test_Pkg       : String;
      Test_Dir       : String)
   is
      Ts : constant Relation_Vectors.Vector :=
        Transitions_In (D, Region);

      Test_Procs : Tag;
      Froms      : Tag;
      Events     : Tag;
      Targets    : Tag;

      Seen_Pairs : array (1 .. 256) of Unbounded_String;
      N_Seen     : Natural := 0;

      function Pair_Seen (From_Lit, Ev_Lit : String) return Boolean is
      begin
         for I in 1 .. N_Seen loop
            if To_String (Seen_Pairs (I)) = From_Lit & "/" & Ev_Lit then
               return True;
            end if;
         end loop;
         return False;
      end Pair_Seen;

      procedure Remember (From_Lit, Ev_Lit : String) is
      begin
         N_Seen := N_Seen + 1;
         Seen_Pairs (N_Seen) :=
           To_Unbounded_String (From_Lit & "/" & Ev_Lit);
      end Remember;

      procedure Render (Template, Output : String;
                        T : Translate_Set) is
         Path : constant String :=
           Uml2Code_Template_Path.Locate ("ada/state/tests",
                                               Template);
         Content : constant String := Templates_Parser.Parse (Path, T);
         F : File_Type;
      begin
         Create (F, Out_File, Output);
         Put (F, Content);
         Close (F);
      end Render;

      T_Case : Translate_Set;
   begin
      for R of Ts loop
         --  Completion transitions (no trigger) are not exercisable
         --  through the Transition lookup, which is keyed by event.
         --  Skip them; they're covered by the runtime's completion
         --  path, not by the test suite.
         if Length (R.Trigger) = 0 then
            goto Continue;
         end if;

         declare
            From_Lit : constant String :=
              State_Literal (Id_Of (D, R.From));
            To_Lit   : constant String :=
              Effective_Target (Id_Of (D, R.To));
            Ev_Lit   : constant String :=
              Event_Literal (To_String (R.Trigger));
         begin
            if not Pair_Seen (From_Lit, Ev_Lit) then
               Remember (From_Lit, Ev_Lit);
               Test_Procs := Test_Procs
                 & ("Test_" & From_Lit & "_" & Ev_Lit);
               Froms      := Froms & From_Lit;
               Events     := Events & Ev_Lit;
               Targets    := Targets & To_Lit;
            end if;
         end;

         <<Continue>>
      end loop;

      Insert (T_Case, Assoc ("PACKAGE_NAME", Package_Name));
      Insert (T_Case, Assoc ("TEST_PACKAGE", Test_Pkg));
      Insert (T_Case, Assoc ("TEST_PROC", Test_Procs));
      Insert (T_Case, Assoc ("FROM", Froms));
      Insert (T_Case, Assoc ("EVENT", Events));
      Insert (T_Case, Assoc ("TARGET", Targets));

      Render ("test_case.ads.tmplt",
              Ada.Directories.Compose (Test_Dir, Test_Pkg & ".ads"),
              T_Case);
      Render ("test_case.adb.tmplt",
              Ada.Directories.Compose (Test_Dir, Test_Pkg & ".adb"),
              T_Case);
   end Emit_Tests_For_Region;

   --  Recursive walker: for every region (top level and each
   --  composite), emit a test case package, and collect the test
   --  package names for the suite composition.
   procedure Emit_Tests_All_Regions
     (D              : UML.Model.Diagram;
      Region         : Natural;
      Package_Name   : String;
      Test_Dir       : String;
      Case_Packages  : in out Tag;
      N_Cases        : in out Natural)
   is
      Test_Pkg : constant String := Package_Name & "_Tests";
      States   : constant Element_Index_Vectors.Vector :=
        States_In (D, Region);
      Children : constant Element_Index_Vectors.Vector :=
        Composite_Children_Of (D, States);
   begin
      Emit_Tests_For_Region (D, Region, Package_Name, Test_Pkg, Test_Dir);
      N_Cases := N_Cases + 1;
      Case_Packages := Case_Packages & Test_Pkg;

      for C of Children loop
         Emit_Tests_All_Regions
           (D             => D,
            Region        => Natural (C),
            Package_Name  => Child_Package_Name (D, C),
            Test_Dir      => Test_Dir,
            Case_Packages => Case_Packages,
            N_Cases       => N_Cases);
      end loop;
   end Emit_Tests_All_Regions;

   procedure Emit_Tests
     (D              : UML.Model.Diagram;
      Package_Name   : String;
      Tests_Dir      : String)
   is
      Test_Dir : constant String :=
        Ada.Directories.Compose (Tests_Dir, "test");
      Suite_Name : constant String := Package_Name & "_Suite";

      Case_Packages : Tag;
      N_Cases       : Natural := 0;

      procedure Render (Subdir, Template, Output : String;
                        T : Translate_Set) is
         Path : constant String :=
           Uml2Code_Template_Path.Locate (Subdir, Template);
         Content : constant String := Templates_Parser.Parse (Path, T);
         F : File_Type;
      begin
         Create (F, Out_File, Output);
         Put (F, Content);
         Close (F);
      end Render;

      Empty_Set : Translate_Set;
   begin
      Ada.Directories.Create_Path (Test_Dir);

      --  Harness: test_main.adb and all_tests.ads are static.
      Render ("ada/project/tests", "test_main.adb.tmplt",
              Ada.Directories.Compose (Test_Dir, "test_main.adb"),
              Empty_Set);
      Render ("ada/project/tests", "all_tests.ads.tmplt",
              Ada.Directories.Compose (Test_Dir, "all_tests.ads"),
              Empty_Set);

      --  Per-region test cases.
      Emit_Tests_All_Regions
        (D             => D,
         Region        => Top_Level,
         Package_Name  => Package_Name,
         Test_Dir      => Test_Dir,
         Case_Packages => Case_Packages,
         N_Cases       => N_Cases);

      --  all_tests.adb is a thin wrapper over the suite.
      declare
         T_A : Translate_Set;
      begin
         Insert (T_A, Assoc ("SUITE_NAME", Suite_Name));
         Render ("ada/project/tests", "all_tests.adb.tmplt",
                 Ada.Directories.Compose (Test_Dir, "all_tests.adb"),
                 T_A);
      end;

      --  Suite composition.
      declare
         T_S : Translate_Set;
         Index_Tag : Tag;
      begin
         for I in 1 .. N_Cases loop
            Index_Tag := Index_Tag
              & Ada.Strings.Fixed.Trim (I'Image, Ada.Strings.Both);
         end loop;
         Insert (T_S, Assoc ("SUITE_NAME", Suite_Name));
         Insert (T_S, Assoc ("CASE_PACKAGE", Case_Packages));
         Insert (T_S, Assoc ("TEST_INDEX", Index_Tag));
         Render ("ada/project/tests", "suite.ads.tmplt",
                 Ada.Directories.Compose (Test_Dir, Suite_Name & ".ads"),
                 T_S);
         Render ("ada/project/tests", "suite.adb.tmplt",
                 Ada.Directories.Compose (Test_Dir, Suite_Name & ".adb"),
                 T_S);
      end;

      --  tests.gpr
      declare
         T_Gpr : Translate_Set;
      begin
         Insert (T_Gpr, Assoc ("TESTS_PROJECT", Package_Name & "_Tests"));
         Render ("ada/project/tests", "tests.gpr.tmplt",
                 Ada.Directories.Compose
                   (Ada.Directories.Containing_Directory (Tests_Dir),
                    Package_Name & "_tests.gpr"),
                 T_Gpr);
      end;

      Put_Line ("wrote test suite for " & Package_Name);
   end Emit_Tests;



   --  Refuse to write generated output into the crate's own source
   --  or test tree. The CLI enforces the same policy at the -o flag,
   --  but tests call Generate directly.
   procedure Refuse_Crate_Internal_Output (Out_Dir : String) is
      function Contains (Haystack, Needle : String) return Boolean is
        (Ada.Strings.Fixed.Index (Haystack, Needle) > 0);
   begin
      if Contains (Out_Dir, "uml2code/tests")
        or else Contains (Out_Dir, "uml2code/src")
        or else Contains (Out_Dir, "plantuml_parser/tests")
        or else Contains (Out_Dir, "plantuml_parser/src")
      then
         raise Constraint_Error with
           "refusing to write into the crate tree: " & Out_Dir;
      end if;
   end Refuse_Crate_Internal_Output;

   procedure Generate
     (D              : UML.Model.Diagram;
      Package_Name   : String;
      Source_Diagram : String;
      Out_Dir        : String)
   is
      Date_Str : Unbounded_String;
   begin
      Refuse_Crate_Internal_Output (Out_Dir);
      declare
         Now : constant Ada.Calendar.Time := Ada.Calendar.Clock;
         Yr  : Ada.Calendar.Year_Number;
         Mn  : Ada.Calendar.Month_Number;
         Dd  : Ada.Calendar.Day_Number;
         Ss  : Ada.Calendar.Day_Duration;
      begin
         Ada.Calendar.Split (Now, Yr, Mn, Dd, Ss);
         Date_Str :=
           To_Unbounded_String
             (Ada.Strings.Fixed.Trim
                (Ada.Calendar.Year_Number'Image (Yr),
                 Ada.Strings.Both)
              & "-"
              & Ada.Strings.Fixed.Trim
                (Ada.Calendar.Month_Number'Image (Mn),
                 Ada.Strings.Both)
              & "-"
              & Ada.Strings.Fixed.Trim
                (Ada.Calendar.Day_Number'Image (Dd),
                 Ada.Strings.Both));
      end;

      declare
         Src_Dir   : constant String :=
           Ada.Directories.Compose (Out_Dir, "src");
         Tests_Dir : constant String :=
           Ada.Directories.Compose (Out_Dir, "tests");
      begin
         Ada.Directories.Create_Path (Src_Dir);
         Ada.Directories.Create_Path (Tests_Dir);

         Emit_Runtime (Src_Dir);
         Emit_Test_Driver (Tests_Dir, Package_Name);
         Emit_Tests (D, Package_Name, Tests_Dir);
         Emit_Setup (Out_Dir, Package_Name);

         Generate_Region
           (D              => D,
            Region         => Top_Level,
            Package_Name   => Package_Name,
            Source_Diagram => Source_Diagram,
            Date_Str       => To_String (Date_Str),
            Out_Dir        => Src_Dir);
      end;
   end Generate;

end Uml2Code_Ada;
