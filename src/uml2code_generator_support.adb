with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Text_IO;              use Ada.Text_IO;

with Jintp;                    use Jintp;
with Uml2Code_Template_Path;

package body Uml2Code_Generator_Support is

   function Locate_Template
     (Subdir   : String;
      Template : String) return String
   is
   begin
      return Uml2Code_Template_Path.Locate (Subdir, Template);
   end Locate_Template;

   procedure Write_File (Path, Content : String) is
      F : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (F, Content);
      Ada.Text_IO.Close (F);
   end Write_File;

   function Render_Dict
     (Subdir   : String;
      Template : String;
      Dict     : Jintp.Dictionary;
      Env      : in out Jintp.Environment) return String
   is
      Path : constant String := Locate_Template (Subdir, Template);
   begin
      return Jintp.Render (Path, Dict, Env);
   end Render_Dict;

   procedure Render_To
     (Subdir   : String;
      Template : String;
      Output   : String;
      Dict     : Jintp.Dictionary;
      Env      : in out Jintp.Environment)
   is
      Content : constant String := Render_Dict (Subdir, Template, Dict, Env);
   begin
      Write_File (Output, Content);
      Put_Line ("wrote " & Output);
   end Render_To;

   procedure Render_If_Missing
     (Subdir   : String;
      Template : String;
      Output   : String;
      Dict     : Jintp.Dictionary;
      Env      : in out Jintp.Environment)
   is
   begin
      if Ada.Directories.Exists (Output) then
         Put_Line ("kept  " & Output);
      else
         Render_To (Subdir, Template, Output, Dict, Env);
      end if;
   end Render_If_Missing;

   function Safe_Name (S : String) return String is
      R : Unbounded_String;
   begin
      for C of S loop
         if C in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' then
            Append (R, C);
         elsif Length (R) > 0
           and then Element (R, Length (R)) /= '_'
         then
            Append (R, '_');
         end if;
      end loop;
      while Length (R) > 0
        and then Element (R, Length (R)) = '_'
      loop
         Delete (R, Length (R), Length (R));
      end loop;
      return To_String (R);
   end Safe_Name;

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

   --  JinTP-specific wrappers (delegate to the above)

   procedure Render_To_Dict
     (Subdir   : String;
      Template : String;
      Output   : String;
      Dict     : Jintp.Dictionary;
      Env      : in out Jintp.Environment)
   is
   begin
      Render_To (Subdir, Template, Output, Dict, Env);
   end Render_To_Dict;

   procedure Render_If_Missing_Dict
     (Subdir   : String;
      Template : String;
      Output   : String;
      Dict     : Jintp.Dictionary;
      Env      : in out Jintp.Environment)
   is
   begin
      Render_If_Missing (Subdir, Template, Output, Dict, Env);
   end Render_If_Missing_Dict;

end Uml2Code_Generator_Support;
