with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;

with Uml2Code_CLI;        use Uml2Code_CLI;
with Uml2Code_Formats;
with Uml2Code_Ansi;

use type Uml2Code_Formats.Format;
use type Uml2Code_Ansi.Color_Mode;

package body Test_CLI is

   function V (S : String) return Unbounded_String is
     (To_Unbounded_String (S));

   function Parse_It (A, B : String := "";
                      C, D, E : String := "") return Parse_Result
   is
      Args : Argument_Vectors.Vector;
   begin
      if A'Length > 0 then Args.Append (V (A)); end if;
      if B'Length > 0 then Args.Append (V (B)); end if;
      if C'Length > 0 then Args.Append (V (C)); end if;
      if D'Length > 0 then Args.Append (V (D)); end if;
      if E'Length > 0 then Args.Append (V (E)); end if;
      return Parse (Args);
   end Parse_It;

   procedure Test_Empty (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result := Parse_It;
   begin
      Assert (not R.Ok or else R.Cmd = Cmd_None, "no command");
   end Test_Empty;

   procedure Test_Dump_One_File (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "a.puml");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Cmd = Cmd_Dump, "cmd dump");
      Assert (Natural (R.Files.Length) = 1, "one file");
      Assert (To_String (R.Files (1)) = "a.puml", "file name");
      Assert (R.Format = Uml2Code_Formats.Text, "default format");
   end Test_Dump_One_File;

   procedure Test_F_Separated (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "-f", "json", "a.puml");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Format = Uml2Code_Formats.Json, "json");
      Assert (Natural (R.Files.Length) = 1, "one file");
   end Test_F_Separated;

   procedure Test_F_Attached (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "-fjson", "a.puml");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Format = Uml2Code_Formats.Json, "json");
   end Test_F_Attached;

   procedure Test_Format_Equals (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "--format=ada", "a.puml");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Format = Uml2Code_Formats.Ada_HSM, "ada");
   end Test_Format_Equals;

   procedure Test_F_Missing_Value (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result := Parse_It ("dump", "-f");
   begin
      Assert (not R.Ok, "missing value fails");
   end Test_F_Missing_Value;

   procedure Test_Unknown_Format (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "-f", "yaml", "a.puml");
   begin
      Assert (not R.Ok, "unknown format fails");
   end Test_Unknown_Format;

   procedure Test_Unknown_Option (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "--bogus", "a.puml");
   begin
      Assert (not R.Ok, "unknown option fails");
   end Test_Unknown_Option;

   procedure Test_Multiple_Commands (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "kind", "a.puml");
   begin
      Assert (not R.Ok, "multiple commands fails");
   end Test_Multiple_Commands;

   procedure Test_Output_Dir (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "-o", "/tmp", "a.puml");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Out_Set, "output set");
      Assert (To_String (R.Out_Dir) = "/tmp", "out dir");
   end Test_Output_Dir;

   procedure Test_Help_Topic (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result := Parse_It ("help", "dump");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Cmd = Cmd_Help, "help");
      Assert (To_String (R.Help_Topic) = "dump", "topic is dump");
   end Test_Help_Topic;

   procedure Test_Help_No_Topic (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result := Parse_It ("help");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Cmd = Cmd_Help, "help");
      Assert (Length (R.Help_Topic) = 0, "no topic");
   end Test_Help_No_Topic;

   procedure Test_Help_Dash_Flag (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result := Parse_It ("--help");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Cmd = Cmd_Help, "help");
   end Test_Help_Dash_Flag;

   procedure Test_Version (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result := Parse_It ("--version");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Cmd = Cmd_Version, "version");
   end Test_Version;

   procedure Test_Color_Never (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "--color=never", "a.puml");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Color = Uml2Code_Ansi.Never, "never");
   end Test_Color_Never;

   procedure Test_Color_Separated (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "--color", "always", "a.puml");
   begin
      Assert (R.Ok, "ok");
      Assert (R.Color = Uml2Code_Ansi.Always, "always");
   end Test_Color_Separated;

   procedure Test_Multiple_Files (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result :=
        Parse_It ("dump", "a.puml", "b.puml", "c.puml");
   begin
      Assert (R.Ok, "ok");
      Assert (Natural (R.Files.Length) = 3, "three files");
   end Test_Multiple_Files;

   procedure Test_Stdin_Dash (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result := Parse_It ("dump", "-");
   begin
      Assert (R.Ok, "ok");
      Assert (Natural (R.Files.Length) = 1, "one file");
      Assert (To_String (R.Files (1)) = "-", "file is -");
   end Test_Stdin_Dash;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Empty'Access, "empty");
      Register_Routine (T, Test_Dump_One_File'Access, "dump one file");
      Register_Routine (T, Test_F_Separated'Access, "-f json");
      Register_Routine (T, Test_F_Attached'Access, "-fjson");
      Register_Routine (T, Test_Format_Equals'Access, "--format=ada");
      Register_Routine (T, Test_F_Missing_Value'Access, "-f missing");
      Register_Routine (T, Test_Unknown_Format'Access, "unknown format");
      Register_Routine (T, Test_Unknown_Option'Access, "unknown option");
      Register_Routine (T, Test_Multiple_Commands'Access,
                        "multiple commands");
      Register_Routine (T, Test_Output_Dir'Access, "-o dir");
      Register_Routine (T, Test_Help_Topic'Access, "help dump");
      Register_Routine (T, Test_Help_No_Topic'Access, "help alone");
      Register_Routine (T, Test_Help_Dash_Flag'Access, "--help");
      Register_Routine (T, Test_Version'Access, "--version");
      Register_Routine (T, Test_Color_Never'Access, "--color=never");
      Register_Routine (T, Test_Color_Separated'Access, "--color always");
      Register_Routine (T, Test_Multiple_Files'Access, "multiple files");
      Register_Routine (T, Test_Stdin_Dash'Access, "- for stdin");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("CLI");
   end Name;

end Test_CLI;
