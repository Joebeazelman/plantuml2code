with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Templates_Parser;         use Templates_Parser;

with UML.Model;                use UML.Model;

with Uml2Code_Utils;      use Uml2Code_Utils;

package body Uml2Code_Template_Bindings is

   --  Templates_Parser.Tag shadows UML.Model.Annotation_Kind's Tag
   --  literal. Nothing here uses the literal.
   subtype Tag is Templates_Parser.Tag;

   function Id_Of (D : UML.Model.Diagram; Idx : Element_Index)
                   return String is
     (To_String (D.Elements (Positive (Idx)).Id));

   --  ---------------------------------------------------------------
   --  JSON escape filter, as a Templates Parser user filter
   --  ---------------------------------------------------------------
   type Json_Escape_Filter is new Templates_Parser.User_Filter
     with null record;

   overriding
   function Execute
     (Filter     : not null access Json_Escape_Filter;
      Value      : String;
      Parameters : String;
      Context    : Templates_Parser.Filter_Context) return String
   is
      pragma Unreferenced (Filter, Parameters, Context);
   begin
      return Escape_Json (Value);
   end Execute;

   Json_Escaper : aliased Json_Escape_Filter;

   procedure Register_Filters is
   begin
      Templates_Parser.Register_Filter
        ("JSON_ESCAPE", Json_Escaper'Access);
   end Register_Filters;

   --  ---------------------------------------------------------------
   --  Helpers
   --  ---------------------------------------------------------------
   function Has_Text (S : Unbounded_String) return Boolean is
     (Length (S) > 0);

   function Is_Transition (R : Relation) return Boolean is
     (R.Kind in UML.Model.Transition
              | UML.Model.Internal_Transition_Kind
              | UML.Model.Completion);

   --  ---------------------------------------------------------------
   --  States
   --  ---------------------------------------------------------------
   function For_States
     (D : UML.Model.Diagram) return Translate_Set
   is
      T : Translate_Set;

      State_Lines      : Tag;
      State_Lines_Json : Tag;
      Trans_Lines      : Tag;
      Trans_Lines_Json : Tag;

      Last_State : constant Natural := Natural (D.Elements.Length);
      Last_Trans : constant Natural := Natural (D.Relations.Length);

      State_Index : Natural := 0;
      Trans_Index : Natural := 0;
   begin
      Insert (T, Assoc ("DIAGRAM_NAME", To_String (D.Id)));

      --  Text lines for states
      for S of D.Elements loop
         State_Index := State_Index + 1;
         declare
            Line : Unbounded_String :=
              To_Unbounded_String (To_String (S.Id)
                                   & "  kind=" & S.Kind'Image);
         begin
            if Has_Text (S.Display) then
               Append (Line, "  as=");
               Append (Line, S.Display);
            end if;
            State_Lines := State_Lines & To_String (Line);
         end;
      end loop;

      --  JSON lines for states
      State_Index := 0;
      for S of D.Elements loop
         State_Index := State_Index + 1;
         declare
            Line : Unbounded_String :=
              To_Unbounded_String ("{""id"": """);
            Comma : constant String :=
              (if State_Index < Last_State then "," else "");
         begin
            Append (Line, Escape_Json (To_String (S.Id)));
            Append (Line, """, ""kind"": """);
            Append (Line, Escape_Json (S.Kind'Image));
            Append (Line, """, ""display"": """);
            Append (Line, Escape_Json (To_String (S.Display)));
            Append (Line, """}" & Comma);
            State_Lines_Json := State_Lines_Json & To_String (Line);
         end;
      end loop;

      --  Text lines for transitions
      for R of D.Relations loop
         if Is_Transition (R) then
            Trans_Index := Trans_Index + 1;
            declare
               Line : Unbounded_String :=
                 To_Unbounded_String (Id_Of (D, R.From)
                                      & " -> "
                                      & Id_Of (D, R.To)
                                      & "  kind="
                                      & R.Kind'Image);
            begin
               if Has_Text (R.Trigger) then
                  Append (Line, "  trigger=");
                  Append (Line, R.Trigger);
               end if;
               if Has_Text (R.Guard) then
                  Append (Line, "  guard=");
                  Append (Line, R.Guard);
               end if;
               if Has_Text (R.Effect) then
                  Append (Line, "  effect=");
                  Append (Line, R.Effect);
               end if;
               Trans_Lines := Trans_Lines & To_String (Line);
            end;
         end if;
      end loop;

      --  JSON lines for transitions
      Trans_Index := 0;
      for R of D.Relations loop
         if Is_Transition (R) then
            Trans_Index := Trans_Index + 1;
            declare
               Line : Unbounded_String := To_Unbounded_String ("{");
               Comma : constant String :=
                 (if Trans_Index < Last_Trans then "," else "");
            begin
               Append (Line, """from"": """);
               Append (Line, Escape_Json (Id_Of (D, R.From)));
               Append (Line, """, ""to"": """);
               Append (Line, Escape_Json (Id_Of (D, R.To)));
               Append (Line, """, ""kind"": """);
               Append (Line, Escape_Json (R.Kind'Image));
               Append (Line, """, ""trigger"": """);
               Append (Line, Escape_Json (To_String (R.Trigger)));
               Append (Line, """, ""guard"": """);
               Append (Line, Escape_Json (To_String (R.Guard)));
               Append (Line, """, ""effect"": """);
               Append (Line, Escape_Json (To_String (R.Effect)));
               Append (Line, """}" & Comma);
               Trans_Lines_Json := Trans_Lines_Json & To_String (Line);
            end;
         end if;
      end loop;

      Insert (T, Assoc ("STATE_LINES",       State_Lines));
      Insert (T, Assoc ("STATE_LINES_JSON",  State_Lines_Json));
      Insert (T, Assoc ("TRANS_LINES",       Trans_Lines));
      Insert (T, Assoc ("TRANS_LINES_JSON",  Trans_Lines_Json));

      return T;
   end For_States;

   --  ---------------------------------------------------------------
   --  Classes
   --  ---------------------------------------------------------------
   function For_Classes
     (D : UML.Model.Diagram) return Translate_Set
   is
      T : Translate_Set;

      Class_Lines      : Tag;
      Class_Lines_Json : Tag;
      Rel_Lines        : Tag;
      Rel_Lines_Json   : Tag;

      Last_Class : constant Natural := Natural (D.Elements.Length);
      Last_Rel   : constant Natural := Natural (D.Relations.Length);

      Class_Index : Natural := 0;
      Rel_Index   : Natural := 0;
   begin
      Insert (T, Assoc ("DIAGRAM_NAME", To_String (D.Id)));

      for K of D.Elements loop
         Class_Index := Class_Index + 1;
         declare
            Line : Unbounded_String :=
              To_Unbounded_String (To_String (K.Id)
                                   & "  kind=" & K.Kind'Image);
         begin
            if Has_Text (K.Display) then
               Append (Line, "  as=");
               Append (Line, K.Display);
            end if;
            Class_Lines := Class_Lines & To_String (Line);
         end;
      end loop;

      Class_Index := 0;
      for K of D.Elements loop
         Class_Index := Class_Index + 1;
         declare
            Line : Unbounded_String := To_Unbounded_String ("{");
            Comma : constant String :=
              (if Class_Index < Last_Class then "," else "");
         begin
            Append (Line, """id"": """);
            Append (Line, Escape_Json (To_String (K.Id)));
            Append (Line, """, ""kind"": """);
            Append (Line, Escape_Json (K.Kind'Image));
            Append (Line, """, ""display"": """);
            Append (Line, Escape_Json (To_String (K.Display)));
            Append (Line, """}" & Comma);
            Class_Lines_Json := Class_Lines_Json & To_String (Line);
         end;
      end loop;

      for R of D.Relations loop
         Rel_Index := Rel_Index + 1;
         declare
            Line : Unbounded_String :=
              To_Unbounded_String (Id_Of (D, R.From)
                                   & " "
                                   & R.Kind'Image
                                   & " "
                                   & Id_Of (D, R.To));
         begin
            if Has_Text (R.Mult_To) then
               Append (Line, "  [");
               Append (Line, R.Mult_To);
               Append (Line, "]");
            end if;
            if Has_Text (R.Label) then
               Append (Line, "  : ");
               Append (Line, R.Label);
            end if;
            Rel_Lines := Rel_Lines & To_String (Line);
         end;
      end loop;

      Rel_Index := 0;
      for R of D.Relations loop
         Rel_Index := Rel_Index + 1;
         declare
            Line : Unbounded_String := To_Unbounded_String ("{");
            Comma : constant String :=
              (if Rel_Index < Last_Rel then "," else "");
         begin
            Append (Line, """from"": """);
            Append (Line, Escape_Json (Id_Of (D, R.From)));
            Append (Line, """, ""to"": """);
            Append (Line, Escape_Json (Id_Of (D, R.To)));
            Append (Line, """, ""kind"": """);
            Append (Line, Escape_Json (R.Kind'Image));
            Append (Line, """, ""label"": """);
            Append (Line, Escape_Json (To_String (R.Label)));
            Append (Line, """, ""mult_to"": """);
            Append (Line, Escape_Json (To_String (R.Mult_To)));
            Append (Line, """}" & Comma);
            Rel_Lines_Json := Rel_Lines_Json & To_String (Line);
         end;
      end loop;

      Insert (T, Assoc ("CLASS_LINES",       Class_Lines));
      Insert (T, Assoc ("CLASS_LINES_JSON",  Class_Lines_Json));
      Insert (T, Assoc ("REL_LINES",         Rel_Lines));
      Insert (T, Assoc ("REL_LINES_JSON",    Rel_Lines_Json));

      return T;
   end For_Classes;

end Uml2Code_Template_Bindings;
