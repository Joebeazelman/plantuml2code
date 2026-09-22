with Ada.Strings.Fixed;        use Ada.Strings.Fixed;
with PlantUML.Tokens;          use PlantUML.Tokens;

package body PlantUML.Classes is

   type Builder is record
      D    : Class_Diagram;
      Open : Index_Vectors.Vector;
   end record;

   function Parse (Source : String) return Class_Diagram is
      Toks : aliased constant List := Tokenize (Source);
      C    : Cursor  := Make (Toks);
      B    : Builder;

      function Consume return Token is
         T : constant Token := C.Peek;
      begin
         C.Next;
         return T;
      end Consume;

      function Peek_At (Ahead : Natural) return Token is
         I : constant Natural := PlantUML.Tokens.Position (C) + Ahead;
      begin
         if I <= Natural (Toks.Length) then
            return Toks (I);
         else
            return (Kind         => Eof,
                    Text         => Null_Unbounded_String,
                    Line         => 1,
                    Space_Before => False);
         end if;
      end Peek_At;

      function Add_Classifier (K : Classifier) return Class_Index is
      begin
         B.D.Pool.Append (K);
         return Class_Index (B.D.Pool.Last_Index);
      end Add_Classifier;

      procedure Attach (Idx : Class_Index) is
      begin
         if B.Open.Is_Empty then
            B.D.Roots.Append (Idx);
         else
            declare
               Top_Idx : constant Class_Index := B.Open.Last_Element;
               Top     : Classifier := B.D.Pool (Positive (Top_Idx));
            begin
               Top.Children.Append (Idx);
               B.D.Pool.Replace_Element (Positive (Top_Idx), Top);
            end;
         end if;
      end Attach;

      procedure Append_Classifier (K : Classifier) is
      begin
         Attach (Add_Classifier (K));
      end Append_Classifier;

      procedure Open_Classifier (K : Classifier) is
      begin
         Append_Classifier (K);
         B.Open.Append (Class_Index (B.D.Pool.Last_Index));
      end Open_Classifier;

      procedure Close_Classifier is
      begin
         if not B.Open.Is_Empty then
            B.Open.Delete_Last;
         end if;
      end Close_Classifier;

      procedure Add_Member_To_Current (M : Member) is
      begin
         if B.Open.Is_Empty then
            return;
         end if;
         declare
            Idx : constant Class_Index := B.Open.Last_Element;
            K   : Classifier := B.D.Pool (Positive (Idx));
         begin
            K.Members.Append (M);
            B.D.Pool.Replace_Element (Positive (Idx), K);
         end;
      end Add_Member_To_Current;

      procedure Add_Annotation_To (Target : String; A : Annotation) is
      begin
         for I in B.D.Pool.First_Index .. B.D.Pool.Last_Index loop
            declare
               K : Classifier := B.D.Pool (I);
            begin
               if To_String (K.Id) = Target then
                  K.Annotations.Append (A);
                  B.D.Pool.Replace_Element (I, K);
                  return;
               end if;
            end;
         end loop;
      end Add_Annotation_To;

      function Parse_Visibility (Found : out Boolean) return Visibility is
      begin
         Found := True;
         if C.Sym_Is ("+") then
            C.Next;
            return Public_Vis;
         elsif C.Sym_Is ("-") then
            C.Next;
            return Private_Vis;
         elsif C.Sym_Is ("#") then
            C.Next;
            return Protected_Vis;
         elsif C.Sym_Is ("~") then
            C.Next;
            return Package_Level;
         else
            Found := False;
            return Public_Vis;
         end if;
      end Parse_Visibility;

      function Keyword_To_Kind (S : String) return Classifier_Kind is
      begin
         if S = "interface" then
            return Interface_Kind;
         elsif S = "enum" then
            return Enumeration;
         elsif S = "record" then
            return Record_Type;
         elsif S = "annotation" then
            return Annotation_Def;
         elsif S = "package" then
            return Package_Kind;
         elsif S = "object" then
            return Object;
         else
            return Class;
         end if;
      end Keyword_To_Kind;

      function Is_Class_Keyword (S : String) return Boolean is
        (S in "class" | "abstract" | "interface" | "enum"
              | "record" | "annotation" | "package" | "object");

      function Enclosing_Is_Enum return Boolean is
      begin
         if B.Open.Is_Empty then
            return False;
         end if;
         return B.D.Pool (Positive (B.Open.Last_Element)).Kind = Enumeration;
      end Enclosing_Is_Enum;

      function Parse_Member return Member is
         M : Member;
      begin
         --  Enum literals: bare words inside an enumeration body.
         if Enclosing_Is_Enum then
            M.Kind := Enum_Literal;
            M.Vis  := Public_Vis;
            if C.Peek.Kind = Word then
               M.Id := Consume.Text;
            end if;
            while C.Peek.Kind not in Newline | Eof loop
               C.Next;
            end loop;
            return M;
         end if;

         --  Visibility prefix
         declare
            Found : Boolean;
            V     : constant Visibility := Parse_Visibility (Found);
         begin
            if Found then
               M.Vis := V;
            end if;
         end;

         --  Modifiers
         loop
            if C.Word_Is ("static") then
               M.Is_Static := True;
               C.Next;
            elsif C.Word_Is ("abstract") then
               M.Is_Abstract := True;
               C.Next;
            elsif C.Sym_Is ("{") then
               C.Next;
               if C.Word_Is ("static") then
                  M.Is_Static := True;
               elsif C.Word_Is ("abstract") then
                  M.Is_Abstract := True;
               end if;
               while not (C.Sym_Is ("}") or else C.At_Eof) loop
                  C.Next;
               end loop;
               if C.Sym_Is ("}") then C.Next; end if;
            else
               exit;
            end if;
         end loop;

         --  Name
         if C.Peek.Kind = Word then
            M.Id := Consume.Text;
         else
            return M;
         end if;

         --  Method parameters
         if C.Sym_Is ("(") then
            M.Kind := Method;
            C.Next;
            declare
               P : Name := Null_Unbounded_String;
            begin
               while not (C.Sym_Is (")") or else C.At_Eof) loop
                  if Length (P) > 0 then
                     P := P & " ";
                  end if;
                  P := P & C.Peek.Text;
                  C.Next;
               end loop;
               M.Params := P;
               if C.Sym_Is (")") then C.Next; end if;
            end;
         end if;

         --  Type after ':'
         if C.Sym_Is (":") then
            C.Next;
            if not C.At_Eof and then C.Peek.Kind /= Newline then
               M.Type_Name := Consume.Text;
            end if;
         end if;

         --  Trailing tokens
         while C.Peek.Kind not in Newline | Eof loop
            if Length (M.Type_Name) = 0 then
               M.Type_Name := C.Peek.Text;
            else
               M.Type_Name := M.Type_Name & " " & C.Peek.Text;
            end if;
            C.Next;
         end loop;

         return M;
      end Parse_Member;

      function Arrow_To_Kind (S : String) return Relation_Kind is
      begin
         if Index (S, "<|") > 0 and then Index (S, "..") > 0 then
            return Realization;
         elsif Index (S, "<|") > 0 then
            return Inheritance;
         elsif Index (S, "*") > 0 then
            return Composition;
         elsif Index (S, "o") > 0 then
            return Aggregation;
         elsif Index (S, "..") > 0 then
            return Dependency;
         elsif Index (S, ">") > 0 or else Index (S, "<") > 0 then
            return Association;
         else
            return Link;
         end if;
      end Arrow_To_Kind;

      procedure Parse_Relation (From : Name) is
         R : Relation;
      begin
         R.From := From;

         declare
            Arrow_Text : constant String := To_String (Consume.Text);
         begin
            R.Kind := Arrow_To_Kind (Arrow_Text);
         end;

         if C.Peek.Kind = Str then
            R.Mult_To := Consume.Text;
         end if;

         if C.Peek.Kind = Word then
            R.To := Consume.Text;
         else
            raise Parse_Error with "Expected relation target";
         end if;

         if C.Sym_Is ("<") then
            C.Next;
            if C.Sym_Is ("<") then C.Next; end if;
            declare
               S : Name := Null_Unbounded_String;
            begin
               while not (C.Sym_Is (">") or else C.At_Eof) loop
                  S := S & C.Peek.Text;
                  C.Next;
               end loop;
               R.Stereotype := S;
               if C.Sym_Is (">") then C.Next; end if;
               if C.Sym_Is (">") then C.Next; end if;
            end;
         end if;

         if C.Sym_Is (":") then
            C.Next;
            declare
               L : Name := Null_Unbounded_String;
            begin
               while C.Peek.Kind not in Newline | Eof loop
                  if Length (L) > 0 then
                     L := L & " ";
                  end if;
                  L := L & C.Peek.Text;
                  C.Next;
               end loop;
               R.Label := L;
            end;
         end if;

         B.D.Relations.Append (R);
      end Parse_Relation;

   begin
      while not C.At_Eof loop
         declare
            T  : constant Token  := C.Peek;
            Tx : constant String :=
              (if T.Kind = Word then T.Text.To_String else "");
         begin
            if Tx = "@startuml" then
               C.Next;
               if C.Peek.Kind = Word then
                  B.D.Diagram_Name := Consume.Text;
               end if;

            elsif Tx in "@enduml" | "@endclass" then
               exit;

            elsif Tx = "@startclass" then
               C.Next;

            elsif Tx = "title" then
               C.Next;
               declare
                  T : Unbounded_String := Null_Unbounded_String;
               begin
                  while C.Peek.Kind not in Newline | Eof loop
                     if Length (T) > 0 and then C.Peek.Space_Before then
                        Append (T, " ");
                     end if;
                     Append (T, C.Peek.Text);
                     C.Next;
                  end loop;
                  B.D.Title := T;
               end;

            elsif T.Kind = Newline then
               C.Next;

            elsif C.Sym_Is ("}") then
               Close_Classifier;
               C.Next;

            elsif C.Sym_Is ("{") then
               C.Next;

            elsif C.Sym_Is ("--") then
               while C.Peek.Kind not in Newline | Eof loop
                  C.Next;
               end loop;

            elsif Is_Class_Keyword (Tx) then
               C.Next;
               declare
                  K : Classifier;
               begin
                  if Tx = "abstract" then
                     K.Kind := Abstract_Class;
                     if C.Peek.Kind = Word
                       and then C.Peek.Text.To_String = "class"
                     then
                        C.Next;
                     end if;
                  else
                     K.Kind := Keyword_To_Kind (Tx);
                  end if;

                  if C.Peek.Kind = Word then
                     K.Id := Consume.Text;
                  end if;

                  if C.Word_Is ("as") then
                     C.Next;
                     if C.Peek.Kind = Word then
                        K.Display := Consume.Text;
                     end if;
                  end if;

                  if C.Sym_Is ("<") then
                     declare
                        Depth : Natural := 0;
                     begin
                        while not C.At_Eof
                          and then C.Peek.Kind /= Newline
                        loop
                           if C.Sym_Is ("<") then
                              Depth := Depth + 1;
                           elsif C.Sym_Is (">") then
                              Depth := Depth - 1;
                              if Depth = 0 then
                                 C.Next;
                                 exit;
                              end if;
                           end if;
                           C.Next;
                        end loop;
                     end;
                  end if;

                  if C.Sym_Is ("{") then
                     C.Next;
                     Open_Classifier (K);
                  else
                     Append_Classifier (K);
                  end if;
               end;

            elsif Tx = "note" then
               C.Next;
               if C.Peek.Kind = Str then
                  --  Floating: note "text" [as Name]
                  declare
                     Txt : constant Name := C.Peek.Text;
                  begin
                     C.Next;
                     while C.Peek.Kind not in Newline | Eof loop
                        C.Next;
                     end loop;
                     B.D.Notes.Append
                       (Annotation'(Kind     => Note,
                                    Text     =>
                                      To_Unbounded_String
                                        (Decode_Escapes
                                           (To_String (Txt))),
                                    Position => Attached));
                  end;

               elsif C.Peek.Kind = Word then
                  --  Positional: note right|left|top|bottom of X : text
                  declare
                     Pos : Note_Position := Attached;
                     Tgt : Name := Null_Unbounded_String;
                     Txt : Name := Null_Unbounded_String;
                     Dir : constant String := To_String (C.Peek.Text);
                  begin
                     if Dir = "right" then
                        Pos := Right_Of;
                     elsif Dir = "left" then
                        Pos := Left_Of;
                     elsif Dir = "top" then
                        Pos := Top_Of;
                     elsif Dir = "bottom" then
                        Pos := Bottom_Of;
                     end if;
                     C.Next;
                     if C.Peek.Kind = Word
                       and then To_String (C.Peek.Text) = "of"
                     then
                        C.Next;
                     end if;
                     if C.Peek.Kind = Word then
                        Tgt := C.Peek.Text;
                        C.Next;
                     end if;
                     if C.Sym_Is (":") then C.Next; end if;
                     while C.Peek.Kind not in Newline | Eof loop
                        if Length (Txt) > 0
                          and then C.Peek.Space_Before
                        then
                           Txt := Txt & " ";
                        end if;
                        Txt := Txt & C.Peek.Text;
                        C.Next;
                     end loop;
                     if Length (Tgt) > 0 and then Length (Txt) > 0 then
                        Add_Annotation_To
                          (To_String (Tgt),
                           (Kind     => Note,
                            Text     => To_Unbounded_String
                                            (Decode_Escapes
                                               (To_String (Txt))),
                            Position => Pos));
                     end if;
                  end;
               end if;

            elsif T.Kind = Word then
               declare
                  Nxt : constant Token := Peek_At (1);
               begin
                  if Nxt.Kind = Arrow then
                     declare
                        From : constant Name := C.Peek.Text;
                     begin
                        C.Next;
                        Parse_Relation (From);
                     end;

                  elsif Nxt.Kind = Str then
                     declare
                        From : constant Name := C.Peek.Text;
                     begin
                        C.Next;
                        declare
                           M : constant Token := Consume;
                           pragma Unreferenced (M);
                        begin
                           null;
                        end;
                        if C.Peek.Kind = Arrow then
                           Parse_Relation (From);
                        else
                           while C.Peek.Kind not in Newline | Eof loop
                              C.Next;
                           end loop;
                        end if;
                     end;

                  elsif Nxt.Kind = Symbol
                    and then Nxt.Text.To_String = ":"
                  then
                     declare
                        Target : constant String
                          := To_String (C.Peek.Text);
                     begin
                        C.Next;
                        C.Next;
                        if C.Sym_Is ("<") then
                           C.Next;
                           if C.Sym_Is ("<") then C.Next; end if;
                           declare
                              S : Name := Null_Unbounded_String;
                           begin
                              while not (C.Sym_Is (">") or else C.At_Eof) loop
                                 S := S & C.Peek.Text;
                                 C.Next;
                              end loop;
                              Add_Annotation_To
                                (Target, (Kind     => Stereotype,
                                          Text     => S,
                                          Position => Attached));
                              if C.Sym_Is (">") then C.Next; end if;
                              if C.Sym_Is (">") then C.Next; end if;
                           end;
                        else
                           while C.Peek.Kind not in Newline | Eof loop
                              C.Next;
                           end loop;
                        end if;
                     end;

                  elsif not B.Open.Is_Empty then
                     Add_Member_To_Current (Parse_Member);

                  else
                     while C.Peek.Kind not in Newline | Eof loop
                        C.Next;
                     end loop;
                  end if;
               end;

            elsif not B.Open.Is_Empty then
               Add_Member_To_Current (Parse_Member);

            else
               while C.Peek.Kind not in Newline | Eof loop
                  C.Next;
               end loop;
            end if;
         end;
      end loop;

      return B.D;
   end Parse;

   function Get (D : Class_Diagram; Index : Class_Index) return Classifier is
     (D.Pool (Positive (Index)));

end PlantUML.Classes;