with Ada.Strings.Unbounded;            use Ada.Strings.Unbounded;

with PlantUML2Code_Template_Path;
with Templates_Parser;

package body PlantUML2Code_Utils is

   function Render_Template
     (Subdir   : String;
      Template : String;
      T        : Templates_Parser.Translate_Set) return String
   is
      Path : constant String :=
        PlantUML2Code_Template_Path.Locate (Subdir, Template);
   begin
      return Templates_Parser.Parse (Path, T);
   end Render_Template;

   function Escape_Json (S : String) return String is
      R : Unbounded_String;
   begin
      for C of S loop
         case C is
            when '"'      => Append (R, "\""");
            when '\'      => Append (R, "\\");
            when ASCII.LF => Append (R, "\n");
            when ASCII.CR => Append (R, "\r");
            when ASCII.HT => Append (R, "\t");
            when others   => Append (R, C);
         end case;
      end loop;
      return To_String (R);
   end Escape_Json;

   function Basename_Without_Extension (Path : String) return String is
      Last_Slash : Natural := 0;
      Last_Dot   : Natural := 0;
   begin
      if Path'Length = 0 then
         return "";
      end if;

      for I in Path'Range loop
         if Path (I) = '/' then
            Last_Slash := I;
            Last_Dot := 0;
         elsif Path (I) = '.' then
            Last_Dot := I;
         end if;
      end loop;

      declare
         Base_Start : constant Positive :=
           (if Last_Slash = 0 then Path'First else Last_Slash + 1);
      begin
         --  No extension, or leading-dot file like ".profile"
         if Last_Dot = 0 or else Last_Dot = Base_Start then
            return Path (Base_Start .. Path'Last);
         else
            return Path (Base_Start .. Last_Dot - 1);
         end if;
      end;
   end Basename_Without_Extension;

end PlantUML2Code_Utils;
