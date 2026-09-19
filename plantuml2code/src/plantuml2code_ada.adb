with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Directories;
with Ada.Calendar;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;

with PlantUML.States;          use PlantUML.States;
with PlantUML2Code_Utils;      use PlantUML2Code_Utils;
with Templates_Parser;         use Templates_Parser;

package body PlantUML2Code_Ada is

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
           and then Element (Tmp, Length (Tmp)) = '_'
         loop
            Delete (Tmp, Length (Tmp), Length (Tmp));
         end loop;

         if Length (Tmp) > 0
           and then Element (Tmp, 1) in '0' .. '9'
         then
            return "S_" & To_String (Tmp);
         end if;

         if Length (Tmp) = 0 then
            return "Unnamed";
         end if;

         return To_String (Tmp);
      end;
   end Sanitize;

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

   function Find_State (D : State_Diagram; Name : String)
                        return State_Index
   is
   begin
      for I in D.Pool.First_Index .. D.Pool.Last_Index loop
         if To_String (D.Pool (I).Id) = Name then
            return State_Index (I);
         end if;
      end loop;
      raise Constraint_Error with "state not found: " & Name;
   end Find_State;

   function Region_Of (D : State_Diagram; Idx : State_Index)
                       return Natural
   is
   begin
      for I in D.Pool.First_Index .. D.Pool.Last_Index loop
         for C of D.Pool (I).Children loop
            if C = Idx then
               return Natural (I);
            end if;
         end loop;
      end loop;
      return Top_Level;
   end Region_Of;

   function States_In (D : State_Diagram; Region : Natural)
                       return Index_Vectors.Vector
   is
      Result : Index_Vectors.Vector;
   begin
      if Region = Top_Level then
         for I of D.Roots loop
            if D.Pool (Positive (I)).Kind
              not in History_Shallow | History_Deep
            then
               Result.Append (I);
            end if;
         end loop;
      else
         for C of D.Pool (Positive (Region)).Children loop
            Result.Append (C);
         end loop;
      end if;
      return Result;
   end States_In;

   function Transitions_In (D : State_Diagram; Region : Natural)
                            return Transition_Vectors.Vector
   is
      Result : Transition_Vectors.Vector;
   begin
      for T of D.Transitions loop
         declare
            From_Idx : constant State_Index :=
              Find_State (D, To_String (T.From));
            To_Idx   : constant State_Index :=
              Find_State (D, To_String (T.To));
            From_Reg : constant Natural := Region_Of (D, From_Idx);
            To_Reg   : constant Natural := Region_Of (D, To_Idx);
            Include  : Boolean := False;
         begin
            if From_Reg = Region and then To_Reg = Region then
               Include := True;
            elsif From_Reg = Region
              and then Is_History_Target (To_String (T.To))
            then
               declare
                  Parent_Idx : constant State_Index :=
                    Find_State (D, Parent_Name (To_String (T.To)));
               begin
                  if Region_Of (D, Parent_Idx) = Region then
                     Include := True;
                  end if;
               end;
            end if;
            if Include then
               Result.Append (T);
            end if;
         end;
      end loop;
      return Result;
   end Transitions_In;

   function Composite_Children_Of
     (D : State_Diagram; States : Index_Vectors.Vector)
      return Index_Vectors.Vector
   is
      Result : Index_Vectors.Vector;
   begin
      for S of States loop
         if D.Pool (Positive (S)).Kind = Composite then
            Result.Append (S);
         end if;
      end loop;
      return Result;
   end Composite_Children_Of;

   type Seen_Array is array (1 .. 64) of Unbounded_String;

   procedure Add_Event
     (Seen    : in out Seen_Array;
      N       : in out Natural;
      Trigger : String)
   is
      Lit : constant String := Event_Literal (Trigger);
      Found : Boolean := False;
   begin
      if Trigger'Length = 0 then
         return;
      end if;
      for I in 1 .. N loop
         if To_String (Seen (I)) = Lit then
            Found := True;
            exit;
         end if;
      end loop;
      if not Found and then N < Seen'Length then
         N := N + 1;
         Seen (N) := To_Unbounded_String (Lit);
      end if;
   end Add_Event;

   function Collect_Events
     (D      : State_Diagram;
      Ts     : Transition_Vectors.Vector;
      States : Index_Vectors.Vector) return String
   is
      Seen : Seen_Array;
      N    : Natural := 0;
      R    : Unbounded_String;
   begin
      for T of Ts loop
         Add_Event (Seen, N, To_String (T.Trigger));
      end loop;

      for I of States loop
         for A of D.Pool (Positive (I)).Annotations loop
            if A.Kind = Internal_Transition then
               Add_Event (Seen, N, To_String (A.Trigger));
            end if;
         end loop;
      end loop;

      if N = 0 then
         return "Tick";
      end if;

      for I in 1 .. N loop
         if I > 1 then
            Append (R, ", ");
         end if;
         Append (R, Seen (I));
      end loop;

      return To_String (R);
   end Collect_Events;

   function State_Literals_Of
     (D : State_Diagram; States : Index_Vectors.Vector) return String
   is
      R : Unbounded_String;
      First : Boolean := True;
   begin
      for I of States loop
         if not First then
            Append (R, ", ");
         end if;
         Append (R, State_Literal (To_String (D.Pool (Positive (I)).Id)));
         First := False;
      end loop;
      return To_String (R);
   end State_Literals_Of;

   function Initial_State_Of
     (D : State_Diagram; Region : Natural; States : Index_Vectors.Vector)
      return String
   is
      Start_Name : constant String :=
        (if Region = Top_Level then "[*]_start"
         else To_String (D.Pool (Positive (Region)).Id) & ".[*]_start");
   begin
      for T of D.Transitions loop
         if To_String (T.From) = Start_Name then
            return State_Literal (To_String (T.To));
         end if;
      end loop;
      for I of States loop
         declare
            Lit : constant String :=
              State_Literal (To_String (D.Pool (Positive (I)).Id));
         begin
            if Lit /= "Start_State" and Lit /= "End_State"
              and Lit /= "History" and Lit /= "Deep_History"
            then
               return Lit;
            end if;
         end;
      end loop;
      return "Idle";
   end Initial_State_Of;

   function Transition_Rows
     (D : State_Diagram; Region : Natural; States : Index_Vectors.Vector)
      return String
   is
      Ts : constant Transition_Vectors.Vector :=
        Transitions_In (D, Region);
      Events : constant String := Collect_Events (D, Ts, States);
      Ev_List : Unbounded_String;
      R : Unbounded_String;
      First_State : Boolean := True;

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
            if State_Literal (To_String (T.From)) = From_Lit
              and then Event_Literal (To_String (T.Trigger)) = Ev_Lit
            then
               return Effective_Target (To_String (T.To));
            end if;
         end loop;
         return From_Lit;
      end Target_For;

   begin
      Split_Events;

      for I of States loop
         declare
            From_Lit : constant String :=
              State_Literal (To_String (D.Pool (Positive (I)).Id));
         begin
            if not First_State then
               Append (R, "," & ASCII.LF & "      ");
            end if;
            First_State := False;
            Append (R, From_Lit & " =>" & ASCII.LF & "        [");
            declare
               Evs : constant String := To_String (Ev_List);
               J   : Natural := Evs'First;
               St  : Natural;
               First_Ev : Boolean := True;
            begin
               while J <= Evs'Last loop
                  St := J;
                  while J <= Evs'Last and then Evs (J) /= ',' loop
                     J := J + 1;
                  end loop;
                  declare
                     Ev_Lit : constant String := Evs (St .. J - 1);
                     Tgt : constant String := Target_For (From_Lit, Ev_Lit);
                  begin
                     if not First_Ev then
                        Append (R, "," & ASCII.LF & "         ");
                     end if;
                     First_Ev := False;
                     Append (R, Ev_Lit & " => " & Tgt);
                  end;
                  if J <= Evs'Last then
                     J := J + 1;
                  end if;
               end loop;
               Append (R, "]");
            end;
         end;
      end loop;

      return To_String (R);
   end Transition_Rows;

   function History_Cases
     (D : State_Diagram; States : Index_Vectors.Vector;
      Ts : Transition_Vectors.Vector) return String
   is
      R : Unbounded_String;
   begin
      for I of States loop
         declare
            From_Lit : constant String :=
              State_Literal (To_String (D.Pool (Positive (I)).Id));
            Arms : Unbounded_String;
            First_Ev : Boolean := True;
         begin
            for T of Ts loop
               if State_Literal (To_String (T.From)) = From_Lit
                 and then Is_History_Target (To_String (T.To))
               then
                  declare
                     Kind : constant String :=
                       (if Ada.Strings.Fixed.Index
                             (To_String (T.To), "[H*]") > 0
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
     (D : State_Diagram; Child : State_Index) return String is
     (State_Literal (To_String (D.Pool (Positive (Child)).Id)) & "_Machine");

   function Child_Field_Name
     (D : State_Diagram; Child : State_Index) return String is
     (State_Literal (To_String (D.Pool (Positive (Child)).Id)) & "_Child");

   function Action_Decls
     (D : State_Diagram; States : Index_Vectors.Vector) return String
   is
      R : Unbounded_String;
   begin
      for S of States loop
         for A of D.Pool (Positive (S)).Annotations loop
            case A.Kind is
               when Entry_Action | Exit_Action | Do_Activity
                  | Internal_Transition =>
                  declare
                     Action_Name : constant String :=
                       Sanitize (To_String (A.Action));
                  begin
                     if Length (A.Action) > 0 then
                        Append (R, "   procedure " & Action_Name
                               & ";  --  "
                               & A.Kind'Image & ": "
                               & To_String (A.Action) & ASCII.LF);
                     end if;
                  end;
               when others => null;
            end case;
         end loop;
      end loop;
      return To_String (R);
   end Action_Decls;

   function Action_Bodies
     (D : State_Diagram; States : Index_Vectors.Vector) return String
   is
      R : Unbounded_String;
   begin
      for S of States loop
         for A of D.Pool (Positive (S)).Annotations loop
            case A.Kind is
               when Entry_Action | Exit_Action | Do_Activity
                  | Internal_Transition =>
                  declare
                     Action_Name : constant String :=
                       Sanitize (To_String (A.Action));
                  begin
                     if Length (A.Action) > 0 then
                        Append (R, "   procedure " & Action_Name
                               & " is" & ASCII.LF
                               & "   begin" & ASCII.LF
                               & "      null;  --  TODO: "
                               & A.Kind'Image & ": "
                               & To_String (A.Action) & ASCII.LF
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
      Content : constant String := Render_Template ("ada", Template, T);
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

   procedure Emit_Deeper_Steppers
     (D : State_Diagram;
      Region : Natural;
      Prefix : String;
      With_Clauses, Decls, Bodies : in out Unbounded_String)
   is
      States     : constant Index_Vectors.Vector := States_In (D, Region);
      Composites : constant Index_Vectors.Vector :=
        Composite_Children_Of (D, States);
   begin
      for C of Composites loop
         declare
            Child_Pkg   : constant String := Child_Package_Name (D, C);
            Child_Field : constant String := Child_Field_Name (D, C);
            State_Lit   : constant String :=
              State_Literal (To_String (D.Pool (Positive (C)).Id));
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
     (D              : State_Diagram;
      Region         : Natural;
      Package_Name   : String;
      Source_Diagram : String;
      Date_Str       : String;
      Out_Dir        : String)
   is
      States       : constant Index_Vectors.Vector := States_In (D, Region);
      Ts           : constant Transition_Vectors.Vector :=
        Transitions_In (D, Region);
      Child_States : constant Index_Vectors.Vector :=
        Composite_Children_Of (D, States);

      T : Translate_Set;

      State_Lits : constant String := State_Literals_Of (D, States);
      Events     : constant String := Collect_Events (D, Ts, States);
      Initial    : constant String := Initial_State_Of (D, Region, States);
      Rows       : constant String := Transition_Rows (D, Region, States);

      Action_Decls_Text  : constant String := Action_Decls (D, States);
      Action_Bodies_Text : constant String := Action_Bodies (D, States);

      With_Clauses  : Unbounded_String;
      Record_Fields : Unbounded_String;
      Step_Decls    : Unbounded_String;
      Step_Bodies   : Unbounded_String;
      On_Enter_Arms : Unbounded_String;
      On_Exit_Arms  : Unbounded_String;
      On_Internal_Arms : Unbounded_String;
      On_Tick_Arms  : Unbounded_String;

      Ads_File : constant String :=
        Ada.Directories.Compose (Out_Dir, Package_Name & ".ads");
      Adb_File : constant String :=
        Ada.Directories.Compose (Out_Dir, Package_Name & ".adb");
      Act_Ads : constant String :=
        Ada.Directories.Compose (Out_Dir, Package_Name & "_Actions.ads");
      Act_Adb : constant String :=
        Ada.Directories.Compose (Out_Dir, Package_Name & "_Actions.adb");
   begin
      for C of Child_States loop
         declare
            Child_Pkg   : constant String := Child_Package_Name (D, C);
            Child_Field : constant String := Child_Field_Name (D, C);
            State_Lit   : constant String :=
              State_Literal (To_String (D.Pool (Positive (C)).Id));
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
              State_Literal (To_String (D.Pool (Positive (I)).Id));
            Is_Composite : Boolean := False;
            Has_Entry    : Boolean := False;
            Has_Exit     : Boolean := False;
         begin
            for C of Child_States loop
               if State_Literal (To_String (D.Pool (Positive (C)).Id)) = Lit then
                  Is_Composite := True;
                  exit;
               end if;
            end loop;
            for A of D.Pool (Positive (I)).Annotations loop
               if A.Kind = Entry_Action then Has_Entry := True; end if;
               if A.Kind = Exit_Action  then Has_Exit  := True; end if;
            end loop;

            if not Is_Composite then
               Append (On_Enter_Arms,
                       "         when " & Lit & " =>" & ASCII.LF);
               if Lit = "End_State" then
                  Append (On_Enter_Arms,
                          "            Mark_Terminated (Self);"
                          & ASCII.LF);
               else
                  for A of D.Pool (Positive (I)).Annotations loop
                     if A.Kind = Entry_Action
                       and then Length (A.Action) > 0
                     then
                        Append (On_Enter_Arms,
                                "            "
                                & Sanitize (To_String (A.Action))
                                & ";" & ASCII.LF);
                     end if;
                  end loop;
                  if not Has_Entry then
                     Append (On_Enter_Arms,
                             "            null;" & ASCII.LF);
                  end if;
               end if;
            end if;

            Append (On_Exit_Arms,
                    "         when " & Lit & " =>" & ASCII.LF);
            for A of D.Pool (Positive (I)).Annotations loop
               if A.Kind = Exit_Action and then Length (A.Action) > 0 then
                  Append (On_Exit_Arms,
                          "            "
                          & Sanitize (To_String (A.Action))
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
               for A of D.Pool (Positive (I)).Annotations loop
                  if A.Kind = Internal_Transition
                    and then Length (A.Trigger) > 0
                    and then Length (A.Action) > 0
                  then
                     Has_Internal := True;
                     Append (Body_Text,
                             "            if On = "
                             & Sanitize (To_String (A.Trigger))
                             & " then" & ASCII.LF
                             & "               "
                             & Sanitize (To_String (A.Action))
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
               for A of D.Pool (Positive (I)).Annotations loop
                  if A.Kind = Do_Activity and then Length (A.Action) > 0 then
                     Has_Do := True;
                     Append (Do_Body,
                             "            "
                             & Sanitize (To_String (A.Action))
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
      Insert (T, Assoc ("DESCRIPTION",
                        "State machine generated from " & Source_Diagram));
      Insert (T, Assoc ("SOURCE_DIAGRAM", Source_Diagram));
      Insert (T, Assoc ("GENERATION_DATE", Date_Str));
      Insert (T, Assoc ("CHILD_WITH_CLAUSES", To_String (With_Clauses)));
      Insert (T, Assoc ("STATE_LITERALS", State_Lits));
      Insert (T, Assoc ("EVENT_LITERALS", Events));
      Insert (T, Assoc ("INITIAL_STATE", Initial));
      Insert (T, Assoc ("STEP_CHILD_DECLS", To_String (Step_Decls)));
      Insert (T, Assoc ("TRANSITION_ROWS", Rows));
      Insert (T, Assoc ("ON_ENTER_CASES", To_String (On_Enter_Arms)));
      Insert (T, Assoc ("ON_EXIT_CASES", To_String (On_Exit_Arms)));
      Insert (T, Assoc ("ON_INTERNAL_CASES", To_String (On_Internal_Arms)));
      Insert (T, Assoc ("ON_TICK_CASES", To_String (On_Tick_Arms)));
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
              ("with " & Package_Name & "_Actions;" & ASCII.LF & ASCII.LF);
            Use_Txt := To_Unbounded_String
              ("   use " & Package_Name & "_Actions;" & ASCII.LF);
         end if;
         Insert (T, Assoc ("ACTIONS_WITH", With_Txt));
         Insert (T, Assoc ("ACTIONS_USE", Use_Txt));
      end;

      Render_To ("state.ads.tmplt", Ads_File, T);
      Render_To ("state.adb.tmplt", Adb_File, T);

      if Action_Decls_Text'Length > 0 then
         Render_If_Missing ("actions.ads.tmplt", Act_Ads, T);
         Render_If_Missing ("actions.adb.tmplt", Act_Adb, T);
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

   procedure Generate
     (D              : State_Diagram;
      Package_Name   : String;
      Source_Diagram : String;
      Out_Dir        : String)
   is
      Date_Str : Unbounded_String;
   begin
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

      Generate_Region
        (D              => D,
         Region         => Top_Level,
         Package_Name   => Package_Name,
         Source_Diagram => Source_Diagram,
         Date_Str       => To_String (Date_Str),
         Out_Dir        => Out_Dir);
   end Generate;

end PlantUML2Code_Ada;
