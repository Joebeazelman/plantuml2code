--  Command-line argument parsing. Produces a Parse_Result that the
--  main program can inspect without doing any string juggling itself.

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with PlantUML2Code_Formats;
with PlantUML2Code_Ansi;

package PlantUML2Code_CLI is

   use Ada.Strings.Unbounded;

   type Command_Kind is
     (Cmd_None, Cmd_Dump, Cmd_Kind, Cmd_Help, Cmd_Version);

   package File_Vectors is new Ada.Containers.Vectors
     (Positive, Unbounded_String);

   type Parse_Result is record
      Ok            : Boolean := True;
      Cmd           : Command_Kind := Cmd_None;
      Help_Topic    : Unbounded_String := Null_Unbounded_String;
      Format        : PlantUML2Code_Formats.Format :=
                        PlantUML2Code_Formats.Text;
      Templates_Dir : Unbounded_String := Null_Unbounded_String;
      Out_Dir       : Unbounded_String := Null_Unbounded_String;
      Out_Set       : Boolean := False;
      Color         : PlantUML2Code_Ansi.Color_Mode :=
                        PlantUML2Code_Ansi.Auto;
      Files         : File_Vectors.Vector;
   end record;

   --  Parse the process command line. Errors are printed to
   --  Standard_Error; the Result's Ok field is set False.
   function Parse return Parse_Result;

end PlantUML2Code_CLI;
