
package body PlantUML.Tokens is

   function Tokenize (Source : String) return List is
      R    : List;
      I    : Natural := Source'First;
      Line : Positive := 1;

      Last_Was_Space : Boolean := False;

      procedure Emit (K : Token_Kind; S : String) is
         T : constant Token := (Kind         => K,
                                Text         => To_Unbounded_String (S),
                                Line         => Line,
                                Space_Before => Last_Was_Space);
      begin
         R.Append (T);
         Last_Was_Space := False;
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

      --  True when everything between the previous line terminator
      --  and position At is whitespace. Used to decide whether an
      --  apostrophe starts a comment.
      function Line_Starts_Comment
        (Src : String; Pos : Natural) return Boolean
      is
         J : Natural := Pos;
      begin
         while J > Src'First loop
            J := J - 1;
            exit when Src (J) = ASCII.LF;
            if Src (J) /= ' '
              and then Src (J) /= ASCII.HT
              and then Src (J) /= ASCII.CR
            then
               return False;
            end if;
         end loop;
         return True;
      end Line_Starts_Comment;

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
               else
                  Last_Was_Space := True;
               end if;
               I := I + 1;

            elsif C = '''
              and then Line_Starts_Comment (Source, I)
            then
               --  Apostrophe starts a line comment only at the start
               --  of a line (possibly after spaces/tabs). Mid-line it
               --  is ordinary text.
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
      else (Kind         => Eof,
            Text         => Null_Unbounded_String,
            Line         => 1,
            Space_Before => False));

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


   --  Decode \\n sequences in a raw text fragment into real
   --  newlines. Used by parsers when assembling note text.
   function Decode_Escapes (S : String) return String is
      N : Natural := 0;
   begin
      if S'Length = 0 then
         return "";
      end if;
      for I in S'First .. S'Last - 1 loop
         if S (I) = '\' and then S (I + 1) = 'n' then
            N := N + 1;
         end if;
      end loop;
      declare
         R : String (1 .. S'Length - N);
         J : Natural := 1;
         I : Natural := S'First;
      begin
         while I <= S'Last loop
            if S (I) = '\'
              and then I < S'Last
              and then S (I + 1) = 'n'
            then
               R (J) := ASCII.LF;
               J := J + 1;
               I := I + 2;
            else
               R (J) := S (I);
               J := J + 1;
               I := I + 1;
            end if;
         end loop;
         return R;
      end;
   end Decode_Escapes;
end PlantUML.Tokens;