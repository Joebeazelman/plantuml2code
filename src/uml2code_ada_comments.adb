with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Jintp;                 use Jintp;

package body Uml2Code_Ada_Comments is

   function Comment_Lines
     (Text       : String;
      Wrap_Width : Positive := 78) return Jintp.List
   is
      Result : List;
      --  The prefix is part of the physical line, so the text budget is
      --  reduced accordingly.  Clamp it to one character for tiny widths.
      Text_Width : constant Positive :=
        (if Wrap_Width > 3 then Wrap_Width - 3 else 1);

      procedure Append_Line (Line : String) is
         Comment : Dictionary;
      begin
         Insert (Comment, "text", "-- " & Line);
         Append (Result, Comment);
      end Append_Line;

      procedure Wrap_Line (Line : String) is
         Current : Unbounded_String;
         Start   : Natural := Line'First;
         I       : Natural := Line'First;

         procedure Add_Word (Word : String) is
         begin
            if Length (Current) = 0 then
               Current := To_Unbounded_String (Word);
            elsif Length (Current) + 1 + Word'Length <= Text_Width then
               Append (Current, ' ');
               Append (Current, Word);
            else
               Append_Line (To_String (Current));
               Current := To_Unbounded_String (Word);
            end if;
         end Add_Word;
      begin
         if Line'Length = 0 then
            Append_Line ("");
            return;
         end if;

         --  Normalize runs of spaces and tabs while retaining explicit
         --  newlines (handled by the caller) as semantic line breaks.
         while I <= Line'Last loop
            if Line (I) in ' ' | ASCII.HT then
               if I >= Start then
                  Add_Word (Line (Start .. I - 1));
               end if;
               I := I + 1;
               while I <= Line'Last and then Line (I) in ' ' | ASCII.HT loop
                  I := I + 1;
               end loop;
               Start := I;
            else
               I := I + 1;
            end if;
         end loop;
         if Start <= Line'Last then
            Add_Word (Line (Start .. Line'Last));
         end if;
         if Length (Current) > 0 then
            Append_Line (To_String (Current));
         end if;
      end Wrap_Line;

      Start : Natural := Text'First;
   begin
      if Text'Length = 0 then
         return Result;
      end if;

      for I in Text'Range loop
         if Text (I) = ASCII.LF then
            Wrap_Line (Text (Start .. I - 1));
            Start := I + 1;
         end if;
      end loop;
      if Start <= Text'Last then
         Wrap_Line (Text (Start .. Text'Last));
      elsif Text (Text'Last) = ASCII.LF then
         Append_Line ("");
      end if;
      return Result;
   end Comment_Lines;

end Uml2Code_Ada_Comments;
