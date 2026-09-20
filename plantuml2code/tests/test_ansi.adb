with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with PlantUML2Code_Ansi; use PlantUML2Code_Ansi;

package body Test_Ansi is

   procedure Test_Never_Leaves_Plain (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Set_Mode (Never);
      Assert (not Enabled, "Never disables color");
      Assert (Bold ("x") = "x", "bold is identity under Never");
      Assert (Red ("x") = "x", "red is identity under Never");
   end Test_Never_Leaves_Plain;

   procedure Test_Always_Wraps (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Set_Mode (Always);
      declare
         R : constant String := Bold ("x");
      begin
         Assert (Enabled, "Always enables color");
         Assert (R'Length > 1, "output is wrapped");
         Assert (R (R'First) = ASCII.ESC, "starts with ESC");
      end;
      Set_Mode (Never);
   end Test_Always_Wraps;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Never_Leaves_Plain'Access, "Never");
      Register_Routine (T, Test_Always_Wraps'Access, "Always");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ansi");
   end Name;

end Test_Ansi;
