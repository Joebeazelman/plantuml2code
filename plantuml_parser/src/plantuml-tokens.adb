with Ada.Characters.Handling;  use Ada.Characters.Handling;
with Ada.Strings.Fixed;        use Ada.Strings.Fixed;

package body PlantUML.Tokens is

   function Tokenize (Source : String) return List is
      R    : List;
      I    : Natural := Source'First;
      Line : Positive := 1;

      procedure Emit (K : Token_Kind; S : String) is
         T : Token := (Kind => K,
                       Text => To_Unbounded_String (S),
                       Line => Line);
      begin
         R.Append (T);
      end Emit;

      function Is_Ident_Char (C : Character) return Boolean is
        (case C is
            when 'a' .. 'z' | 'A' .. 'Z'
               | '0' .. '9' | '_' | '$' => True,
            when others => False);

      function Span_Ident return String is
         Start : constant Natural := I;
         J     : Natural := I;
      begin
         if J <= Source'Last and then Source (J) = '@' then
            J := J + 1;
         end if;

         while J <= Source'Last loop
            if Is_Ident_Char (Source (J)) then
               J := J + 1;
            else
               exit;
            end if;
         end loop;

         I := J;
         return Source (Start .. J - 1);
      end Span_Ident;

      function Span_Arrow return String is
         Start : constant Natural := I;
         J     : Natural := I;
      begin
         while J <= Source'Last loop
            declare
               C : constant Character := Source (J);
            begin
               if (case C is
                      when '-' | '.' | 'o' | '*'
                         | '<' | '>' | '|' | '/' => True,
                      when others => False)
               then
                  J := J + 1;
               else
                  exit;
               end if;
            end;
         end loop;
         I := J;
         return Source (Start .. J - 1);
      end Span_Arrow;

   begin
      while I <= Source'Last loop
         declare
            C : constant Character := Source (I);
         begin
            if C = '@'
              and then I + 1 <= Source'Last
              and then Is_Ident_Char (Source (I + 1))
            then
               Emit (Word, Span_Ident);

            elsif Is_Ident_Char (C) then
               Emit (Word, Span_Ident);

            elsif C in ' ' | ASCII.HT | ASCII.LF | ASCII.CR then
               if C = ASCII.LF then
                  Emit (Newline, "");
                  Line := Line + 1;
               end if;
               I := I + 1;

            elsif C = ''' then
               while I <= Source'Last and then Source (I) /= ASCII.LF loop
                  I := I + 1;
               end loop;

            elsif C = '"' then
               declare
                  Start : constant Natural := I + 1;
                  J     : Natural := Start;
               begin
                  while J <= Source'Last and then Source (J) /= '"' loop
                     J := J + 1;
                  end loop;
                  if J > Source'Last then
                     raise Parse_Error with
                       "Unterminated string at line" & Line'Image;
                  end if;
                  Emit (Str, Source (Start .. J - 1));
                  I := J + 1;
               end;

            elsif C in '-' | '.' | 'o' | '*' | '<' | '>' | '|' | '/' then
               declare
                  S : constant String := Span_Arrow;
               begin
                  --  A run of two or more arrow characters is an Arrow
                  --  token. A single character is a Symbol.
                  Emit ((if S'Length >= 2 then Arrow else Symbol), S);
               end;

            else
               Emit (Symbol, String'[C]);
               I := I + 1;
            end if;
         end;
      end loop;

      Emit (Eof, "");
      return R;
   end Tokenize;

   function Make (L : aliased in List) return Cursor is
     ((Src => L'Unchecked_Access, I => 1));

   function Peek (C : Cursor) return Token is
     (if C.I <= Natural (C.Src.Length) then C.Src (C.I)
      else (Kind => Eof,
            Text => Null_Unbounded_String,
            Line => 1));

   procedure Next (C : in out Cursor) is
   begin
      C.I := C.I + 1;
   end Next;

   function At_Eof (C : Cursor) return Boolean is (Peek (C).Kind = Eof);

   function Position (C : Cursor) return Natural is
     (C.I);

   function Word_Is (C : Cursor; S : String) return Boolean is
     (declare T : constant Token := Peek (C);
      begin T.Kind = Word and then To_String (T.Text) = S);

   function Sym_Is (C : Cursor; S : String) return Boolean is
     (declare T : constant Token := Peek (C);
      begin T.Kind = Symbol and then To_String (T.Text) = S);

end PlantUML.Tokens;