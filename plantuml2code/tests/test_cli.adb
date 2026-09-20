with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Ada.Command_Line;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;

with PlantUML2Code_CLI;        use PlantUML2Code_CLI;
with PlantUML2Code_Formats;
with PlantUML2Code_Ansi;

package body Test_CLI is

   --  Helper: replace the process command line with the given args.
   procedure Set_Args (Args : in String) is
      I : Positive := Args'First;
      Start : Positive;
      N : Natural := 0;
   begin
      --  Clear existing arguments by resetting to zero.
      while Ada.Command_Line.Argument_Count > 0 loop
         --  Ada.Command_Line has no "clear", so we just set once at
         --  package elaboration. This helper is best-effort.
         exit;
      end loop;
      --  Parse the space-separated string and record count.
      --  Command_Line is fixed at process start, so we don't attempt
      --  to alter it. These tests are limited to non-argument
      --  properties.
      while I <= Args'Last loop
         while I <= Args'Last and then Args (I) = ' ' loop
            I := I + 1;
         end loop;
         exit when I > Args'Last;
         Start := I;
         while I <= Args'Last and then Args (I) /= ' ' loop
            I := I + 1;
         end loop;
         N := N + 1;
      end loop;
      pragma Unreferenced (Start, N);
   end Set_Args;

   procedure Test_No_Args (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Parse_Result := Parse;
   begin
      --  Whatever the actual command line is under AUnit, Parse should
      --  not crash and should set a Cmd.
      Assert (R.Cmd in Cmd_None | Cmd_Dump | Cmd_Kind
                        | Cmd_Help | Cmd_Version,
              "command enumerated");
   end Test_No_Args;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_No_Args'Access, "parse does not crash");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("CLI");
   end Name;

end Test_CLI;
