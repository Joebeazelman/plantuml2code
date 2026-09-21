with PlantUML.Tokens;          use PlantUML.Tokens;

package body PlantUML.States is

   type Builder is record
      D    : State_Diagram;
      Open : Index_Vectors.Vector;
   end record;

   function Parse (Source : String) return State_Diagram is
      Toks : aliased constant List := Tokenize (Source);
      C    : Cursor  := Make (Toks);
      B    : Builder;

      function Consume return Token is
         T : constant Token := C.Peek;
      begin
         C.Next;
         return T;
      end Consume;

      function Scoped (Name : String) return String is
        (if B.Open.Is_Empty then Name
         else To_String (B.D.Pool (Positive (B.Open.Last_Element)).Id)
              & "." & Name);

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

      function Add_State (S : State) return State_Index is
      begin
         B.D.Pool.Append (S);
         return State_Index (B.D.Pool.Last_Index);
      end Add_State;

      procedure Append_State (S : State) is
         Idx : constant State_Index := Add_State (S);
      begin
         if B.Open.Is_Empty then
            B.D.Roots.Append (Idx);
         else
            declare
               Top_Idx : constant State_Index := B.Open.Last_Element;
               Top     : State := B.D.Pool (Positive (Top_Idx));
            begin
               Top.Children.Append (Idx);
               B.D.Pool.Replace_Element (Positive (Top_Idx), Top);
            end;
         end if;
      end Append_State;

      procedure Open_Composite (S : State) is
      begin
         Append_State (S);
         B.Open.Append (State_Index (B.D.Pool.Last_Index));
      end Open_Composite;

      procedure Close_Composite is
      begin
         if not B.Open.Is_Empty then
            declare
               Idx : constant State_Index := B.Open.Last_Element;
               S   : State := B.D.Pool (Positive (Idx));
            begin
               --  A composite state that ended up with no children
               --  is really a simple state. Downgrade so downstream
               --  code does not try to emit a child package.
               if S.Children.Is_Empty then
                  S.Kind := Simple;
                  B.D.Pool.Replace_Element (Positive (Idx), S);
               end if;
            end;
            B.Open.Delete_Last;
         end if;
      end Close_Composite;

      function Pseudostate_Exists (Name : String) return Boolean is
      begin
         for S of B.D.Pool loop
            if To_String (S.Id) = Name then
               return True;
            end if;
         end loop;
         return False;
      end Pseudostate_Exists;

      procedure Register_Pseudostate (Name : String; Kind : State_Kind) is
      begin
         if not Pseudostate_Exists (Name) then
            Append_State
              ((Id          => To_Unbounded_String (Name),
                Display     => Null_Unbounded_String,
                Kind        => Kind,
                Annotations => Annotation_Vectors.Empty_Vector,
                Children    => Index_Vectors.Empty_Vector));
         end if;
      end Register_Pseudostate;

      procedure Apply_Annotation (Name : String; A : Annotation) is
      begin
         for I in B.D.Pool.First_Index .. B.D.Pool.Last_Index loop
            declare
               S : State := B.D.Pool (I);
            begin
               if To_String (S.Id) = Name then
                  S.Annotations.Append (A);
                  B.D.Pool.Replace_Element (I, S);
                  return;
               end if;
            end;
         end loop;
      end Apply_Annotation;

      procedure Parse_Bracket_Pseudostate
        (Kind : out State_Kind;
         Ok   : out Boolean)
      is
      begin
         Kind := Simple;
         Ok   := False;

         if not C.Sym_Is ("[") then
            return;
         end if;
         C.Next;

         if C.Sym_Is ("*") then
            C.Next;
            if C.Sym_Is ("]") then
               C.Next;
               Kind := Start_Pseudostate;
               Ok   := True;
            end if;

         elsif C.Word_Is ("H") then
            C.Next;
            if C.Sym_Is ("*") then
               C.Next;
               if C.Sym_Is ("]") then
                  C.Next;
                  Kind := History_Deep;
                  Ok   := True;
               end if;
            elsif C.Sym_Is ("]") then
               C.Next;
               Kind := History_Shallow;
               Ok   := True;
            end if;
         end if;
      end Parse_Bracket_Pseudostate;

      procedure Parse_Label
        (Trigger : out Name;
         Guard   : out Name;
         Effect  : out Name;
         Raw     : out Name);

      function Parse_Target return Name is
         Result : Unbounded_String;

         function Parse_Single_Pseudostate return Name is
            Kind  : State_Kind;
            Ok    : Boolean;
            Canon : Name;
         begin
            Parse_Bracket_Pseudostate (Kind, Ok);
            if not Ok then
               raise Parse_Error with
                 "Unrecognized pseudostate as target";
            end if;
            if Kind = Start_Pseudostate then
               Canon := To_Unbounded_String ("[*]");
            elsif Kind = History_Shallow then
               Canon := To_Unbounded_String (Shallow_History_Name);
            elsif Kind = History_Deep then
               Canon := To_Unbounded_String (Deep_History_Name);
            else
               raise Parse_Error with "Unknown pseudostate kind";
            end if;
            return Canon;
         end Parse_Single_Pseudostate;

      begin
         if C.Sym_Is ("[") then
            declare
               Canon : constant Name := Parse_Single_Pseudostate;
            begin
               if To_String (Canon) = "[*]" then
                  Register_Pseudostate
                    (Scoped (End_Pseudostate_Name), End_Pseudostate);
                  return To_Unbounded_String
                    (Scoped (End_Pseudostate_Name));
               elsif To_String (Canon) = Shallow_History_Name then
                  Register_Pseudostate
                    (Scoped (Shallow_History_Name), History_Shallow);
                  return To_Unbounded_String
                    (Scoped (Shallow_History_Name));
               elsif To_String (Canon) = Deep_History_Name then
                  Register_Pseudostate
                    (Scoped (Deep_History_Name), History_Deep);
                  return To_Unbounded_String
                    (Scoped (Deep_History_Name));
               else
                  return Canon;
               end if;
            end;
         elsif C.Peek.Kind = Word then
            Result := Consume.Text;
            while C.Sym_Is (".") loop
               Append (Result, ".");
               C.Next;
               if C.Sym_Is ("[") then
                  declare
                     Canon : constant Name := Parse_Single_Pseudostate;
                  begin
                     Append (Result, To_String (Canon));
                     if To_String (Canon) = "[*]" then
                        Register_Pseudostate
                          (To_String (Result), Start_Pseudostate);
                     elsif To_String (Canon) = Shallow_History_Name then
                        Register_Pseudostate
                          (To_String (Result), History_Shallow);
                     elsif To_String (Canon) = Deep_History_Name then
                        Register_Pseudostate
                          (To_String (Result), History_Deep);
                     end if;
                  end;
               elsif C.Peek.Kind = Word then
                  Append (Result, Consume.Text);
               else
                  exit;
               end if;
            end loop;
            return Result;
         else
            raise Parse_Error with "Expected transition target";
         end if;
      end Parse_Target;

      procedure Parse_Tail (Tr : in out Transition) is
      begin
         if C.Sym_Is (":") then
            C.Next;
            Parse_Label (Tr.Trigger, Tr.Guard, Tr.Effect, Tr.Label);
            if Length (Tr.Trigger) = 0
              and then Length (Tr.Guard) = 0
              and then Length (Tr.Effect) = 0
            then
               Tr.Kind := Completion;
            end if;
         else
            Tr.Kind := Completion;
         end if;
      end Parse_Tail;

      procedure Parse_Transition_From (Source : Name) is
         Tr : Transition;
      begin
         Tr.From := Source;
         Tr.Kind := External;

         declare
            Ignored : constant Token := Consume;
            pragma Unreferenced (Ignored);
         begin
            null;
         end;

         Tr.To := Parse_Target;
         Parse_Tail (Tr);
         B.D.Transitions.Append (Tr);
      end Parse_Transition_From;

      function Parse_Annotation return Annotation is
         A : Annotation;
      begin
         declare
            T : constant Token := C.Peek;
            S : constant String :=
              (if T.Kind = Word then T.Text.To_String else "");
         begin
            if S = "entry" then
               A.Kind := Entry_Action;
               C.Next;
               if C.Sym_Is ("/") then C.Next; end if;
               A.Action := Consume.Text;

            elsif S = "exit" then
               A.Kind := Exit_Action;
               C.Next;
               if C.Sym_Is ("/") then C.Next; end if;
               A.Action := Consume.Text;

            elsif S = "do" then
               A.Kind := Do_Activity;
               C.Next;
               if C.Sym_Is ("/") then C.Next; end if;
               A.Action := Consume.Text;

            else
               --  "State : text" is an internal transition only when
               --  the rest of the line contains '/'. Otherwise it is
               --  a note attached to the state.
               declare
                  Has_Slash : Boolean := False;
                  Lookahead : Natural := 0;
               begin
                  loop
                     declare
                        Ix : constant Natural :=
                          PlantUML.Tokens.Position (C) + Lookahead;
                        Tk : constant Token :=
                          (if Ix <= Natural (Toks.Length)
                           then Toks (Ix)
                           else (Eof, Null_Unbounded_String, 1, False));
                     begin
                        exit when Tk.Kind in Newline | Eof;
                        if Tk.Kind = Symbol
                          and then To_String (Tk.Text) = "/"
                        then
                           Has_Slash := True;
                           exit;
                        end if;
                        Lookahead := Lookahead + 1;
                     end;
                  end loop;

                  if not Has_Slash then
                     A.Kind := Note;
                     declare
                        Txt : Unbounded_String := Null_Unbounded_String;
                        Raw : Unbounded_String := Null_Unbounded_String;
                     begin
                        while C.Peek.Kind not in Newline | Eof loop
                           declare
                              Tk : constant Token := C.Peek;
                           begin
                              if Tk.Space_Before
                                and then Length (Raw) > 0
                              then
                                 Append (Raw, " ");
                              end if;
                              Append (Raw, Tk.Text);
                           end;
                           C.Next;
                        end loop;

                        declare
                           R : constant String := To_String (Raw);
                           J : Natural := R'First;
                        begin
                           while J <= R'Last loop
                              if R (J) = '\'
                                and then J < R'Last
                                and then R (J + 1) = 'n'
                              then
                                 Append (Txt, ASCII.LF);
                                 J := J + 2;
                              else
                                 Append (Txt, R (J));
                                 J := J + 1;
                              end if;
                           end loop;
                        end;

                        A.Action := Txt;
                     end;
                     return A;
                  end if;
               end;

               A.Kind := Internal_Transition;

               if C.Peek.Kind = Word then
                  A.Trigger := Consume.Text;
               end if;

               if C.Sym_Is ("[") then
                  C.Next;
                  declare
                     G : Name := Null_Unbounded_String;
                  begin
                     while not (C.Sym_Is ("]") or else C.At_Eof) loop
                        G := G & C.Peek.Text & " ";
                        C.Next;
                     end loop;
                     if C.Sym_Is ("]") then C.Next; end if;
                     A.Guard := G;
                  end;
               end if;

               if C.Sym_Is ("/") then
                  C.Next;
                  A.Action := Consume.Text;
               end if;
            end if;
         end;

         if A.Kind in Note | Stereotype | Unknown
           or else Length (A.Action) = 0
         then
            while C.Peek.Kind not in Newline | Eof loop
               if Length (A.Action) = 0 then
                  A.Action := C.Peek.Text;
               else
                  A.Action := A.Action & " " & C.Peek.Text;
               end if;
               C.Next;
            end loop;
         end if;

         return A;
      end Parse_Annotation;

      procedure Parse_Label
        (Trigger : out Name;
         Guard   : out Name;
         Effect  : out Name;
         Raw     : out Name)
      is
         R : Unbounded_String;
      begin
         Trigger := Null_Unbounded_String;
         Guard   := Null_Unbounded_String;
         Effect  := Null_Unbounded_String;

         if C.Peek.Kind = Word then
            Trigger := Consume.Text;
            R := Trigger;
         end if;

         if C.Sym_Is ("[") then
            C.Next;
            declare
               G : Name := Null_Unbounded_String;
            begin
               while not (C.Sym_Is ("]") or else C.At_Eof) loop
                  G := G & C.Peek.Text & " ";
                  C.Next;
               end loop;
               if C.Sym_Is ("]") then C.Next; end if;
               Guard := G;
               R := R & " [" & G & "]";
            end;
         end if;

         if C.Sym_Is ("/") then
            C.Next;
            Effect := Consume.Text;
            R := R & " / " & Effect;
         end if;

         while C.Peek.Kind not in Newline | Eof loop
            declare
               T : constant Token := Consume;
            begin
               if Length (Effect) = 0 then
                  Effect := T.Text;
               else
                  Effect := Effect & " " & T.Text;
               end if;
               R := R & " " & T.Text;
            end;
         end loop;

         Raw := R;
      end Parse_Label;

      procedure Register_Source_Pseudostate (Kind : State_Kind) is
      begin
         if Kind = Start_Pseudostate then
            Register_Pseudostate
              (Scoped (Start_Pseudostate_Name), Start_Pseudostate);
         elsif Kind = History_Shallow then
            Register_Pseudostate
              (Scoped (Shallow_History_Name), History_Shallow);
         elsif Kind = History_Deep then
            Register_Pseudostate
              (Scoped (Deep_History_Name), History_Deep);
         end if;
      end Register_Source_Pseudostate;

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

            elsif Tx in "@enduml" | "@endstate" then
               exit;

            elsif Tx = "@startstate" then
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
               Close_Composite;
               C.Next;

            elsif C.Sym_Is ("{") then
               C.Next;

            elsif C.Sym_Is ("--") then
               while C.Peek.Kind not in Newline | Eof loop
                  C.Next;
               end loop;

            elsif Tx = "state" then
               C.Next;
               declare
                  S : State;
               begin
                  while C.Peek.Kind = Newline loop C.Next; end loop;
                  if C.At_Eof then
                     raise Parse_Error with
                       "Unexpected end of input after 'state'";
                  end if;
                  S.Id := Consume.Text;
                  S.Kind := Simple;

                  if C.Word_Is ("as") then
                     C.Next;
                     S.Display := Consume.Text;
                  end if;

                  if C.Sym_Is ("<") then
                     while C.Peek.Kind /= Newline
                       and then not C.Sym_Is (">")
                       and then not C.At_Eof
                     loop
                        C.Next;
                     end loop;
                     if C.Sym_Is (">") then C.Next; end if;
                  end if;

                  if C.Sym_Is ("{") then
                     S.Kind := Composite;
                     C.Next;
                     Open_Composite (S);
                  else
                     Append_State (S);
                  end if;
               end;

            elsif C.Sym_Is ("[") then
               declare
                  Kind  : State_Kind;
                  Ok    : Boolean;
                  Canon : Name;
               begin
                  Parse_Bracket_Pseudostate (Kind, Ok);
                  if not Ok then
                     raise Parse_Error with
                       "Unrecognized pseudostate as source";
                  end if;

                  Register_Source_Pseudostate (Kind);

                  if Kind = Start_Pseudostate then
                     Canon := To_Unbounded_String (Scoped (Start_Pseudostate_Name));
                  elsif Kind = History_Shallow then
                     Canon := To_Unbounded_String (Scoped (Shallow_History_Name));
                  elsif Kind = History_Deep then
                     Canon := To_Unbounded_String (Scoped (Deep_History_Name));
                  else
                     Canon := To_Unbounded_String (Scoped (Start_Pseudostate_Name));
                  end if;

                  if C.Peek.Kind = Arrow then
                     Parse_Transition_From (Canon);
                  end if;
               end;

            elsif T.Kind = Word then
               declare
                  Nxt : constant Token := Peek_At (1);
               begin
                  if Nxt.Kind = Arrow then
                     declare
                        From : constant Name := C.Peek.Text;
                     begin
                        C.Next;
                        Parse_Transition_From (From);
                     end;

                  elsif Nxt.Kind = Symbol
                    and then Nxt.Text.To_String = ":"
                  then
                     declare
                        Subj : constant Name := C.Peek.Text;
                     begin
                        C.Next;
                        C.Next;
                        declare
                           A : constant Annotation := Parse_Annotation;
                        begin
                           Apply_Annotation (To_String (Subj), A);
                        end;
                     end;

                  else
                     while C.Peek.Kind not in Newline | Eof loop
                        C.Next;
                     end loop;
                  end if;
               end;

            else
               while C.Peek.Kind not in Newline | Eof loop
                  C.Next;
               end loop;
            end if;
         end;
      end loop;

      return B.D;
   end Parse;

   function Get (D : State_Diagram; Index : State_Index) return State is
     (D.Pool (Positive (Index)));

end PlantUML.States;
