with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with PlantUML2Code_Formats;   use PlantUML2Code_Formats;

package body Test_Formats is

   procedure Test_Text (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Parse ("text") = Text, "text");
   end Test_Text;

   procedure Test_Json (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Parse ("json") = Json, "json");
   end Test_Json;

   procedure Test_Ada (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Parse ("ada") = Ada_HSM, "ada");
      Assert (Parse ("ada-hsm") = Ada_HSM, "ada-hsm alias");
   end Test_Ada;

   procedure Test_Mixed_Case (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Parse ("JSON") = Json, "case-insensitive");
   end Test_Mixed_Case;

   procedure Test_Unknown_Raises (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Dummy : Format;
      pragma Unreferenced (Dummy);
   begin
      begin
         Dummy := Parse ("yaml");
         Assert (False, "expected Constraint_Error");
      exception
         when Constraint_Error => null;
      end;
   end Test_Unknown_Raises;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Text'Access, "text");
      Register_Routine (T, Test_Json'Access, "json");
      Register_Routine (T, Test_Ada'Access, "ada");
      Register_Routine (T, Test_Mixed_Case'Access, "case-insensitive");
      Register_Routine (T, Test_Unknown_Raises'Access, "unknown raises");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Formats");
   end Name;

end Test_Formats;
