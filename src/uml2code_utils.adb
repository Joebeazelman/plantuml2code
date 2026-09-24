with Ada.Calendar.Formatting;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Uml2Code_Template_Path;

package body Uml2Code_Utils is

   function Render_Template
     (Subdir   : String;
      Template : String;
      T        : Templates_Parser.Translate_Set) return String
   is
      Path : constant String :=
        Uml2Code_Template_Path.Locate (Subdir, Template);
   begin
      return Templates_Parser.Parse (Path, T);
   end Render_Template;

   function Escape_Json (S : String) return String is
      Result : Unbounded_String;
   begin
      for C of S loop
         case C is
            when '"'      => Append (Result, "\""");
            when '\'      => Append (Result, "\\");
            when ASCII.LF => Append (Result, "\n");
            when ASCII.CR => Append (Result, "\r");
            when ASCII.HT => Append (Result, "\t");
            when others   =>
               if Character'Pos (C) < 32 then
                  Append (Result, "\u" &
                    Ada.Strings.Fixed.Trim (Character'Pos (C)'Image,
                      Ada.Strings.Both));
               else
                  Append (Result, C);
               end if;
         end case;
      end loop;
      return To_String (Result);
   end Escape_Json;

   function Basename_Without_Extension (Path : String) return String is
   begin
      return Ada.Directories.Base_Name (Path);
   end Basename_Without_Extension;

   function Today return String is
      use Ada.Calendar.Formatting;
   begin
      return Image (Ada.Calendar.Clock, False);
   end Today;

end Uml2Code_Utils;
