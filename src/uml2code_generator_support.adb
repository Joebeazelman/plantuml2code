with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;                 use Ada.Text_IO;
with Uml2Code_Template_Path;
with Uml2Code_Utils;

package body Uml2Code_Generator_Support is
   procedure Write_File (Path, Content : String) is
      F : File_Type;
   begin Create (F, Out_File, Path); Put (F, Content); Close (F); end Write_File;

   procedure Render_To (Subdir, Template, Output : String; T : Templates_Parser.Translate_Set) is
      Content : constant String := Uml2Code_Utils.Render_Template (Subdir, Template, T);
   begin Write_File (Output, Content); Put_Line ("wrote " & Output); end Render_To;

   procedure Render_If_Missing (Subdir, Template, Output : String; T : Templates_Parser.Translate_Set) is
   begin
      if Ada.Directories.Exists (Output) then Put_Line ("kept  " & Output);
      else Render_To (Subdir, Template, Output, T); end if;
   end Render_If_Missing;

   procedure Refuse_Crate_Internal_Output (Out_Dir : String) is
      function Contains (Haystack, Needle : String) return Boolean is (Ada.Strings.Fixed.Index (Haystack, Needle) > 0);
   begin
      if Contains (Out_Dir, "uml2code/tests") or else Contains (Out_Dir, "uml2code/src") or else
         Contains (Out_Dir, "plantuml_parser/tests") or else Contains (Out_Dir, "plantuml_parser/src") then
         raise Constraint_Error with "refusing to write into the crate tree: " & Out_Dir;
      end if;
   end Refuse_Crate_Internal_Output;
end Uml2Code_Generator_Support;
