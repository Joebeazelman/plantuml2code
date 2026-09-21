with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with PlantUML2Code_Template_Path;
use  PlantUML2Code_Template_Path;

package body Test_Config is

   procedure Test_Empty (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Parse_Config ("", "x") = "", "empty -> empty");
   end Test_Empty;

   procedure Test_Comment_Only (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Parse_Config ("# nothing here" & ASCII.LF, "x") = "",
              "comment -> empty");
   end Test_Comment_Only;

   procedure Test_Simple (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Parse_Config ("templates_dir = /tmp/t" & ASCII.LF, "x")
              = "/tmp/t",
              "simple value");
   end Test_Simple;

   procedure Test_Whitespace (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Parse_Config ("  templates_dir   =   /tmp/t  " & ASCII.LF,
                            "x")
              = "/tmp/t",
              "value and key trimmed");
   end Test_Whitespace;

   procedure Test_Unknown_Key (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Parse_Config ("other = 1" & ASCII.LF, "x") = "",
              "unknown key ignored");
   end Test_Unknown_Key;

   procedure Test_Malformed (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Caught : Boolean := False;
   begin
      begin
         declare
            X : constant String := Parse_Config ("garbage line" & ASCII.LF,
                                                 "f");
            pragma Unreferenced (X);
         begin
            null;
         end;
      exception
         when Config_Error =>
            Caught := True;
      end;
      Assert (Caught, "malformed line raises Config_Error");
   end Test_Malformed;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Empty'Access, "empty");
      Register_Routine (T, Test_Comment_Only'Access, "comment only");
      Register_Routine (T, Test_Simple'Access, "simple");
      Register_Routine (T, Test_Whitespace'Access, "whitespace");
      Register_Routine (T, Test_Unknown_Key'Access, "unknown key");
      Register_Routine (T, Test_Malformed'Access, "malformed");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Config");
   end Name;

end Test_Config;
